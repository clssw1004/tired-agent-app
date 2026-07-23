import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback? onKill;
  final VoidCallback? onDelete;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onKill,
    this.onDelete,
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

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}s ago';
    if (s < 3600000) return '${s ~/ 60000}m ago';
    if (s < 86400000) return '${s ~/ 3600000}h ago';
    return '${s ~/ 86400000}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundElement,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.one),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.two),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.three),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: label + status badge
              Row(
                children: [
                  Expanded(
                    child: ThemedText.body(session.label ?? session.cmd),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(session.status).withAlpha(30),
                      borderRadius: BorderRadius.circular(AppSpacing.one),
                    ),
                    child: ThemedText.small(_statusLabel(session.status),
                        color: _statusColor(session.status)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.one),
              // Subtitle: cmd args · pid/exit
              ThemedText.small(
                () {
                  final cmd = [session.cmd, ...session.args].join(' ');
                  if (session.status == SessionStatus.exited) {
                    final exitInfo = 'exit ${session.exitCode ?? '?'}';
                    final ago = session.exitedAt != null ? ' · ${_timeSince(session.exitedAt!)}' : '';
                    return '$cmd · $exitInfo$ago';
                  }
                  return '$cmd · pid ${session.pid ?? '?'}';
                }(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Mode badge if present
              if (session.mode != null) ...[
                const SizedBox(height: AppSpacing.two),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppSpacing.one),
                        border: Border.all(color: AppColors.accent.withAlpha(60)),
                      ),
                      child: ThemedText.code(session.mode!.name, color: AppColors.accentLight),
                    ),
                    const Spacer(),
                    if (session.mode == SessionMode.persistent && onKill != null)
                      _ActionButton(
                        icon: '⏹',
                        label: 'Kill',
                        color: AppColors.danger,
                        onTap: onKill!,
                      ),
                    if (session.status == SessionStatus.exited && onDelete != null)
                      _ActionButton(
                        icon: '🗑',
                        label: 'Delete',
                        color: AppColors.textSecondary,
                        onTap: onDelete!,
                      ),
                  ],
                ),
              ],
              if (session.mode == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.two),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (session.status != SessionStatus.exited && onKill != null)
                        _ActionButton(
                          icon: '⏹',
                          label: 'Kill',
                          color: AppColors.danger,
                          onTap: onKill!,
                        ),
                      if (session.status == SessionStatus.exited && onDelete != null)
                        _ActionButton(
                          icon: '🗑',
                          label: 'Delete',
                          color: AppColors.textSecondary,
                          onTap: onDelete!,
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
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: AppSpacing.one),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(80)),
          borderRadius: BorderRadius.circular(AppSpacing.one),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedText(icon, fontSize: 12),
            const SizedBox(width: 4),
            ThemedText.small(label, color: color),
          ],
        ),
      ),
    );
  }
}
