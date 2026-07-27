import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Toggle state for modifier keys. Shared between [PtyModifierHandler] and
/// [PtyKeyboardPanel] so that toggling Ctrl/Alt/Shift in the panel causes
/// subsequent hardware-keyboard keystrokes to carry those modifiers.
class PtyModifierState extends ChangeNotifier {
  bool _ctrl = false;
  bool _alt = false;
  bool _shift = false;

  bool get ctrl => _ctrl;
  bool get alt => _alt;
  bool get shift => _shift;

  void setCtrl(bool v) {
    if (_ctrl != v) {
      _ctrl = v;
      notifyListeners();
    }
  }

  void setAlt(bool v) {
    if (_alt != v) {
      _alt = v;
      notifyListeners();
    }
  }

  void setShift(bool v) {
    if (_shift != v) {
      _shift = v;
      notifyListeners();
    }
  }

  void toggleCtrl() => setCtrl(!_ctrl);
  void toggleAlt() => setAlt(!_alt);
  void toggleShift() => setShift(!_shift);

  /// Reset all modifiers (e.g. when leaving the session).
  void reset() {
    _ctrl = false;
    _alt = false;
    _shift = false;
    notifyListeners();
  }
}

/// [TerminalInputHandler] that reads the [PtyModifierState] and, when a
/// modifier is toggled on, adds it to every hardware-keyboard event before
/// passing the event downstream.
///
/// This is the xterm2-side integration of the virtual modifier keys — it
/// makes "Ctrl" + tapping "C" on the system keyboard produce Ctrl+C (0x03).
class PtyModifierHandler implements TerminalInputHandler {
  final PtyModifierState state;
  final TerminalInputHandler next;

  const PtyModifierHandler({required this.state, required this.next});

  @override
  String? call(TerminalKeyboardEvent event) {
    if (!state.ctrl && !state.alt && !state.shift) {
      return next.call(event);
    }

    // Build a modified event with panel modifiers OR'd in.
    final modified = event.copyWith(
      ctrl: event.ctrl || state.ctrl,
      alt: event.alt || state.alt,
      shift: event.shift || state.shift,
    );

    // Let the original handler chain process the modified event.
    final result = next.call(modified);

    // Auto-release modifiers after a successfully handled key press,
    // so the user doesn't need to manually toggle off.
    if (result != null) {
      state.reset();
    }
    return result;
  }
}

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
    required this.onSendBytes,
    this.onDismissKeyboard,
  });

  /// The layout configuration (which rows and keys to show).
  final PtyKeyboardConfig config;

  final PtyModifierState modifierState;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<List<int>> onSendBytes;

  /// Called when the user taps the "dismiss keyboard" button.
  /// The parent should call [FocusScope.of(context).unfocus()] or similar.
  final VoidCallback? onDismissKeyboard;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(c),
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

  Widget _buildHandle(AppColors colors) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        color: colors.surfaceAlt,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            AnimatedRotation(
              duration: _animDuration,
              turns: expanded ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: colors.primary.withAlpha(160),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              expanded ? AppStrings.of.ptyKeyboardClose : AppStrings.of.ptyKeyboardKeys,
              style: TextStyle(
                fontSize: 11,
                color: colors.primary.withAlpha(140),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            // Active modifier indicator
            ListenableBuilder(
              listenable: modifierState,
              builder: (context, _) {
                final active = <String>[];
                if (modifierState.ctrl) active.add('Ctrl');
                if (modifierState.alt) active.add('Alt');
                if (modifierState.shift) active.add('Shift');
                if (active.isEmpty) return const SizedBox.shrink();
                return Text(
                  active.join('+'),
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const Spacer(),
            // Dismiss system keyboard button
            GestureDetector(
              onTap: () {
                onDismissKeyboard?.call();
                onToggle();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.keyboard_hide_outlined,
                  size: 15,
                  color: colors.textSecondary.withAlpha(160),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<TerminalKeyDef> keys, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: keys.map((k) => Expanded(child: _buildKeyButton(k, colors))).toList(),
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

// --- Internal button widgets --------------------------------------------

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
            border: Border.all(
              color: c.border.withAlpha(100),
              width: 0.5,
            ),
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
