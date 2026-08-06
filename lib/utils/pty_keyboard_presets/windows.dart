import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/pty_keyboard_presets/shell.dart';

/// Builtin Windows layout — cmd.exe, PowerShell.
///
/// Currently mirrors the shell preset; kept as a separate file so future
/// Windows-specific keys (Win, App, etc.) can be added without touching the
/// shell layout.
final PtyKeyboardConfig windowsPreset = PtyKeyboardConfig(
  id: 'windows',
  name: 'Windows',
  rows: shellPreset.rows,
);