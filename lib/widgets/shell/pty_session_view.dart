import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/protocol/sse_client.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/utils/pty_scroll_physics.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/pty_modifier.dart';
import 'package:tired_agent_app/widgets/shell/pty_keyboard_panel.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// PTY session view using xterm2 for terminal emulation.
class PtySessionView extends StatefulWidget {
  final ServerRef serverRef;
  final String agentId;
  final Session session;
  final Future<String?> Function()? tokenProvider;

  const PtySessionView({
    super.key,
    required this.serverRef,
    required this.agentId,
    required this.session,
    this.tokenProvider,
  });

  @override
  PtySessionViewState createState() => PtySessionViewState();
}

class PtySessionViewState extends State<PtySessionView>
    with SingleTickerProviderStateMixin {
  /// Must be initialized after [initState] when we can access [AppSettingsProvider].
  late final Terminal _terminal;
  late final HttpSseTransport _transport;
  late final SseClient _sseClient;
  final PtyModifierState _modifierState = PtyModifierState();

  /// Toggle the system keyboard (IME) on/off.
  late final FocusNode _terminalFocusNode;

  /// Directly drives the IME input connection via xterm2's [TerminalViewState],
  /// bypassing the focus-node keyboard-token dance that caused hide/show races.
  final GlobalKey<TerminalViewState> _terminalViewKey = GlobalKey();
  bool _keyboardExpanded = false;

  /// When true, the system soft keyboard (IME) won't pop up on tap.
  /// Toggled by double-tap on the terminal area.
  bool _hardwareKeyboardOnly = true;

  /// Timestamp of the last pointer-down event, for double-tap detection.
  DateTime? _lastTapDown;

  /// Animation for the pulsing reconnect dot.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  /// Tracks the previous status to detect reconnection success.
  SseConnectionStatus _prevStatus = SseConnectionStatus.disconnected;

  /// Public getter so [SessionDetailScreen] can read the status.
  SseConnectionStatus get connectionStatus => _sseClient.status;

  /// Resolve keyboard layout from the session command.
  PtyKeyboardConfig get _keyboardConfig =>
      PtyKeyboardConfig.fromCommand(widget.session.cmd);

  @override
  void initState() {
    super.initState();
    _transport = HttpSseTransport(tokenProvider: widget.tokenProvider);
    _sseClient = SseClient(
      transport: _transport,
      ref: widget.serverRef,
      sessionId: widget.session.id,
      agentId: widget.agentId,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    final bufferSize = context.read<AppSettingsProvider>().terminalBufferSize;
    _terminal = Terminal(maxLines: bufferSize);
    _terminalFocusNode = FocusNode();
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

  /// Cross-flush dedup: if the last flush ended with \r, skip the next standalone
  /// \r. IME Enter often double-fires: the IME commit (text possibly with \n)
  /// + the key event \r arrive in separate microtask flushes.
  bool _lastFlushEndedWithCr = false;

  void _flushOutput() {
    _outputScheduled = false;
    if (_pendingOutput.isEmpty) return;
    // Dedup Enter sequences from mobile IME: the IME commit + xterm2 key event
    // produce \r\n, \n\r, \r\r, or standalone \n instead of a single \r.
    // Order matters: multi-char patterns first, standalone \n last.
    final normalized = _pendingOutput
        .replaceAll('\r\n', '\r')
        .replaceAll('\n\r', '\r')
        .replaceAll('\r\r', '\r')
        .replaceAll('\n', '\r');
    _pendingOutput = '';
    if (normalized.isEmpty) return;

    // Cross-flush dedup: a lone \r right after a flush that ended with \r
    // is a duplicate Enter from IME, not a second intentional press.
    final isCr = normalized == '\r';
    final endsWithCr = isCr || normalized.endsWith('\r');
    if (isCr && _lastFlushEndedWithCr) {
      _lastFlushEndedWithCr = false; // consume the duplicate
      return;
    }
    _lastFlushEndedWithCr = endsWithCr;

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
    _sseClient
      ..onChunk = (chunk) {
        final text = utf8.decode(chunk.data, allowMalformed: true);
        _terminal.write(text);
      }
      ..onState = (session) {
        if (session.status == SessionStatus.exited) {
          _terminal.write(
            '\r\n\x1b[33m[${AppStrings.of.ptySessionExited}]\x1b[0m\r\n',
          );
          _pulseController.stop();
          if (mounted) setState(() {});
        }
      }
      ..onError = (error) {
        debugPrint('[PtySessionView] SSE error: $error');
        if (mounted) setState(() {});
      }
      ..onHeartbeat = () {
        // Reconnection success → smooth transition to connected.
        if (_sseClient.status == SseConnectionStatus.connected &&
            _prevStatus == SseConnectionStatus.reconnecting) {
          _pulseController.stop();
          _prevStatus = SseConnectionStatus.connected;
        }
        if (mounted) setState(() {});
      };

    await _sseClient.start();
    if (mounted) setState(() {});
  }

  /// Toggle the system keyboard (IME) on/off. Only affects the IME; the
  /// extended keyboard panel ([_keyboardExpanded]) is untouched.
  void _toggleIme() {
    final wasHidden = _hardwareKeyboardOnly;
    setState(() {
      _hardwareKeyboardOnly = !_hardwareKeyboardOnly;
    });
    // After the frame swaps CustomKeyboardListener ↔ CustomTextEdit, drive the
    // input connection directly. Old code did unfocus→refocus, which closed and
    // reopened the connection in the same frame — Android's IME hide/show race
    // intermittently left the keyboard shown without a viewInsets change, so the
    // terminal never shrank and the keyboard covered it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (wasHidden) {
        _terminalViewKey.currentState?.requestKeyboard();
      } else {
        _terminalViewKey.currentState?.closeKeyboard();
      }
    });
  }

  /// Public — called from [SessionDetailScreen] via GlobalKey to
  /// resubscribe the SSE stream without re-fetching history.
  void reconnect() {
    _prevStatus = _sseClient.status;
    _sseClient.reconnect();
    _pulseController.repeat(reverse: true);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sseClient.close();
    _pulseController.dispose();
    _terminalFocusNode.dispose();
    _modifierState.dispose();
    super.dispose();
  }

  // ── Status banner ─────────────────────────────────────────────────

  /// Animated status banner — slides in/out with pulsing reconnect dot.
  Widget _statusBanner() {
    final c = context.appColors;
    final bool visible;
    final Color color;
    final String label;
    final bool isReconnecting;

    switch (_sseClient.status) {
      case SseConnectionStatus.connected:
        visible = false;
        color = c.success;
        label = '';
        isReconnecting = false;
      case SseConnectionStatus.reconnecting:
        visible = true;
        color = c.warning;
        label = AppStrings.of.ptyReconnecting;
        isReconnecting = true;
      case SseConnectionStatus.disconnected:
        visible = true;
        color = c.textSecondary;
        label = _sseClient.sessionExited
            ? AppStrings.of.ptySessionExited
            : AppStrings.of.ptyDisconnected;
        isReconnecting = false;
    }

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -2),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: visible
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.three,
                  vertical: AppSpacing.one,
                ),
                color: color.withAlpha(25),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing status dot
                    isReconnecting
                        ? AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (_, _) => Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withAlpha(
                                      (_pulseAnimation.value * 120).toInt(),
                                    ),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withAlpha(120),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(width: AppSpacing.two),
                    ThemedText.mono(label, color: color),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final terminalTheme = context.watch<AppSettingsProvider>().terminalTheme;
    return Scaffold(
      // SessionDetailScreen 的外层 Scaffold 已按 viewInsets 收缩 body，
      // 内层再 shrink 会双重收缩（终端下方多出整块键盘高度）。
      resizeToAvoidBottomInset: false,
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Status banner
            _statusBanner(),
            Expanded(
              child: Listener(
                onPointerDown: (_) {
                  final now = DateTime.now();
                  final gap = _lastTapDown != null
                      ? now.difference(_lastTapDown!).inMilliseconds
                      : null;
                  _lastTapDown = now;

                  // Double-tap within 400ms → toggle system keyboard.
                  if (gap != null && gap < 400) {
                    _toggleIme();
                  }
                },
                child: ScrollConfiguration(
                  behavior: const PtyScrollBehavior(),
                  child: TerminalView(
                    _terminal,
                    key: _terminalViewKey,
                    theme: terminalTheme,
                    autofocus: false,
                    hardwareKeyboardOnly: _hardwareKeyboardOnly,
                    focusNode: _terminalFocusNode,
                    backgroundOpacity: 1.0,
                    deleteDetection: true,
                  ),
                ),
              ),
            ),
            PtyKeyboardPanel(
              config: _keyboardConfig,
              modifierState: _modifierState,
              expanded: _keyboardExpanded,
              imeActive: !_hardwareKeyboardOnly,
              onToggle: () =>
                  setState(() => _keyboardExpanded = !_keyboardExpanded),
              onToggleIme: _toggleIme,
              onSendBytes: (bytes) => _transport.sendInput(
                widget.serverRef,
                widget.session.id,
                bytes,
                agentId: widget.agentId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
