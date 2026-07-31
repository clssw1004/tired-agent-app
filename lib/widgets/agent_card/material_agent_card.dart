import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/agent_card/contract.dart';

/// Material Design 3 风格 Agent 卡片 — 原生 M3 ListTile，编辑/删除用 IconButton。
class MD3AgentCard extends AgentCardContract {
  const MD3AgentCard();

  @override
  Widget build(BuildContext context, AgentCardData data) {
    final agent = data.agent;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final statusColor = switch (agent.state) {
      AgentState.online => scheme.primary,
      AgentState.offline => scheme.error,
      AgentState.pending => scheme.onSurfaceVariant,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: data.onTap,
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        title: Text(
          agent.name,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              agent.baseUrl,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (agent.platform != null)
              Text(
                '${agent.platform!.os} · ${agent.platform!.arch}',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.onEdit != null)
              IconButton(
                onPressed: data.onEdit,
                tooltip: AppStrings.of.agentEditTooltip,
                icon: Icon(Icons.edit_outlined, size: 18, color: scheme.onSurfaceVariant),
                visualDensity: VisualDensity.compact,
              ),
            if (data.onDelete != null)
              IconButton(
                onPressed: data.onDelete,
                icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
