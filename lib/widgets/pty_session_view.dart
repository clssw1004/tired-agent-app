import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/theme.dart';

/// PTY session view using xterm2 for terminal emulation.
///
/// - Subscribes to SSE stream via Transport.subscribe()
/// - Writes decoded output to xterm2 Terminal
/// - Forwards user input back via Transport.sendInput()
/// - Handles terminal resize events
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
  final Terminal _terminal = Terminal(
    maxLines: 10000,
  );
  final HttpSseTransport _transport = HttpSseTransport();
  Subscription? _subscription;

  @override
  void initState() {
    super.initState();
    _setupTerminal();
    _subscribe();
  }

  void _setupTerminal() {
    // Forward user keyboard input to the PTY process
    _terminal.onOutput = (String data) {
      final bytes = utf8.encode(data);
      _transport.sendInput(
        widget.serverRef,
        widget.session.id,
        bytes,
        agentId: widget.agentId,
      );
    };

    // Handle terminal resize
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
            _terminal.write('\x1b[1m\x1b[31m⏹\x1b[0m \x1b[33mSession ended\x1b[0m\r\n');
          }
        },
        onError: (Object error) {
          debugPrint('SSE error: $error');
        },
      ),
      agentId: widget.agentId,
      fromOffset: widget.session.byteOffset,
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
        ),
      ),
    );
  }
}
