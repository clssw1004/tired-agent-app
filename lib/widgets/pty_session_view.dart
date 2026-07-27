import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/widgets/pty_keyboard_panel.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// SSE connection state for the PTY session view.
enum PtyConnectionStatus { connected, reconnecting, disconnected }

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
  PtySessionViewState createState() => PtySessionViewState();
}

class PtySessionViewState extends State<PtySessionView> {
  final Terminal _terminal = Terminal(maxLines: 10000);
  final HttpSseTransport _transport = HttpSseTransport();
  final PtyModifierState _modifierState = PtyModifierState();
  Subscription? _subscription;
  int _currentOffset = 0;
  bool _keyboardExpanded = false;

  /// Current SSE connection status.
  PtyConnectionStatus _connectionStatus = PtyConnectionStatus.disconnected;

  /// Whether the session has exited — stops automatic reconnection.
  bool _sessionExited = false;

  /// Public getter so [SessionDetailScreen] can read the status.
  PtyConnectionStatus get connectionStatus => _connectionStatus;

  /// Resolve keyboard layout from the session command.
  PtyKeyboardConfig get _keyboardConfig =>
      PtyKeyboardConfig.fromCommand(widget.session.cmd);

  @override
  void initState() {
    super.initState();
    _setupTerminal();
    _initialize();
    // Send initial resize after first frame so TerminalView has actual dimensions.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialResize());
  }

  /// Send current terminal dimensions to the server.
  void _sendInitialResize() {
    final cols = _terminal.viewWidth;
    final rows = _terminal.viewHeight;
    if (cols > 0 && rows > 0) {
      _transport.resizeSession(
        widget.serverRef,
        widget.session.id,
        cols,
        rows,
        agentId: widget.agentId,
      );
    }
  }

  /// Buffer for deduplicating Enter sequences from mobile IME.
  String _pendingOutput = '';
  bool _outputScheduled = false;

  void _flushOutput() {
    _outputScheduled = false;
    if (_pendingOutput.isEmpty) return;
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
    _connectionStatus = PtyConnectionStatus.connected;
    if (mounted) setState(() {});
  }

  /// Public — called from [SessionDetailScreen] via GlobalKey to force a
  /// full re-initialization (fetch output + subscribe).
  void reconnect() {
    if (_sessionExited) return;
    _subscription?.close();
    _subscription = null;
    setState(() => _connectionStatus = PtyConnectionStatus.reconnecting);
    _initialize();
  }

  void _subscribe() {
    _subscription = _transport.subscribe(
      widget.serverRef,
      widget.session.id,
      SubscribeHandlers(
        onHeartbeat: () {
          // Heartbeat received — SSE connection is alive.
          if (_connectionStatus == PtyConnectionStatus.reconnecting && mounted) {
            setState(() => _connectionStatus = PtyConnectionStatus.connected);
          }
        },
        onChunk: (OutputChunk chunk) {
          final text = utf8.decode(chunk.data, allowMalformed: true);
          _terminal.write(text);
        },
        onState: (Session session) {
          if (session.status == SessionStatus.exited) {
            _terminal.write('\r\n\x1b[33m[${AppStrings.of.ptySessionExited}]\x1b[0m\r\n');
            _sessionExited = true;
            _subscription?.close();
            _subscription = null;
            if (mounted) {
              setState(
                () => _connectionStatus = PtyConnectionStatus.disconnected,
              );
            }
          }
        },
        onError: (Object error) {
          debugPrint('[PtySessionView] SSE error: $error');
          if (!_sessionExited && mounted) {
            setState(
              () => _connectionStatus = PtyConnectionStatus.reconnecting,
            );
          }
        },
      ),
      agentId: widget.agentId,
      fromOffset: _currentOffset,
    );
    // Caller (_initialize or reconnect) manages setState for initial connected.
  }

  @override
  void dispose() {
    _subscription?.close();
    _modifierState.dispose();
    super.dispose();
  }

  // ── Status banner ─────────────────────────────────────────────────

  /// Thin colored bar shown below the AppBar.
  Widget _statusBanner() {
    final c = context.appColors;
    final bool visible;
    final Color color;
    final String label;

    switch (_connectionStatus) {
      case PtyConnectionStatus.connected:
        visible = false;
        color = c.success;
        label = '';
      case PtyConnectionStatus.reconnecting:
        visible = true;
        color = c.warning;
        label = AppStrings.of.ptyReconnecting;
      case PtyConnectionStatus.disconnected:
        visible = true;
        color = c.textSecondary;
        label = _sessionExited ? AppStrings.of.ptySessionExited : AppStrings.of.ptyDisconnected;
    }

    if (!visible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.one,
      ),
      color: color.withAlpha(25),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withAlpha(120), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.two),
          ThemedText.mono(label, color: color),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Status banner
            _statusBanner(),
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
