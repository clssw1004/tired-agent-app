import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

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
