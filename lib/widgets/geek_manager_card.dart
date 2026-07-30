import 'package:flutter/material.dart';
import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Geek-mode text-only card — 终端风格纯文字排版。
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
                ThemedText.mono(profile.name, color: c.text),
                const SizedBox(width: 6),
                ThemedText(_statusLabel(connStatus), fontSize: 11, fontFamily: 'monospace', color: statusColor),
                if (connection.error != null) ...[
                  const SizedBox(width: 4),
                  ThemedText('!${connection.error}', fontSize: 11, fontFamily: 'monospace', color: c.danger, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
            ThemedText('│ ${profile.baseUrl}', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (hasAgentInfo || profile.lastUsedMs > 0)
              ThemedText(
                '│ ${hasAgentInfo
                  ? pendingAgents > 0
                      ? AppStrings.of.managerAgentCountsWithPending(totalAgents, onlineAgents, offlineAgents, pendingAgents)
                      : AppStrings.of.managerAgentCounts(totalAgents, onlineAgents, offlineAgents)
                  : ''}${hasAgentInfo && profile.lastUsedMs > 0 ? '  |  ' : ''}${profile.lastUsedMs > 0 ? _timeSince(profile.lastUsedMs) : ''}',
                fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
