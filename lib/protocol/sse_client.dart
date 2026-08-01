import 'dart:convert';

import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/types.dart';

/// SSE connection state for screen-level status tracking.
enum SseConnectionStatus { connected, reconnecting, disconnected }

/// Encapsulates the SSE lifecycle for a single PTY session.
///
/// Orchestrates [Transport.fetchOutput] (history replay) →
/// [Transport.subscribe] (live stream), tracks connection status from the
/// transport's [SubscribeHandlers.onConnected]/[onReconnecting] callbacks, and
/// detects session-exit.
///
/// Transport-level reconnection (HTTP backoff) and the resume byte offset are
/// owned by [Transport.subscribe]; this class only mirrors status and teardown.
class SseClient {
  final Transport _transport;
  final ServerRef _ref;
  final String _sessionId;
  final String? _agentId;

  Subscription? _subscription;
  bool _closed = false;
  bool _sessionExited = false;

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
  void Function()? onConnected;
  void Function()? onReconnecting;

  SseClient({
    required Transport transport,
    required ServerRef ref,
    required String sessionId,
    String? agentId,
  }) : _transport = transport,
       _ref = ref,
       _sessionId = sessionId,
       _agentId = agentId;

  /// Start the SSE lifecycle: fetch history → subscribe to live stream.
  ///
  /// [tail] controls how much historical output to fetch (default 1 MiB).
  /// Pass 0 to skip history entirely.
  Future<void> start({int tail = 1048576}) async {
    int fromOffset = 0;

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
          fromOffset = result.upTo;
        }
      } on SessionNotFoundException catch (e) {
        // Session already gone — mark exited and don't bother subscribing.
        _sessionExited = true;
        _status = SseConnectionStatus.disconnected;
        onError?.call(e);
        return;
      } catch (e) {
        // History replay may fail (e.g. transient network error). Surface it
        // but still try the live stream; offset falls back to 0, so the tail
        // of the buffer may be replayed.
        onError?.call(e);
      }
    }

    _subscription = _transport.subscribe(
      _ref,
      _sessionId,
      SubscribeHandlers(
        onChunk: _onChunk,
        onState: _onState,
        onError: _onError,
        onHeartbeat: _onHeartbeat,
        onConnected: _onConnected,
        onReconnecting: _onReconnecting,
      ),
      agentId: _agentId,
      fromOffset: fromOffset,
    );
  }

  /// Reconnect the current stream without re-fetching history.
  ///
  /// Status transitions are driven by the transport's connection callbacks.
  void reconnect() {
    if (_sessionExited || _closed) return;
    _subscription?.resubscribe?.call();
  }

  /// Close permanently — no more reconnections.
  void close() {
    _closed = true;
    _subscription?.close();
    _subscription = null;
    _status = SseConnectionStatus.disconnected;
  }

  // ── Internal ───────────────────────────────────────────────────────────

  void _onChunk(OutputChunk chunk) {
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
    if (error is SessionNotFoundException && !_sessionExited) {
      _sessionExited = true;
      _status = SseConnectionStatus.disconnected;
    }
    onError?.call(error);
  }

  void _onConnected() {
    _status = SseConnectionStatus.connected;
    onConnected?.call();
  }

  void _onReconnecting() {
    if (!_sessionExited && !_closed) {
      _status = SseConnectionStatus.reconnecting;
    }
    onReconnecting?.call();
  }

  void _onHeartbeat() {
    onHeartbeat?.call();
  }
}
