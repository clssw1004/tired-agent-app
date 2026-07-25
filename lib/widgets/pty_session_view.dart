import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/widgets/pty_keyboard_panel.dart';

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
  final PtyModifierState _modifierState = PtyModifierState();
  Subscription? _subscription;
  int _currentOffset = 0;
  bool _keyboardExpanded = false;

  /// Resolve keyboard layout from the session command.
  PtyKeyboardConfig get _keyboardConfig =>
      PtyKeyboardConfig.fromCommand(widget.session.cmd);

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
    // Inject modifier handler into the xterm2 input pipeline so that
    // toggling Ctrl/Alt/Meta from the virtual keyboard affects physical
    // keystrokes coming from the system keyboard.
    _terminal.inputHandler = PtyModifierHandler(
      state: _modifierState,
      next: defaultInputHandler,
    );

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
        tail: 1048576,
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
    _modifierState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TerminalView(
                _terminal,
                autofocus: false,
                backgroundOpacity: 1.0,
                deleteDetection: true,
              ),
            ),
            PtyKeyboardPanel(
              config: _keyboardConfig,
              modifierState: _modifierState,
              expanded: _keyboardExpanded,
              onToggle: () =>
                  setState(() => _keyboardExpanded = !_keyboardExpanded),
              onSendBytes: (bytes) => _transport.sendInput(
                widget.serverRef,
                widget.session.id,
                bytes,
                agentId: widget.agentId,
              ),
              onDismissKeyboard: () => FocusScope.of(context).unfocus(),
            ),
          ],
        ),
      ),
    );
  }
}
