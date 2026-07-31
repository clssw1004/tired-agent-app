import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/agent_card/contract.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// 赛博朋克风格 Agent 卡片：状态点 + 图标按钮 + 长按删除。
class NeonAgentCard extends AgentCardContract {
  const NeonAgentCard();

  @override
  Widget build(BuildContext context, AgentCardData data) {
    final agent = data.agent;
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.three),
      child: GestureDetector(
        onTap: data.onTap,
        onLongPress: data.onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSpacing.two),
            border: Border.all(color: c.primary.withAlpha(40), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.three),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _agentColor(agent.state, c),
                    shape: BoxShape.circle,
                    boxShadow: agent.state == AgentState.online
                        ? [
                            BoxShadow(
                              color: c.success.withAlpha(80),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.three),
                // Name + URL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThemedText.body(agent.name, color: c.text),
                      const SizedBox(height: 2),
                      ThemedText.label(agent.baseUrl, color: c.textSecondary),
                      if (agent.platform != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _platformIcon(agent.platform!.os, c),
                            const SizedBox(width: 4),
                            ThemedText.mono(
                              '${agent.platform!.os} · ${agent.platform!.arch}',
                              color: c.primary.withAlpha(120),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Edit button
                if (data.onEdit != null)
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: c.textSecondary,
                    ),
                    tooltip: AppStrings.of.agentEditTooltip,
                    onPressed: data.onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                // Chevron
                Icon(Icons.chevron_right, size: 20, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _agentColor(AgentState s, AppColors c) {
    switch (s) {
      case AgentState.online:
        return c.success;
      case AgentState.offline:
        return c.danger;
      case AgentState.pending:
        return c.textSecondary;
    }
  }

  static Widget _platformIcon(String os, AppColors c) {
    IconData icon;
    Color color;
    switch (os) {
      case 'win32':
        icon = Icons.window;
        color = c.primary;
      case 'darwin':
        icon = Icons.laptop_mac;
        color = c.text;
      case 'linux':
        icon = Icons.terminal;
        color = c.warning;
      default:
        icon = Icons.devices;
        color = c.textSecondary;
    }
    return Icon(icon, size: 14, color: color.withAlpha(160));
  }
}
