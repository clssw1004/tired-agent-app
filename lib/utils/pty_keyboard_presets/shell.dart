import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// Builtin shell layout — bash, zsh, sh, fish.
///
/// Modifiers + navigation + a few command macros (/resume, /clear, /compact).
final PtyKeyboardConfig shellPreset = PtyKeyboardConfig(
  id: 'shell',
  name: 'Shell',
  rows: [
    // Row 1 — command macros
    [
      TerminalKeys.combo([
        TerminalKeyCode.shift,
        TerminalKeyCode.tab,
      ], label: 'Mode'),
      TerminalKeys.commandShowIcon(
        icon: FontAwesomeIcons.play.data,
        command: '/resume',
        withEnter: true,
        confirm: true,
      ),
      TerminalKeys.commandShowIcon(
        icon: FontAwesomeIcons.broom.data,
        command: '/clear',
        withEnter: true,
        confirm: true,
      ),
      TerminalKeys.commandShowIcon(
        icon: FontAwesomeIcons.compress.data,
        command: '/compact',
        withEnter: true,
        confirm: true,
      ),
      TerminalKeys.commandShowIcon(
        icon: FontAwesomeIcons.codeBranch.data,
        command: '!git fetch --all;git checkout main;git rebase origin/main',
        withEnter: true,
        confirm: true,
      ),
      TerminalKeys.backspace,
    ],
    // Row 2 — escape + shift + tab + nav + enter
    [
      TerminalKeys.escape,
      TerminalKeys.shift,
      TerminalKeys.tab,
      TerminalKeys.commandShowText(label: '@', command: '!@'),

      TerminalKeys.up,
      TerminalKeys.enter,
    ],
    // Row 3 — ctrl + alt + arrows
    [
      TerminalKeys.ctrl,
      TerminalKeys.commandShowText(label: '!', command: '!'),
      TerminalKeys.commandShowText(label: '/', command: '/'),
      TerminalKeys.left,
      TerminalKeys.down,
      TerminalKeys.right,
    ],
  ],
);
