import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Geek-mode text-only card for an agent.
class GeekAgentCard extends StatelessWidget {
  final AgentInfo agent;
  final String profileId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GeekAgentCard({
    super.key,
    required this.agent,
    required this.profileId,
    this.onEdit,
    this.onDelete,
  });

  String _statusLabel(AgentState s) => switch (s) {
    AgentState.online => '+online',
    AgentState.offline => '-offline',
    AgentState.pending => '~pending',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final statusColor = switch (agent.state) {
      AgentState.online => c.success,
      AgentState.offline => c.danger,
      AgentState.pending => c.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.two),
      child: GestureDetector(
        onTap: () => context.push('/profile/$profileId/agent/${agent.id}'),
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: c.border.withAlpha(60), width: 0.5),
          ),
          padding: const EdgeInsets.all(AppSpacing.two),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status
                    Row(
                      children: [
                        ThemedText.mono(agent.name, color: c.text),
                        const SizedBox(width: 4),
                        ThemedText( _statusLabel(agent.state), fontSize: 11, fontFamily: 'monospace', color: statusColor),
                      ],
                    ),
                    // URL
                    ThemedText(agent.baseUrl, fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                    // Platform
                    if (agent.platform != null)
                      ThemedText('${agent.platform!.os} ${agent.platform!.arch}', fontSize: 11, fontFamily: 'monospace', color: c.primary.withAlpha(120)),
                  ],
                ),
              ),
              // Actions
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.textSecondary.withAlpha(50), width: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: ThemedText('edit', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
