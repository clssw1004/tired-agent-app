import 'package:flutter/widgets.dart';

import 'package:tired_agent_app/enhancements/enhancement.dart';
import 'package:tired_agent_app/enhancements/enhancement_context.dart';
import 'package:tired_agent_app/enhancements/types.dart';
import 'package:tired_agent_app/protocol/types.dart';

class ClaudeProjectsEnhancement extends SessionEnhancement {
  @override
  String get id => 'claude-projects';

  @override
  EnhancementActivation get activation => const EnhancementActivation(
        presetIds: ['claude'],
        commandPattern: 'claude',
      );

  @override
  EnhancementPoint get point => EnhancementPoint.directorySelected;

  @override
  Widget buildWidget(BuildContext context, EnhancementContext ctx) {
    // Resume is now handled via the --resume option chip in the
    // CreateSessionScreen — no separate block needed.
    return const SizedBox.shrink();
  }

  @override
  Future<SessionSpec> modifySpec(
      SessionSpec spec, EnhancementContext ctx) async {
    final extraArgs = <String>[];

    // Use historical session's display name as label if available.
    final label = ctx.selectedSessionDisplayName ?? spec.label;

    // Build extra metadata — always store the effective label.
    final extra = <String, dynamic>{};
    if (label != null && label.isNotEmpty) {
      extra['claudeName'] = label;
    }

    // Always inject --name <label> for claude sessions.
    if (label != null && label.isNotEmpty) {
      extraArgs.addAll(['--name', label]);
    }

    // Inject --resume if user selected a session.
    if (ctx.selectedSessionId != null) {
      extraArgs.addAll(['--resume', ctx.selectedSessionId!]);
    }

    if (extraArgs.isEmpty && extra.isEmpty) return spec;

    return SessionSpec(
      cmd: spec.cmd,
      args: [...?spec.args, ...extraArgs],
      cwd: spec.cwd,
      env: spec.env,
      cols: spec.cols,
      rows: spec.rows,
      label: label,
      mode: spec.mode,
      executionMode: spec.executionMode,
      extra: extra.isNotEmpty ? extra : null,
    );
  }
}
