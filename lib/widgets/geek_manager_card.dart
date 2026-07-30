import 'package:flutter/material.dart';
import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Geek-mode text-only card for a manager connection.
class GeekManagerCard extends StatelessWidget {
  final ManagerConnection connection;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GeekManagerCard({
    super.key,
    required this.connection,
    this.onTap,
    this.onDelete,
  });

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
  Widget build(BuildContext context) {
    final profile = connection.profile;
    final connStatus = connection.status;
    final agents = connection.agents;
    final totalAgents = agents.length;
    final onlineAgents = agents.where((a) => a.state == AgentState.online).length;
    final offlineAgents = agents.where((a) => a.state == AgentState.offline).length;
    final pendingAgents = agents.where((a) => a.state == AgentState.pending).length;
    final hasAgentInfo = totalAgents > 0;
    final c = context.appColors;
    final statusColor = switch (connStatus) {
      ConnectionStatus.connected => c.success,
      ConnectionStatus.connecting => c.warning,
      ConnectionStatus.error => c.danger,
      ConnectionStatus.idle => c.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.two),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: c.border.withAlpha(60), width: 0.5),
          ),
          padding: const EdgeInsets.all(AppSpacing.two),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name + status ──────────────────────────────────
              Row(
                children: [
                  ThemedText.mono(profile.name, color: c.text),
                  const SizedBox(width: AppSpacing.one),
                  ThemedText(_statusLabel(connStatus), fontSize: 11, fontFamily: 'monospace', color: statusColor),
                  if (connection.error != null)
                    Flexible(
                      child: ThemedText( ' !${connection.error}', fontSize: 11, fontFamily: 'monospace', color: c.danger, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
              // ── URL ────────────────────────────────────────────
              ThemedText(profile.baseUrl, fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
              // ── Agent counts + last used ───────────────────────
              if (hasAgentInfo || profile.lastUsedMs > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      if (hasAgentInfo)
                        ThemedText(
                          pendingAgents > 0
                              ? AppStrings.of.managerAgentCountsWithPending(totalAgents, onlineAgents, offlineAgents, pendingAgents)
                              : AppStrings.of.managerAgentCounts(totalAgents, onlineAgents, offlineAgents),
                          fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
                      if (profile.lastUsedMs > 0) ...[
                        if (hasAgentInfo)
                          const SizedBox(width: AppSpacing.two),
                        ThemedText(_timeSince(profile.lastUsedMs), fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
