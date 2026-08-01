import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/agent_card/contract.dart';
import 'package:tired_agent_app/widgets/common/geek_action_button.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// 极简极客风格 Agent 卡片 — 纯终端排版，编辑/删除以 [edit]/[delete] 文字按钮展示（免长按）。
///
/// 布局采用"对齐网格"：提示符统一 12px monospace 垂直对齐；
/// url/platform 合并单行，去掉右分离，排版更整洁。
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

    // ── 合并信息行（url · platform）────────────────────────────
    final platform = agent.platform != null ? '${agent.platform!.os} · ${agent.platform!.arch}' : '';
    final urlLine = platform.isEmpty ? '│ ${agent.baseUrl}' : '│ ${agent.baseUrl} · $platform';

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.two),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row1: > name + status + [edit] + [delete] ───────
            Row(
              children: [
                ThemedText.mono('> ', color: c.primary),
                Expanded(
                  child: ThemedText.mono(
                    agent.name,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ThemedText.mono(_statusLabel(agent.state), color: statusColor),
                if (data.onEdit != null) ...[
                  const SizedBox(width: 8),
                  GeekActionButton(label: 'edit', onTap: data.onEdit!, color: c.textSecondary),
                ],
                if (data.onDelete != null) ...[
                  const SizedBox(width: 8),
                  GeekActionButton(label: 'delete', onTap: data.onDelete!, color: c.danger),
                ],
              ],
            ),
            // ── Row2: url · platform ────────────────────────────
            ThemedText.mono(urlLine, color: c.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
