import 'package:flutter/material.dart';

import 'package:tired_agent_app/utils/terminal_keys.dart';

/// PTY keyboard panel layout configuration.
///
/// Each [PtyKeyboardConfig] holds the row definitions for the virtual keyboard
/// panel. Different session presets (bash, cmd.exe, python3, …) load different
/// configs so the buttons shown match the shell's needs.
class PtyKeyboardConfig {
  /// Machine-friendly id (e.g. `"shell"`, `"windows"`, `"repl"`).
  final String id;

  /// Human-readable name (shown in tooltip or future settings).
  final String name;

  /// Row definitions — each sub-list is one row of buttons.
  final List<List<TerminalKeyDef>> rows;

  const PtyKeyboardConfig({
    required this.id,
    required this.name,
    required this.rows,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Presets
  // ═══════════════════════════════════════════════════════════════════════

  /// Default shell layout (bash, zsh) — modifiers + nav + command keys.
  static final shell = PtyKeyboardConfig(
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
          icon: Icons.play_arrow,
          command: '/resume',
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
        TerminalKeys.up,
        TerminalKeys.enter,
      ],
      // Row 3 — ctrl + alt + arrows
      [
        TerminalKeys.ctrl,
        TerminalKeys.alt,
        TerminalKeys.left,
        TerminalKeys.down,
        TerminalKeys.right,
      ],
    ],
  );

  /// Minimal layout (Python REPL, Node REPL) — fewer function keys.
  static final minimal = PtyKeyboardConfig(
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

  /// Windows layout (cmd.exe, PowerShell) — with Windows-specific keys.
  static final windows = PtyKeyboardConfig(
    id: 'windows',
    name: 'Windows',
    rows: shell.rows, // Same as shell for now; easy to customise later.
  );

  /// The default config when no specific preset matches.
  static final defaultConfig = shell;

  /// Resolve a config from the session command string.
  ///
  /// [cmd] is the executable name (e.g. `"/bin/bash"`, `"powershell.exe"`).
  static PtyKeyboardConfig fromCommand(String cmd) {
    final name = cmd.split(RegExp(r'[/\\]')).last;

    if (name == 'python3' || name == 'python' || name == 'node') {
      return minimal;
    }
    if (name == 'cmd.exe' || name == 'powershell.exe') {
      return windows;
    }
    // bash, zsh, sh, fish, etc.
    return shell;
  }
}
