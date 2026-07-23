import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  Color _statusColor(SessionStatus status) => switch (status) {
    SessionStatus.running => AppColors.success,
    SessionStatus.starting => AppColors.warning,
    SessionStatus.exited => AppColors.textSecondary,
  };

  String _statusLabel(SessionStatus status) => switch (status) {
    SessionStatus.running => 'Running',
    SessionStatus.starting => 'Starting',
    SessionStatus.exited => 'Exited',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundElement,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.one),
      child: ListTile(
        title: ThemedText.body(session.label ?? session.cmd),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _statusColor(session.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.two),
            ThemedText.small(_statusLabel(session.status)),
            if (session.mode != null) ...[
              const SizedBox(width: AppSpacing.three),
              ThemedText.small(session.mode!.name),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
