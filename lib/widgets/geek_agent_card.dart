import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Geek-mode 纯终端风格卡片 — 填满宽度。
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.two),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border.withAlpha(40), width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ThemedText('> ', fontSize: 12, fontFamily: 'monospace', color: c.primary),
                Expanded(
                  child: ThemedText.mono(agent.name, color: c.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                ThemedText(_statusLabel(agent.state), fontSize: 11, fontFamily: 'monospace', color: statusColor),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onEdit,
                    child: ThemedText('[edit]', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: ThemedText('[delete]', fontSize: 11, fontFamily: 'monospace', color: c.danger),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ThemedText('│ ${agent.baseUrl}', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (agent.platform != null) ...[
                  const SizedBox(width: 8),
                  ThemedText('${agent.platform!.os} ${agent.platform!.arch}', fontSize: 11, fontFamily: 'monospace', color: c.primary.withAlpha(120)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
