import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/agent_card/contract.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// 极简极客风格 Agent 卡片 — 纯终端排版，编辑/删除以 [edit]/[delete] 文字按钮展示（免长按）。
class GeekAgentCard extends AgentCardContract {
  const GeekAgentCard();

  String _statusLabel(AgentState s) => switch (s) {
    AgentState.online => '+online',
    AgentState.offline => '-offline',
    AgentState.pending => '~pending',
  };

  @override
  Widget build(BuildContext context, AgentCardData data) {
    final agent = data.agent;
    final c = context.appColors;
    final statusColor = switch (agent.state) {
      AgentState.online => c.success,
      AgentState.offline => c.danger,
      AgentState.pending => c.textSecondary,
    };

    return GestureDetector(
      onTap: data.onTap,
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
                if (data.onEdit != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: data.onEdit,
                    child: ThemedText('[edit]', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
                  ),
                ],
                if (data.onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: data.onDelete,
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
