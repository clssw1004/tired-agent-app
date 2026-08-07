import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/pty_modifier.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/common/neon_dialog.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/shell/pty_key_cap.dart';

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
    required this.onPaste,
    required this.onSendBytes,
    this.schemeName,
    this.onSwitchScheme,
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

  /// Open the textarea paste dialog.
  final VoidCallback onPaste;

  final ValueChanged<List<int>> onSendBytes;

  /// Current keyboard scheme name — shown in the expanded header.
  final String? schemeName;

  /// Open the scheme switcher sheet.
  final VoidCallback? onSwitchScheme;

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
          onPaste: onPaste,
          colors: c,
          modifierState: modifierState,
          schemeName: schemeName,
          onSwitchScheme: onSwitchScheme,
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

/// Handle bar split into four evenly-divided tap zones:
///
/// 1. **Extended keys** toggle — grayed when collapsed, lit up when expanded.
/// 2. **Scheme/mode** switch — shows the active keyboard scheme; tapping opens
///    the switcher. Always visible, even when the panel is collapsed.
/// 3. **Paste** — opens the textarea paste dialog.
/// 4. **IME** toggle — shows/hides the system keyboard.
class _ExpandHandle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final bool imeActive;
  final VoidCallback onToggleIme;
  final VoidCallback onPaste;
  final AppColors colors;
  final PtyModifierState modifierState;
  final String? schemeName;
  final VoidCallback? onSwitchScheme;

  const _ExpandHandle({
    required this.expanded,
    required this.onToggle,
    required this.imeActive,
    required this.onToggleIme,
    required this.onPaste,
    required this.colors,
    required this.modifierState,
    this.schemeName,
    this.onSwitchScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: colors.surfaceAlt,
      child: Row(
        children: [
          // ── 1. Extended keyboard toggle ──────────────────────────
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 28,
                alignment: Alignment.center,
                // FittedBox so the active-modifier badge (Ctrl/Alt/Shift)
                // scales down instead of overflowing the narrower button.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.extension_outlined,
                        size: 14,
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
                          letterSpacing: 0.5,
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
          ),
          _vSep(colors),

          // ── 2. Scheme/mode switch — adjacent to 扩展键 ──────────
          if (schemeName != null && onSwitchScheme != null) ...[
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: onSwitchScheme,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 28,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          schemeName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.unfold_more, size: 12, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ),
            _vSep(colors),
          ],

          // ── 3. Paste — opens textarea dialog for large text ────
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: onPaste,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 28,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.content_paste,
                      size: 14,
                      color: colors.textSecondary.withAlpha(180),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.of.ptyPaste,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary.withAlpha(160),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _vSep(colors),

          // ── 4. IME toggle ─────────────────────────────────────
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
                    Icon(
                      Icons.keyboard_outlined,
                      size: 14,
                      color: imeActive
                          ? colors.primary
                          : colors.textSecondary.withAlpha(120),
                    ),
                    const SizedBox(width: 4),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thin vertical separator between toggle-bar segments.
  Widget _vSep(AppColors colors) =>
      Container(width: 0.5, height: 16, color: colors.border.withAlpha(60));
}

// ═══════════════════════════════════════════════════════════════════════════
// Internal button widgets
// ═══════════════════════════════════════════════════════════════════════════

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
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final active = switch (keyDef.id) {
          'ctrl' => state.ctrl,
          'alt' => state.alt,
          'shift' => state.shift,
          _ => false,
        };
        return PtyKeyCap(
          keyDef: keyDef,
          lit: active,
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
    return PtyKeyCap(
      keyDef: keyDef,
      onTap: keyDef.bytes.isNotEmpty || keyDef.id == 'tab'
          ? () => _onTap(context)
          : null,
    );
  }
}
