import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// Builtin minimal layout — Python REPL, Node REPL.
///
/// Fewer function keys; modifiers + navigation only.
final PtyKeyboardConfig minimalPreset = PtyKeyboardConfig(
  id: 'minimal',
  name: 'Minimal',
  rows: [
    [
      TerminalKeys.escape,
      TerminalKeys.shift,
      TerminalKeys.tab,
      TerminalKeys.up,
      TerminalKeys.enter,
      TerminalKeys.backspace,
    ],
    [
      TerminalKeys.ctrl,
      TerminalKeys.alt,
      TerminalKeys.left,
      TerminalKeys.down,
      TerminalKeys.right,
    ],
  ],
);