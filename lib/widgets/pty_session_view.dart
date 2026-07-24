import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/theme.dart';

/// PTY session view using xterm2 for terminal emulation.
class PtySessionView extends StatefulWidget {
  final ServerRef serverRef;
  final String agentId;
  final Session session;

  const PtySessionView({
    super.key,
    required this.serverRef,
    required this.agentId,
    required this.session,
  });

  @override
  State<PtySessionView> createState() => _PtySessionViewState();
}

class _PtySessionViewState extends State<PtySessionView> {
  final Terminal _terminal = Terminal(maxLines: 10000);
  final HttpSseTransport _transport = HttpSseTransport();
  Subscription? _subscription;
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _setupTerminal();
    _initialize();
  }

  /// Buffer for deduplicating Enter sequences from mobile IME.
  /// On mobile, pressing Enter fires both textInput("\n") and
  /// keyInput(Enter → "\r") separately, resulting in duplicate Enter
  /// signals to the PTY. This buffer coalesces them within one
  /// microtask and normalizes "\n\r" → "\r".
  String _pendingOutput = '';
  bool _outputScheduled = false;

  void _flushOutput() {
    _outputScheduled = false;
    if (_pendingOutput.isEmpty) return;
    // Normalize: mobile IME may send "\n" (textInput) + "\r" (keyInput)
    // for a single Enter press. Keep only the "\r" which is the standard
    // terminal enter sequence.
    final normalized = _pendingOutput.replaceAll('\n\r', '\r');
    _pendingOutput = '';
    if (normalized.isEmpty) return;
    final bytes = utf8.encode(normalized);
    _transport.sendInput(
      widget.serverRef,
      widget.session.id,
      bytes,
      agentId: widget.agentId,
    );
  }

  void _scheduleFlush() {
    if (_outputScheduled) return;
    _outputScheduled = true;
    Future.microtask(_flushOutput);
  }

  void _setupTerminal() {
    _terminal.onOutput = (String data) {
      _pendingOutput += data;
      _scheduleFlush();
    };

    _terminal.onResize = (int cols, int rows, int px, int py) {
      _transport.resizeSession(
        widget.serverRef,
        widget.session.id,
        cols,
        rows,
        agentId: widget.agentId,
      );
    };
  }

  Future<void> _initialize() async {
    _currentOffset = widget.session.byteOffset;
    // Fetch existing output first
    try {
      final result = await _transport.fetchOutput(
        widget.serverRef,
        widget.session.id,
        agentId: widget.agentId,
        tail: 5000,
      );
      for (final chunk in result.chunks) {
        final text = utf8.decode(
          base64.decode(chunk.data),
          allowMalformed: true,
        );
        _terminal.write(text);
      }
      if (result.chunks.isNotEmpty) {
        _currentOffset = result.upTo;
      }
    } catch (_) {
      // no existing output
    }
    _subscribe();
  }

  void _subscribe() {
    _subscription = _transport.subscribe(
      widget.serverRef,
      widget.session.id,
      SubscribeHandlers(
        onChunk: (OutputChunk chunk) {
          final text = utf8.decode(chunk.data, allowMalformed: true);
          _terminal.write(text);
        },
        onState: (Session session) {
          if (session.status == SessionStatus.exited) {
            _terminal.write('\r\n\x1b[33m[Session exited]\x1b[0m\r\n');
          }
        },
        onError: (Object error) {
          debugPrint('[PtySessionView] SSE error: $error');
        },
      ),
      agentId: widget.agentId,
      fromOffset: _currentOffset,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: TerminalView(
          _terminal,
          autofocus: true,
          backgroundOpacity: 1.0,
          deleteDetection: true,
        ),
      ),
    );
  }
}
