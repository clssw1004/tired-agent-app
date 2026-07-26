/// Data models for session creation presets.
library;

/// A single selectable value for a [PresetOption].
class OptionValue {
  final String label;
  final List<String> args;
  final String hint;
  const OptionValue({
    required this.label,
    required this.args,
    this.hint = '',
  });
}

/// A configurable option under a preset, with one or more selectable values.
///
/// - If `values` has one entry → toggle on/off behavior.
/// - If `values` has multiple entries → picker behavior (select one).
class PresetOption {
  final String id;
  final String label;
  final String hint;
  final List<OptionValue> values;
  const PresetOption({
    required this.id,
    required this.label,
    required this.hint,
    required this.values,
  });

  bool get isToggle => values.length == 1;
}

/// A built-in command preset, with configurable options.
class BuiltinPreset {
  final String id;
  final String label;
  final String cmd;
  final String hint;
  final String emoji;
  final List<PresetOption> options;

  /// OS families this preset applies to. `null` = all platforms.
  /// `['win32']` = Windows only; `['linux', 'darwin']` = Unix only.
  final List<String>? platforms;

  const BuiltinPreset({
    required this.id,
    required this.label,
    required this.cmd,
    required this.hint,
    required this.emoji,
    this.options = const [],
    this.platforms,
  });
}

/// Number of option chips to show inline before the "+N more" button.
const int inlineOptionLimit = 3;

const List<BuiltinPreset> builtinPresets = [
  BuiltinPreset(
    id: 'claude',
    label: 'Claude',
    cmd: 'claude',
    hint: 'Anthropic Claude Code CLI',
    emoji: '✦',
    // All platforms
    options: [
      PresetOption(
        id: 'permission-mode',
        label: 'Mode',
        hint: 'Permission mode for the session',
        values: [
          OptionValue(label: 'Manual', args: ['--permission-mode', 'manual'], hint: 'Approve each action'),
          OptionValue(label: 'Auto', args: ['--permission-mode', 'auto'], hint: 'Auto approve all'),
          OptionValue(label: 'Plan', args: ['--permission-mode', 'plan'], hint: 'Plan only, no execution'),
          OptionValue(label: 'Accept edits', args: ['--permission-mode', 'acceptEdits'], hint: 'Auto accept edits'),
          OptionValue(label: 'Bypass', args: ['--permission-mode', 'bypassPermissions'], hint: 'Skip all prompts'),
          OptionValue(label: "Don't ask", args: ['--permission-mode', 'dontAsk'], hint: 'Suppress prompts'),
        ],
      ),
      PresetOption(
        id: 'skip-perms',
        label: 'Skip perms',
        hint: '--dangerously-skip-permissions',
        values: [
          OptionValue(label: 'On', args: ['--dangerously-skip-permissions']),
        ],
      ),
    ],
  ),
  BuiltinPreset(
    id: 'bash',
    label: 'Bash',
    cmd: 'bash',
    hint: 'POSIX shell',
    emoji: r'$',
    platforms: ['linux', 'darwin'],
    options: [
      PresetOption(
        id: 'interactive',
        label: 'Interactive',
        hint: 'Force interactive mode',
        values: [
          OptionValue(label: 'On', args: ['-i']),
        ],
      ),
      PresetOption(
        id: 'login',
        label: 'Login',
        hint: 'Start as a login shell',
        values: [
          OptionValue(label: 'On', args: ['-l']),
        ],
      ),
    ],
  ),
  BuiltinPreset(
    id: 'zsh',
    label: 'Zsh',
    cmd: 'zsh',
    hint: 'Z shell',
    emoji: r'$',
    platforms: ['linux', 'darwin'],
    options: [
      PresetOption(
        id: 'interactive',
        label: 'Interactive',
        hint: 'Force interactive mode',
        values: [
          OptionValue(label: 'On', args: ['-i']),
        ],
      ),
      PresetOption(
        id: 'login',
        label: 'Login',
        hint: 'Start as a login shell',
        values: [
          OptionValue(label: 'On', args: ['-l']),
        ],
      ),
    ],
  ),
  BuiltinPreset(
    id: 'cmd',
    label: 'cmd.exe',
    cmd: 'cmd.exe',
    hint: 'Windows command prompt',
    emoji: '>',
    platforms: ['win32'],
    options: [
      PresetOption(
        id: 'no-auto-run',
        label: 'No AutoRun',
        hint: 'Disable AutoRun commands',
        values: [
          OptionValue(label: 'On', args: ['/d']),
        ],
      ),
    ],
  ),
  BuiltinPreset(
    id: 'powershell',
    label: 'PowerShell',
    cmd: 'powershell.exe',
    hint: 'Windows PowerShell',
    emoji: '>',
    platforms: ['win32'],
    options: [
      PresetOption(
        id: 'no-logo',
        label: 'No logo',
        hint: 'Hide startup logo',
        values: [
          OptionValue(label: 'On', args: ['-NoLogo']),
        ],
      ),
      PresetOption(
        id: 'no-profile',
        label: 'No profile',
        hint: 'Skip profile scripts',
        values: [
          OptionValue(label: 'On', args: ['-NoProfile']),
        ],
      ),
    ],
  ),
];
