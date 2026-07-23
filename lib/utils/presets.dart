import 'package:tired_agent_app/protocol/types.dart';

class CmdPreset {
  final String label;
  final String cmd;
  final List<String> args;
  final String? description;
  final SessionMode? mode;
  final ExecutionMode? executionMode;
  const CmdPreset({required this.label, required this.cmd, this.args = const [], this.description, this.mode, this.executionMode});
}

class CmdPresets {
  static const List<CmdPreset> defaults = [
    CmdPreset(label: 'Bash', cmd: 'bash', description: 'Interactive shell'),
    CmdPreset(label: 'Claude Chat', cmd: 'claude', args: ['--persistent'], description: 'Claude AI chat session', mode: SessionMode.persistent, executionMode: ExecutionMode.auto),
    CmdPreset(label: 'Claude Auto', cmd: 'claude', args: ['--persistent', '--execution-mode', 'auto'], description: 'Claude with auto execution', mode: SessionMode.persistent, executionMode: ExecutionMode.auto),
    CmdPreset(label: 'Claude Manual', cmd: 'claude', args: ['--persistent', '--execution-mode', 'manual'], description: 'Claude with manual approval', mode: SessionMode.persistent, executionMode: ExecutionMode.manual),
    CmdPreset(label: 'Claude Plan', cmd: 'claude', args: ['--persistent', '--execution-mode', 'plan'], description: 'Claude plan mode', mode: SessionMode.persistent, executionMode: ExecutionMode.plan),
  ];
  static CmdPreset? find(String label) {
    try { return defaults.firstWhere((p) => p.label == label); } catch (_) { return null; }
  }
}
