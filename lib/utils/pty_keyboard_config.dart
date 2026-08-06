import 'package:tired_agent_app/utils/pty_keyboard_presets/minimal.dart';
import 'package:tired_agent_app/utils/pty_keyboard_presets/shell.dart';
import 'package:tired_agent_app/utils/pty_keyboard_presets/windows.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// PTY keyboard panel layout configuration.
///
/// Each [PtyKeyboardConfig] holds the row definitions for the virtual keyboard
/// panel. Different session presets (bash, cmd.exe, python3, …) load different
/// configs so the buttons shown match the shell's needs.
///
/// The three builtin presets live in their own files under
/// `pty_keyboard_presets/`: `shell.dart`, `minimal.dart`, `windows.dart`.
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

  /// All builtin presets, in display order.
  static final List<PtyKeyboardConfig> presets = [
    shellPreset,
    minimalPreset,
    windowsPreset,
  ];

  /// Resolve a builtin preset by [id], or `null` if not found.
  static PtyKeyboardConfig? byId(String id) {
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Resolve a config from the session command string.
  ///
  /// [cmd] is the executable name (e.g. `"/bin/bash"`, `"powershell.exe"`).
  static PtyKeyboardConfig fromCommand(String cmd) {
    final name = cmd.split(RegExp(r'[/\\]')).last;

    if (name == 'python3' || name == 'python' || name == 'node') {
      return minimalPreset;
    }
    if (name == 'cmd.exe' || name == 'powershell.exe') {
      return windowsPreset;
    }
    // bash, zsh, sh, fish, etc.
    return shellPreset;
  }
}