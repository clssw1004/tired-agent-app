import 'package:flutter/material.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/glow_badge.dart';
import 'package:tired_agent_app/widgets/neon_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback? onKill;
  final VoidCallback? onDelete;
  final VoidCallback? onResume;
  final bool isPinned;
  final VoidCallback? onPin;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onKill,
    this.onDelete,
    this.onResume,
    this.isPinned = false,
    this.onPin,
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
    final c = context.appColors;
    return NeonCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.four,
        vertical: AppSpacing.one,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + status badge + pin
          Row(
            children: [
              Expanded(child: ThemedText.mono(session.label ?? session.cmd)),
              if (onPin != null)
                GestureDetector(
                  onTap: onPin,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 16,
                      color: isPinned
                          ? c.primary
                          : c.textSecondary,
                    ),
                  ),
                ),
              GlowBadge(
                status: switch (session.status) {
                  SessionStatus.running => BadgeStatus.running,
                  SessionStatus.starting => BadgeStatus.starting,
                  SessionStatus.exited => BadgeStatus.exited,
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.one),
          // Subtitle: cmd args · pid/exit
          ThemedText.mono(
            () {
              final cmd = [session.cmd, ...session.args].join(' ');
              if (session.status == SessionStatus.exited) {
                final exitInfo = 'exit ${session.exitCode ?? '?'}';
                final ago = session.exitedAt != null
                    ? ' · ${_timeSince(session.exitedAt!)}'
                    : '';
                return '$cmd · $exitInfo$ago';
              }
              return '$cmd · pid ${session.pid ?? '?'}';
            }(),
            color: c.textSecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Working directory
          if (session.cwd != null && session.cwd!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_outlined, size: 12, color: c.primary.withAlpha(120)),
                const SizedBox(width: 4),
                Flexible(
                  child: ThemedText.mono(
                    session.cwd!,
                    color: c.primary.withAlpha(140),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          // Mode badge + action buttons
          if (session.mode != null) ...[
            const SizedBox(height: AppSpacing.two),
            Row(
              children: [
                _ModeBadge(mode: session.mode!),
                const Spacer(),
                if (onKill != null)
                  _ActionButton(
                    icon: '⏹',
                    label: AppStrings.of.sessionsKillBtn,
                    color: c.danger,
                    onTap: onKill!,
                  ),
                if (session.status == SessionStatus.exited && onDelete != null)
                  _ActionButton(
                    icon: '🗑',
                    label: AppStrings.of.sessionsDeleteBtn,
                    color: c.textSecondary,
                    onTap: onDelete!,
                  ),
                if (session.mode == SessionMode.persistent &&
                    session.status == SessionStatus.exited &&
                    session.claudeSessionId != null &&
                    onResume != null)
                  Tooltip(
                    message: AppStrings.of.sessionResumeTooltip,
                    child: _ActionButton(
                      icon: '▶',
                      label: AppStrings.of.sessionResumeBtn,
                      color: c.success,
                      onTap: onResume!,
                    ),
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
                      label: AppStrings.of.sessionsKillBtn,
                      color: c.danger,
                      onTap: onKill!,
                    ),
                  if (session.status == SessionStatus.exited &&
                      onDelete != null)
                    _ActionButton(
                      icon: '🗑',
                      label: AppStrings.of.sessionsDeleteBtn,
                      color: c.textSecondary,
                      onTap: onDelete!,
                    ),
                  if (session.mode == SessionMode.persistent &&
                      session.status == SessionStatus.exited &&
                      session.claudeSessionId != null &&
                      onResume != null)
                    Tooltip(
                      message: AppStrings.of.sessionResumeTooltip,
                      child: _ActionButton(
                        icon: '▶',
                        label: AppStrings.of.sessionResumeBtn,
                        color: c.success,
                        onTap: onResume!,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final SessionMode mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.two,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: c.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.one),
        border: Border.all(color: c.primary.withAlpha(50)),
      ),
      child: ThemedText.mono(mode.name, color: c.primary),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.one,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(70)),
          borderRadius: BorderRadius.circular(AppSpacing.one),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedText(icon, fontSize: 12),
            const SizedBox(width: 4),
            ThemedText.mono(label, color: color),
          ],
        ),
      ),
    );
  }
}
