import 'package:flutter/material.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/manager_card/contract.dart';

/// Material Design 3 风格 Manager 卡片 — 原生 M3 Card + InkWell，删除用 TextButton。
///
/// 布局紧凑：Card margin 收紧、url/agent 统计/lastUsed 合并单行、delete compact。
class MD3ManagerCard extends ManagerCardContract {
  const MD3ManagerCard();

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}s';
    if (s < 3600000) return '${s ~/ 60000}m';
    if (s < 86400000) return '${s ~/ 3600000}h';
    return '${s ~/ 86400000}d';
  }

  @override
  Widget build(BuildContext context, ManagerCardData data) {
    final connection = data.connection;
    final profile = connection.profile;
    final connStatus = connection.status;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final agents = connection.agents;
    final totalAgents = agents.length;
    final onlineAgents = agents.where((a) => a.state == AgentState.online).length;
    final offlineAgents = agents.where((a) => a.state == AgentState.offline).length;
    final pendingAgents = agents.where((a) => a.state == AgentState.pending).length;

    // ── 合并信息行（url · agent 统计 · last used）─────────────
    final parts = <String>[
      profile.baseUrl,
      if (totalAgents > 0)
        pendingAgents > 0
            ? AppStrings.of.managerAgentCountsWithPending(totalAgents, onlineAgents, offlineAgents, pendingAgents)
            : AppStrings.of.managerAgentCounts(totalAgents, onlineAgents, offlineAgents),
      if (profile.lastUsedMs > 0) _timeSince(profile.lastUsedMs),
    ];
    final infoLine = parts.join(' · ');

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status dot + name + status label + error
              Row(
                children: [
                  _StatusDot(status: connStatus, scheme: scheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profile.name,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusLabel(status: connStatus, scheme: scheme),
                  if (connection.error != null)
                    IconButton(
                      onPressed: () => _showError(context, connection),
                      icon: Icon(Icons.error_outline, size: 18, color: scheme.error),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                ],
              ),
              // url · agent 统计 · last used（合并单行）
              if (infoLine.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    infoLine,
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Delete（compact）
              if (data.onDelete != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: data.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('delete'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, ManagerConnection connection) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(connection.error!)),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final ConnectionStatus status;
  final ColorScheme scheme;

  const _StatusDot({required this.status, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ConnectionStatus.connected => scheme.primary,
      ConnectionStatus.connecting => scheme.tertiary,
      ConnectionStatus.error => scheme.error,
      ConnectionStatus.idle => scheme.onSurfaceVariant,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final ConnectionStatus status;
  final ColorScheme scheme;

  const _StatusLabel({required this.status, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ConnectionStatus.connected => (AppStrings.of.statusConnected, scheme.primary),
      ConnectionStatus.connecting => (AppStrings.of.statusConnecting, scheme.tertiary),
      ConnectionStatus.error => (AppStrings.of.statusError, scheme.error),
      ConnectionStatus.idle => (AppStrings.of.statusDisconnected, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
