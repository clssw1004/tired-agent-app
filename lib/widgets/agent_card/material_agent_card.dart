import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/agent_card/contract.dart';

/// Material Design 3 风格 Agent 卡片 — 原生 M3 ListTile，编辑/删除用 IconButton。
///
/// 布局紧凑：Card margin 收紧、ListTile compact、platform 并入 baseUrl 行。
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

    // ── 合并信息行（baseUrl · platform）────────────────────────
    final platform = agent.platform != null ? '${agent.platform!.os} · ${agent.platform!.arch}' : '';
    final subtitle = platform.isEmpty ? agent.baseUrl : '${agent.baseUrl} · $platform';

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        onTap: data.onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        minTileHeight: 44,
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
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
