import 'package:flutter/material.dart';
import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/geek_action_button.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/manager_card/contract.dart';

/// 极简极客风格 Manager 卡片 — 纯终端排版，删除以 [delete] 文字按钮展示（免长按）。
///
/// 布局采用"对齐网格"：提示符统一 12px monospace 垂直对齐；
/// url/lastUsed、agent 统计合并单行，减少右对齐点。
class GeekManagerCard extends ManagerCardContract {
  const GeekManagerCard();

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}s';
    if (s < 3600000) return '${s ~/ 60000}m';
    if (s < 86400000) return '${s ~/ 3600000}h';
    return '${s ~/ 86400000}d';
  }

  String _statusLabel(ConnectionStatus s) => switch (s) {
    ConnectionStatus.connected => '+online',
    ConnectionStatus.connecting => '~connecting',
    ConnectionStatus.error => '!error',
    ConnectionStatus.idle => '-offline',
  };

  @override
  Widget build(BuildContext context, ManagerCardData data) {
    final connection = data.connection;
    final profile = connection.profile;
    final connStatus = connection.status;
    final agents = connection.agents;
    final totalAgents = agents.length;
    final onlineAgents = agents
        .where((a) => a.state == AgentState.online)
        .length;
    final offlineAgents = agents
        .where((a) => a.state == AgentState.offline)
        .length;
    final pendingAgents = agents
        .where((a) => a.state == AgentState.pending)
        .length;
    final hasAgentInfo = totalAgents > 0;
    final c = context.appColors;
    final statusColor = switch (connStatus) {
      ConnectionStatus.connected => c.success,
      ConnectionStatus.connecting => c.warning,
      ConnectionStatus.error => c.danger,
      ConnectionStatus.idle => c.textSecondary,
    };

    // ── 合并信息行（url · last used）───────────────────────────
    final lastUsed = profile.lastUsedMs > 0
        ? _timeSince(profile.lastUsedMs)
        : '';
    final urlLine = lastUsed.isEmpty
        ? '│ ${profile.baseUrl}'
        : '│ ${profile.baseUrl} · $lastUsed';
    final agentsLine = hasAgentInfo
        ? '│ ${pendingAgents > 0 ? AppStrings.of.managerAgentCountsWithPending(totalAgents, onlineAgents, offlineAgents, pendingAgents) : AppStrings.of.managerAgentCounts(totalAgents, onlineAgents, offlineAgents)}'
        : '';

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.two),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row1: > name + status ──────────────────────────
            Row(
              children: [
                ThemedText.mono('> ', color: c.primary),
                Flexible(
                  child: ThemedText.mono(
                    profile.name,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                ThemedText.mono(_statusLabel(connStatus), color: statusColor),
              ],
            ),
            // ── 异常行（断链时独立展示，不挤在状态行）────────
            if (connection.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ThemedText.mono(
                  '! ${connection.error}',
                  color: c.danger,
                  height: 1.5,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // ── Row2: url · last used ───────────────────────────
            if (urlLine.isNotEmpty)
              ThemedText.mono(
                urlLine,
                color: c.textSecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // ── Row3: agent counts ──────────────────────────────
            if (agentsLine.isNotEmpty)
              ThemedText.mono(
                agentsLine,
                color: c.textSecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // ── Row4: [delete]（可点击文字按钮，免长按）────────
            if (data.onDelete != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GeekActionButton(
                    label: 'delete',
                    onTap: data.onDelete!,
                    color: c.danger,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
