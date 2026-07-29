import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Card widget for displaying a manager connection in the server list.
class ManagerCard extends StatelessWidget {
  final ManagerConnection connection;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ManagerCard({
    super.key,
    required this.connection,
    this.onTap,
    this.onDelete,
  });

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}${AppStrings.of.timeSecondsAgo}';
    if (s < 3600000) return '${s ~/ 60000}${AppStrings.of.timeMinutesAgo}';
    if (s < 86400000) return '${s ~/ 3600000}${AppStrings.of.timeHoursAgo}';
    return '${s ~/ 86400000}${AppStrings.of.timeDaysAgo}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = connection.profile;
    final connStatus = connection.status;
    final c = context.appColors;

    // Status color + label
    Color statusColor;
    String statusLabel;
    switch (connStatus) {
      case ConnectionStatus.connected:
        statusColor = c.success;
        statusLabel = AppStrings.of.statusConnected;
      case ConnectionStatus.connecting:
        statusColor = c.warning;
        statusLabel = AppStrings.of.statusConnecting;
      case ConnectionStatus.error:
        statusColor = c.danger;
        statusLabel = AppStrings.of.statusError;
      case ConnectionStatus.idle:
        statusColor = c.textSecondary;
        statusLabel = AppStrings.of.statusDisconnected;
    }

    // Agent summary (only meaningful when connected)
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.three),
      child: GestureDetector(
        onTap: () {
          if (connStatus == ConnectionStatus.connected) {
            context.push('/profile/${profile.id}');
          } else {
            onTap?.call();
          }
        },
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSpacing.two),
            border: Border.all(
              color: connStatus == ConnectionStatus.connected
                  ? c.primary.withAlpha(60)
                  : c.border.withAlpha(80),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.three,
                  AppSpacing.two,
                  AppSpacing.three,
                  AppSpacing.one,
                ),
                child: Row(
                  children: [
                    // Status dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: connStatus == ConnectionStatus.connected
                            ? [
                                BoxShadow(
                                  color: statusColor.withAlpha(80),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.two),
                    // Name + URL
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ThemedText.body(profile.name, color: c.text),
                          ThemedText.label(
                            profile.baseUrl,
                            color: c.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    // Status label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.two,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(12),
                        borderRadius: BorderRadius.circular(AppSpacing.one),
                        border: Border.all(
                          color: statusColor.withAlpha(40),
                          width: 0.5,
                        ),
                      ),
                      child: ThemedText.label(statusLabel, color: statusColor),
                    ),
                    // Error info icon
                    if (connection.error != null)
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: c.danger,
                        ),
                        onPressed: () => _showError(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    // Entry chevron hint (only when connected)
                    if (connStatus == ConnectionStatus.connected)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: c.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // ── Secondary info row ─────────────────────────────
              if (hasAgentInfo || profile.lastUsedMs > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.three,
                    0,
                    AppSpacing.three,
                    AppSpacing.two,
                  ),
                  child: Row(
                    children: [
                      if (hasAgentInfo)
                        Expanded(
                          child: ThemedText.mono(
                            pendingAgents > 0
                                ? AppStrings.of.managerAgentCountsWithPending(
                                    totalAgents,
                                    onlineAgents,
                                    offlineAgents,
                                    pendingAgents,
                                  )
                                : AppStrings.of.managerAgentCounts(
                                    totalAgents,
                                    onlineAgents,
                                    offlineAgents,
                                  ),
                            color: c.textSecondary,
                          ),
                        ),
                      if (profile.lastUsedMs > 0)
                        ThemedText.mono(
                          _timeSince(profile.lastUsedMs),
                          color: c.textSecondary,
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

  void _showError(BuildContext context) {
    final c = context.appColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(connection.error!), backgroundColor: c.danger),
    );
  }
}
