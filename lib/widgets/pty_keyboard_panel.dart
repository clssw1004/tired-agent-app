import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/pty_modifier.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Collapsible virtual keyboard panel providing modifier keys (Shift/Ctrl/Alt),
/// arrow keys, and other special keys (Esc/Tab/Enter/Backspace/Home/End) that
/// are missing from mobile soft keyboards.
///
/// Button rows are defined by [PtyKeyboardConfig] — different session presets
/// (shell, windows, repl, …) load different layouts.
///
/// When collapsed only a thin toggle handle is visible.
class PtyKeyboardPanel extends StatelessWidget {
  const PtyKeyboardPanel({
    super.key,
    required this.config,
    required this.modifierState,
    required this.expanded,
    required this.onToggle,
    required this.imeActive,
    required this.onToggleIme,
    required this.onSendBytes,
  });

  /// The layout configuration (which rows and keys to show).
  final PtyKeyboardConfig config;

  final PtyModifierState modifierState;
  final bool expanded;
  final VoidCallback onToggle;

  /// Whether the system keyboard (IME) is currently active.
  final bool imeActive;

  /// Toggle the system keyboard (IME) on/off.
  final VoidCallback onToggleIme;

  final ValueChanged<List<int>> onSendBytes;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ExpandHandle(
          expanded: expanded,
          onToggle: onToggle,
          imeActive: imeActive,
          onToggleIme: onToggleIme,
          colors: c,
          modifierState: modifierState,
        ),
        if (expanded) ...[
          for (final row in config.rows) ...[
            const SizedBox(height: 4),
            _buildRow(row, c),
          ],
          const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildRow(List<TerminalKeyDef> keys, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: keys
            .map((k) => Expanded(child: _buildKeyButton(k, colors)))
            .toList(),
      ),
    );
  }

  Widget _buildKeyButton(TerminalKeyDef key, AppColors colors) {
    if (key.isMod) {
      return _ModifierButton(
        keyDef: key,
        state: modifierState,
        onSendBytes: onSendBytes,
      );
    }
    return _KeyButton(
      keyDef: key,
      modifierState: modifierState,
      onSendBytes: onSendBytes,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Toggle handle — two halves: 扩展键 toggle | IME toggle
// ═══════════════════════════════════════════════════════════════════════════

/// Handle bar split into two tap zones:
///
/// - **Left half**: toggle the extended keyboard panel. Grayed when collapsed,
///   lit up when expanded.
/// - **Right half**: toggle the system keyboard (IME). Grayed when hidden,
///   lit up when visible.
class _ExpandHandle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final bool imeActive;
  final VoidCallback onToggleIme;
  final AppColors colors;
  final PtyModifierState modifierState;

  const _ExpandHandle({
    required this.expanded,
    required this.onToggle,
    required this.imeActive,
    required this.onToggleIme,
    required this.colors,
    required this.modifierState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: colors.surfaceAlt,
      child: Row(
        children: [
          // ── Left half: Extended keyboard toggle ──────────────────
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 28,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.extension,
                      size: 16,
                      color: expanded
                          ? colors.primary
                          : colors.textSecondary.withAlpha(120),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.of.ptyKeyboardKeys,
                      style: TextStyle(
                        fontSize: 11,
                        color: expanded
                            ? colors.primary
                            : colors.textSecondary.withAlpha(140),
                        letterSpacing: 1.0,
                      ),
                    ),
                    // Modifier indicator badge
                    ListenableBuilder(
                      listenable: modifierState,
                      builder: (context, _) {
                        final active = <String>[];
                        if (modifierState.ctrl) active.add('Ctrl');
                        if (modifierState.alt) active.add('Alt');
                        if (modifierState.shift) active.add('Shift');
                        if (active.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            active.join('+'),
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Separator line
          Container(width: 0.5, height: 16, color: colors.border.withAlpha(60)),

          // ── Right half: IME toggle ──────────────────────────────
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: onToggleIme,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 28,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'IME',
                      style: TextStyle(
                        fontSize: 11,
                        color: imeActive
                            ? colors.primary
                            : colors.textSecondary.withAlpha(140),
                        fontWeight: imeActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_outlined,
                      size: 16,
                      color: imeActive
                          ? colors.primary
                          : colors.textSecondary.withAlpha(120),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Internal button widgets
// ═══════════════════════════════════════════════════════════════════════════

const _animDuration = Duration(milliseconds: 200);

/// Check whether a key is an arrow key — those get a larger label.
bool _isArrow(TerminalKeyDef k) =>
    k.id == 'up' || k.id == 'down' || k.id == 'left' || k.id == 'right';

/// A toggle button for Ctrl / Alt / Shift.
class _ModifierButton extends StatelessWidget {
  const _ModifierButton({
    required this.keyDef,
    required this.state,
    required this.onSendBytes,
  });

  final TerminalKeyDef keyDef;
  final PtyModifierState state;
  final ValueChanged<List<int>> onSendBytes;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final active = switch (keyDef.id) {
          'ctrl' => state.ctrl,
          'alt' => state.alt,
          'shift' => state.shift,
          _ => false,
        };
        final accent = switch (keyDef.id) {
          'ctrl' => c.primary,
          'alt' => c.secondary,
          'shift' => c.warning,
          _ => c.primary,
        };
        return _build(
          active: active,
          accent: accent,
          colors: c,
          label: keyDef.label,
          onTap: () {
            HapticFeedback.selectionClick();
            if (keyDef.id == 'ctrl') {
              state.toggleCtrl();
            } else if (keyDef.id == 'alt') {
              state.toggleAlt();
            } else if (keyDef.id == 'shift') {
              state.toggleShift();
            }
          },
        );
      },
    );
  }

  Widget _build({
    required bool active,
    required Color accent,
    required AppColors colors,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _animDuration,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? accent.withAlpha(25) : colors.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active ? accent : colors.border.withAlpha(100),
              width: active ? 1.0 : 0.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withAlpha(50),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? accent : colors.textCode,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single-shot key button that sends its escape sequence when tapped.
class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.keyDef,
    required this.modifierState,
    required this.onSendBytes,
  });

  final TerminalKeyDef keyDef;
  final PtyModifierState modifierState;
  final ValueChanged<List<int>> onSendBytes;

  /// Backtab escape sequence (\E[Z) sent when Shift+Tab is used.
  static const _backtab = [0x1B, 0x5B, 0x5A];

  void _onTap(BuildContext context) {
    final c = context.appColors;
    HapticFeedback.lightImpact();

    if (keyDef.confirm) {
      assert(keyDef.confirmMessage != null);
      NeonDialog.show<bool>(
        context: context,
        title: keyDef.confirmMessage!,
        maxWidth: 340,
        showRobot: true,
        content: ThemedText.body(
          AppStrings.of.ptyKeyboardConfirmSend,
          color: c.textSecondary,
        ),
        actions: [
          NeonDialogAction(
            label: AppStrings.of.cancel,
            onPressed: (ctx) => Navigator.of(ctx).pop(false),
          ),
          NeonDialogAction(
            label: AppStrings.of.send,
            isDanger: true,
            onPressed: (ctx) => Navigator.of(ctx).pop(true),
          ),
        ],
      ).then((confirmed) {
        if (confirmed == true) _send();
      });
    } else {
      _send();
    }
  }

  void _send() {
    if (keyDef.id == 'tab' && modifierState.shift) {
      onSendBytes(_backtab);
      modifierState.setShift(false);
    } else if (keyDef.bytes.isNotEmpty) {
      onSendBytes(keyDef.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: GestureDetector(
        onTap: keyDef.bytes.isNotEmpty || keyDef.id == 'tab'
            ? () => _onTap(context)
            : null,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: c.border.withAlpha(100), width: 0.5),
          ),
          child: keyDef.icon != null
              ? Icon(keyDef.icon, size: 16, color: c.textCode)
              : Text(
                  keyDef.label,
                  style: TextStyle(
                    fontSize: _isArrow(keyDef) ? 14 : 10,
                    fontWeight: _isArrow(keyDef)
                        ? FontWeight.w300
                        : FontWeight.w500,
                    color: c.textCode,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
