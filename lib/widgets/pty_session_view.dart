import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
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
  /// Must be initialized after [initState] when we can access [AppSettingsProvider].
  late final Terminal _terminal;
  final HttpSseTransport _transport = HttpSseTransport();
  final PtyModifierState _modifierState = PtyModifierState();
  /// Toggle the system keyboard (IME) on/off.
  late final FocusNode _terminalFocusNode;
  Subscription? _subscription;
  int _currentOffset = 0;
  bool _keyboardExpanded = false;

  /// When true, the system soft keyboard (IME) won't pop up on tap.
  /// Toggled by double-tap on the terminal area.
  bool _hardwareKeyboardOnly = true;

  /// Timestamp of the last pointer-down event, for double-tap detection.
  DateTime? _lastTapDown;

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

  /// Toggle the system keyboard (IME) on/off.
  /// [extraState] is called inside the same [setState] for any additional changes.
  void _toggleIme({VoidCallback? extraState}) {
    final wasHidden = _hardwareKeyboardOnly;
    setState(() {
      _hardwareKeyboardOnly = !_hardwareKeyboardOnly;
      extraState?.call();
    });
    if (wasHidden) {
      // Showing IME: unfocus now to consume any stale keyboard token,
      // then generate a fresh one after the frame rebuild.
      _terminalFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _terminalFocusNode.requestFocus();
      });
    } else {
      _terminalFocusNode.unfocus();
    }
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
    _terminalFocusNode.dispose();
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
    final terminalTheme = context.watch<AppSettingsProvider>().terminalTheme;
    return Scaffold(
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
                  behavior: const _PtyScrollBehavior(),
                  child: TerminalView(
                    _terminal,
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
              onToggleIme: () => _toggleIme(
                extraState: () => _keyboardExpanded = false,
              ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Custom scroll physics — responsive drag + controlled fling
// ═══════════════════════════════════════════════════════════════════════════

/// Custom scroll behavior for the PTY terminal view.
///
/// Uses [_PtyScrollPhysics] which combines [BouncingScrollPhysics]-style
/// responsive drag feel with [ClampingScrollPhysics]-style ballistic fling
/// control — the terminal buffer is very tall (thousands of lines), so even
/// a moderate ballistic fling can scroll through hundreds of lines unless the
/// deceleration is properly bounded.
///
/// Also uses [RangeMaintainingScrollPhysics] to prevent position snapping
/// when new terminal output is appended during a scroll.
class _PtyScrollBehavior extends ScrollBehavior {
  const _PtyScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const _PtyScrollPhysics(
      parent: RangeMaintainingScrollPhysics(),
    );
  }
}

/// Hybrid scroll physics for terminal content.
///
/// - **Drag**: 1:1 finger-to-scroll mapping with low (3.5 px) start threshold
///   — feels responsive like [BouncingScrollPhysics].
/// - **Fling**: Uses [ClampingScrollSimulation] which has ~67× higher effective
///   friction than [BouncingScrollSimulation], preventing the "whoosh" effect
///   where a light flick scrolls through half the buffer.
/// - **Overscroll**: Uses spring simulation to gently return in-range.
class _PtyScrollPhysics extends ScrollPhysics {
  const _PtyScrollPhysics({super.parent});

  @override
  _PtyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _PtyScrollPhysics(parent: buildParent(ancestor));
  }

  // ── Drag ──────────────────────────────────────────────────────

  /// Low threshold — finger starts affecting scroll immediately.
  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  /// 1:1 drag mapping for responsive feel (like [BouncingScrollPhysics]).
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset;
  }

  /// Allow overscroll so the drag can enter the overscroll region
  /// (the spring simulation will return it).
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) =>
      0.0;

  // ── Fling ─────────────────────────────────────────────────────

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);

    // Overscroll — use a spring to gently return in-range.
    if (position.outOfRange) {
      final end = position.pixels > position.maxScrollExtent
          ? position.maxScrollExtent
          : position.minScrollExtent;
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end,
        velocity.clamp(-2000.0, 2000.0),
        tolerance: tolerance,
      );
    }

    // In-range fling — use ClampingScrollSimulation for controlled
    // deceleration (much higher friction than BouncingScrollSimulation).
    if (velocity.abs() < tolerance.velocity) return null;
    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }

    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }
}
