import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Geek-mode text-only card — 终端风格纯文字排版。
class GeekAgentCard extends StatelessWidget {
  final AgentInfo agent;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GeekAgentCard({
    super.key,
    required this.agent,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  String _statusLabel(AgentState s) => switch (s) {
    AgentState.online => '+online',
    AgentState.offline => '-offline',
    AgentState.pending => '~pending',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final statusColor = switch (agent.state) {
      AgentState.online => c.success,
      AgentState.offline => c.danger,
      AgentState.pending => c.textSecondary,
    };

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ThemedText('> ', fontSize: 12, fontFamily: 'monospace', color: c.primary),
                ThemedText.mono(agent.name, color: c.text),
                const SizedBox(width: 6),
                ThemedText(_statusLabel(agent.state), fontSize: 11, fontFamily: 'monospace', color: statusColor),
                const Spacer(),
                if (onEdit != null)
                  ThemedText('[edit]', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
              ],
            ),
            ThemedText('│ ${agent.baseUrl}', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (agent.platform != null)
              ThemedText('│ ${agent.platform!.os} ${agent.platform!.arch}', fontSize: 11, fontFamily: 'monospace', color: c.primary.withAlpha(120)),
          ],
        ),
      ),
    );
  }
}
