import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/protocol/sse_client.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/services/session_exit_notifier.dart';
import 'package:tired_agent_app/utils/pty_scroll_physics.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/pty_modifier.dart';
import 'package:tired_agent_app/widgets/shell/pty_keyboard_panel.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// PTY session view using xterm2 for terminal emulation.
class PtySessionView extends StatefulWidget {
  final String profileId;
  final ServerRef serverRef;
  final String agentId;
  final Session session;
  final Future<String?> Function()? tokenProvider;

  const PtySessionView({
    super.key,
    required this.profileId,
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

  /// Selection controller — xterm2 long-press/drag/double-tap/triple-tap
  /// gestures drive selection through this. We own it to observe selection
  /// changes (show/hide the copy bar) and to read the selected text.
  final TerminalController _terminalController = TerminalController();

  /// Whether the terminal currently has an active (non-empty) selection.
  bool _hasSelection = false;

  /// Toggle the system keyboard (IME) on/off.
  late final FocusNode _terminalFocusNode;

  /// Directly drives the IME input connection via xterm2's [TerminalViewState],
  /// bypassing the focus-node keyboard-token dance that caused hide/show races.
  final GlobalKey<TerminalViewState> _terminalViewKey = GlobalKey();
  bool _keyboardExpanded = false;

  /// When true, the system soft keyboard (IME) won't pop up on tap.
  /// Toggled via the keyboard panel's IME button.
  bool _hardwareKeyboardOnly = true;

  /// Animation for the pulsing reconnect dot.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

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
    _terminalController.addListener(_onSelectionChanged);
    _setupTerminal();
    _initialize();
    // 打开的是 running 会话 → 记录，退出时才能触发通知（running→exited 转移）。
    if (widget.session.status != SessionStatus.exited) {
      context.read<SessionExitNotifier>().trackRunning(_sessionRef());
    }
    // Send initial resize after first frame so TerminalView has actual dimensions.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialResize());
  }

  SessionRef _sessionRef({Session? session}) {
    final s = session ?? widget.session;
    return SessionRef(
      profileId: widget.profileId,
      agentId: widget.agentId,
      sessionId: widget.session.id,
      label: s.label ?? s.cmd,
      cmd: s.cmd,
    );
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
          // 快路径：SSE 实时退出 → 立即通知。
          context.read<SessionExitNotifier>().handleExited(_sessionRef(session: session));
        }
      }
      ..onError = (error) {
        debugPrint('[PtySessionView] SSE error: $error');
        if (mounted) setState(() {});
      }
      ..onConnected = () {
        // Connection (re)established → stop the pulsing reconnect dot.
        _pulseController.stop();
        if (mounted) setState(() {});
      }
      ..onReconnecting = () {
        _pulseController.repeat(reverse: true);
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
    _sseClient.reconnect();
    _pulseController.repeat(reverse: true);
    if (mounted) setState(() {});
  }

  // ── Selection / copy / paste ────────────────────────────────────

  /// Tracks xterm2 selection state; flips the copy-bar visibility.
  void _onSelectionChanged() {
    final hasSelection = _hasSelection;
    final newState = _terminalController.selectionFor(_terminal.buffer) != null;
    if (hasSelection != newState && mounted) {
      setState(() => _hasSelection = newState);
    }
  }

  /// Copy the currently selected text to the system clipboard.
  Future<void> _copySelection() async {
    final selection = _terminalController.selectionFor(_terminal.buffer);
    if (selection == null) return;
    // 不能开 trimWhitespace：窄屏折行时，折行边界上真实落在行尾的空格会被
    // trim 掉，续接后词间空格丢失（"aaaaaa bbb" 复制成 "aaaaaabbb"）。
    // 空白填充 cell 是 code-0，getText 本就跳过，不会引入整行空格噪声。
    final text = _terminal.buffer.getText(selection);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    _terminalController.clearSelection();
    _showSnack(AppStrings.of.ptyCopied);
  }

  /// Clear the current selection without copying.
  void _clearSelection() {
    _terminalController.clearSelection();
  }

  /// Select the entire terminal buffer (scrollback + viewport).
  void _selectAll() {
    _terminalController.setSelection(
      _terminal.buffer.createAnchor(0, 0),
      _terminal.buffer.createAnchor(
        _terminal.viewWidth,
        _terminal.buffer.height - 1,
      ),
      mode: SelectionMode.line,
    );
  }

  /// Paste via a textarea dialog — avoid flooding the IME input connection
  /// with large pastes. Writes the whole text in one `paste` call.
  Future<void> _pasteFromDialog() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final initial = clipboard?.text ?? '';
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _PasteDialog(controller: controller),
    );
    if (result == null || result.isEmpty) return;
    _terminal.paste(result);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: ThemedText.small(message),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _terminalController.removeListener(_onSelectionChanged);
    _terminalController.dispose();
    _sseClient.close();
    _pulseController.dispose();
    _terminalFocusNode.dispose();
    _modifierState.dispose();
    super.dispose();
  }

  // ── Status banner ─────────────────────────────────────────────────

  /// Floating action bar shown above the keyboard when text is selected —
  /// copy / select-all / clear.
  Widget _buildSelectionBar() {
    final c = context.appColors;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.two),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: c.borderGlow.withAlpha(60),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SelectionAction(
                icon: Icons.copy,
                label: AppStrings.of.ptyCopy,
                color: c.primary,
                onTap: _copySelection,
              ),
              _SelectionAction(
                icon: Icons.select_all,
                label: AppStrings.of.ptySelectAll,
                color: c.textSecondary,
                onTap: _selectAll,
              ),
              _SelectionAction(
                icon: Icons.close,
                label: '',
                color: c.textSecondary,
                onTap: _clearSelection,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ScrollConfiguration(
                      behavior: const PtyScrollBehavior(),
                      child: TerminalView(
                        _terminal,
                        key: _terminalViewKey,
                        controller: _terminalController,
                        theme: terminalTheme,
                        autofocus: false,
                        hardwareKeyboardOnly: _hardwareKeyboardOnly,
                        focusNode: _terminalFocusNode,
                        backgroundOpacity: 1.0,
                        deleteDetection: true,
                      ),
                    ),
                  ),
                  if (_hasSelection) _buildSelectionBar(),
                ],
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
              onPaste: _pasteFromDialog,
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

/// A single icon+label action in the terminal selection bar.
class _SelectionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              ThemedText.label(label, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

/// Modal textarea for pasting/typing large blocks of text. Sends the whole
/// buffer in one `paste` call instead of flooding the IME input connection
/// with per-character input requests.
class _PasteDialog extends StatefulWidget {
  final TextEditingController controller;

  const _PasteDialog({required this.controller});

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.four,
                AppSpacing.three,
                AppSpacing.four,
                AppSpacing.one,
              ),
              child: Row(
                children: [
                  Icon(Icons.content_paste, size: 18, color: c.primary),
                  const SizedBox(width: AppSpacing.two),
                  Expanded(
                    child: ThemedText.title(
                      AppStrings.of.ptyPaste,
                      color: c.text,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.three,
                  AppSpacing.two,
                  AppSpacing.three,
                  AppSpacing.one,
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                  decoration: InputDecoration(
                    hintText: AppStrings.of.ptyPasteHint,
                    hintStyle: TextStyle(
                      color: c.textSecondary.withAlpha(140),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: c.surfaceAlt.withAlpha(120),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(AppSpacing.three),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.primary, width: 1),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.three),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: ThemedText.small(
                      AppStrings.of.cancel,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.two),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.of(context)
                        .pop(widget.controller.text),
                    icon: const Icon(Icons.send, size: 16),
                    label: ThemedText.label(AppStrings.of.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
