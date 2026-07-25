import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm2/xterm.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

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

// --- Key definitions ----------------------------------------------------

/// Collapsible virtual keyboard panel providing modifier keys (Shift/Ctrl/Alt),
/// arrow keys, and other special keys (Esc/Tab/Enter/Backspace/Home/End) that
/// are missing from mobile soft keyboards.
///
/// Layout (2 fixed rows when expanded):
///   Row 1 - [Shift] [Tab] [Esc] [^] [<-] [Enter]
///   Row 2 - [<-] [down] [->] [Home] [End] [Ctrl] [Alt]
///
/// When collapsed only a thin toggle handle is visible.
class PtyKeyboardPanel extends StatelessWidget {
  const PtyKeyboardPanel({
    super.key,
    required this.modifierState,
    required this.expanded,
    required this.onToggle,
    required this.onSendBytes,
    this.onDismissKeyboard,
  });

  final PtyModifierState modifierState;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<List<int>> onSendBytes;

  /// Called when the user taps the "dismiss keyboard" button.
  /// The parent should call [FocusScope.of(context).unfocus()] or similar.
  final VoidCallback? onDismissKeyboard;

  // -- Row layout (reorder or move keys between rows here) ---------------

  static final _row1 = [
    // Shift+Tab → backtab
    TerminalKeys.combo([
      TerminalKeyCode.shift,
      TerminalKeyCode.tab,
    ], label: 'Mode'),
    TerminalKeys.commandShowIcon(
      icon: Icons.cleaning_services,
      command: '/clear',
      withEnter: true,
      confirm: true,
    ),
    TerminalKeys.commandShowIcon(
      icon: Icons.compress,
      command: '/compact',
      withEnter: true,
      confirm: true,
    ),
    TerminalKeys.commandShowIcon(
      icon: Icons.extension,
      command: '/plugin',
      withEnter: true,
      confirm: true,
    ),
    TerminalKeys.backspace,
  ];
  static const _row2 = [
    TerminalKeys.escape,
    TerminalKeys.shift,
    TerminalKeys.tab,

    TerminalKeys.up,
    TerminalKeys.enter,
  ];
  static const _row3 = [
    TerminalKeys.ctrl,
    TerminalKeys.alt,
    TerminalKeys.left,
    TerminalKeys.down,
    TerminalKeys.right,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // -- Toggle handle ----------------------------------------------
        _buildHandle(),
        if (expanded) ...[
          const SizedBox(height: 4),
          _buildRow(_row1),
          const SizedBox(height: 4),
          _buildRow(_row2),
          const SizedBox(height: 2),
          _buildRow(_row3),
          const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildHandle() {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 22,
        color: AppColors.surfaceAlt,
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          children: [
            const SizedBox(width: 4),
            AnimatedRotation(
              duration: _animDuration,
              turns: expanded ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: AppColors.primary.withAlpha(160),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              expanded ? 'Close keyboard' : 'Keys',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary.withAlpha(140),
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const Spacer(),
            // Dismiss system keyboard button
            GestureDetector(
              onTap: () => onDismissKeyboard?.call(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.keyboard_hide_outlined,
                  size: 13,
                  color: AppColors.textSecondary.withAlpha(160),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<TerminalKeyDef> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: keys.map((k) => Expanded(child: _buildKeyButton(k))).toList(),
      ),
    );
  }

  Widget _buildKeyButton(TerminalKeyDef key) {
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
          'ctrl' => AppColors.primary,
          'alt' => AppColors.secondary,
          'shift' => AppColors.warning,
          _ => AppColors.primary,
        };
        return _build(
          active: active,
          accent: accent,
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
            color: active ? accent.withAlpha(25) : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active ? accent : AppColors.border.withAlpha(100),
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
              color: active ? accent : AppColors.textCode,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single-shot key button that sends its escape sequence when tapped.
/// Knows the [PtyModifierState] so keys like Tab can produce Shift+Tab
/// when Shift is toggled on.
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
    HapticFeedback.lightImpact();

    // If confirm is enabled, show confirmation dialog first.
    if (keyDef.confirm) {
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Confirm', style: TextStyle(color: AppColors.text)),
          content: Text(
            keyDef.confirmMessage!,
            style: const TextStyle(color: AppColors.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Send',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
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
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.border.withAlpha(100),
              width: 0.5,
            ),
          ),
          child: keyDef.icon != null
              ? Icon(keyDef.icon, size: 16, color: AppColors.textCode)
              : Text(
                  keyDef.label,
                  style: TextStyle(
                    fontSize: _isArrow(keyDef) ? 14 : 10,
                    fontWeight: _isArrow(keyDef)
                        ? FontWeight.w300
                        : FontWeight.w500,
                    color: AppColors.textCode,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
