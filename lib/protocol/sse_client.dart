import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/types.dart';

/// SSE connection state for screen-level status tracking.
enum SseConnectionStatus { connected, reconnecting, disconnected }

/// Encapsulates the SSE lifecycle for a single PTY session.
///
/// Orchestrates [Transport.fetchOutput] (history replay) →
/// [Transport.subscribe] (live stream), manages connection status,
/// and handles session-exit detection.
///
/// Transport-level reconnection (HTTP backoff) is handled internally by
/// [Transport.subscribe]; this class owns screen-level concerns: tracking
/// status, triggering reconnect at the right offset, and ending the stream
/// when the session has exited.
class SseClient {
  final Transport _transport;
  final ServerRef _ref;
  final String _sessionId;
  final String? _agentId;

  Subscription? _subscription;
  bool _closed = false;
  bool _sessionExited = false;

  /// Current byte offset, updated on every chunk.
  int _currentOffset = 0;

  SseConnectionStatus _status = SseConnectionStatus.disconnected;

  /// Public status for UI banners etc.
  SseConnectionStatus get status => _status;

  /// Whether the session has exited — stops reconnection attempts.
  bool get sessionExited => _sessionExited;

  // ── Callbacks (set before [start]) ────────────────────────────────────

  void Function(OutputChunk chunk)? onChunk;
  void Function(Session session)? onState;
  void Function(Object error)? onError;
  void Function()? onHeartbeat;

  SseClient({
    required Transport transport,
    required ServerRef ref,
    required String sessionId,
    String? agentId,
  })  : _transport = transport,
        _ref = ref,
        _sessionId = sessionId,
        _agentId = agentId;

  /// Start the SSE lifecycle: fetch history → subscribe to live stream.
  ///
  /// [tail] controls how much historical output to fetch (default 1 MiB).
  /// Pass 0 to skip history entirely.
  Future<void> start({int tail = 1048576}) async {
    _currentOffset = 0;

    // Fetch historical output (skip if tail is 0).
    if (tail > 0) {
      try {
        final result = await _transport.fetchOutput(
          _ref,
          _sessionId,
          agentId: _agentId,
          tail: tail,
        );
        for (final chunk in result.chunks) {
          final decoded = base64.decode(chunk.data);
          onChunk?.call(OutputChunk(offset: chunk.offset, data: decoded));
        }
        if (result.chunks.isNotEmpty) {
          _currentOffset = result.upTo;
        }
      } catch (_) {
        // May fail if the session has no output yet — fine.
      }
    }

    // Subscribe to live stream.
    _doSubscribe();
    _status = SseConnectionStatus.connected;
  }

  /// Tear down the current subscription and create a new one.
  ///
  /// Does NOT re-fetch history — resumes from the last byte offset.
  void reconnect() {
    if (_sessionExited || _closed) return;
    _subscription?.close();
    _subscription = null;
    _status = SseConnectionStatus.reconnecting;
    _doSubscribe();
    _status = SseConnectionStatus.connected;
  }

  /// Close permanently — no more reconnections.
  void close() {
    _closed = true;
    _subscription?.close();
    _subscription = null;
    _status = SseConnectionStatus.disconnected;
  }

  // ── Internal ───────────────────────────────────────────────────────────

  void _doSubscribe() {
    _subscription = _transport.subscribe(
      _ref,
      _sessionId,
      SubscribeHandlers(
        onChunk: _onChunk,
        onState: _onState,
        onError: _onError,
        onHeartbeat: _onHeartbeat,
      ),
      agentId: _agentId,
      fromOffset: _currentOffset,
    );
  }

  void _onChunk(OutputChunk chunk) {
    _currentOffset = chunk.offset + chunk.data.length;
    onChunk?.call(chunk);
  }

  void _onState(Session session) {
    if (session.status == SessionStatus.exited) {
      _sessionExited = true;
      _subscription?.close();
      _subscription = null;
      _status = SseConnectionStatus.disconnected;
    }
    onState?.call(session);
  }

  void _onError(Object error) {
    debugPrint('[SseClient] SSE error: $error');
    if (!_sessionExited && !_closed) {
      _status = SseConnectionStatus.reconnecting;
    }
    onError?.call(error);
  }

  void _onHeartbeat() {
    // Heartbeat received → connection is alive.
    if (_status == SseConnectionStatus.reconnecting) {
      _status = SseConnectionStatus.connected;
    }
    onHeartbeat?.call();
  }
}
