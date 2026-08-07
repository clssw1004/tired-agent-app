import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/glow_badge.dart';
import 'package:tired_agent_app/widgets/common/neon_card.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';

/// 赛博朋克风格 Session 卡片：图标按钮 + 长按删除。
class NeonSessionCard extends SessionCardContract {
  const NeonSessionCard();

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s <= 0) return '0${AppStrings.of.timeSecondsAgo}';
    if (s < 60000) return '${s ~/ 1000}${AppStrings.of.timeSecondsAgo}';
    if (s < 3600000) return '${s ~/ 60000}${AppStrings.of.timeMinutesAgo}';
    if (s < 86400000) return '${s ~/ 3600000}${AppStrings.of.timeHoursAgo}';
    return '${s ~/ 86400000}${AppStrings.of.timeDaysAgo}';
  }

  @override
  Widget build(BuildContext context, SessionCardData data) {
    final session = data.session;
    final c = context.appColors;
    final canResume =
        session.status == SessionStatus.exited &&
        data.onResume != null &&
        session.cmd == 'claude' &&
        (session.extra?['claudeSessionId'] != null ||
            session.extra?['claudeName'] != null ||
            session.label != null);
    return NeonCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.four,
        vertical: AppSpacing.one,
      ),
      onTap: data.onTap,
      onLongPress: data.onDelete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + status badge + pin
          Row(
            children: [
              Expanded(child: ThemedText.mono(session.label ?? session.cmd)),
              if (data.onPin != null)
                GestureDetector(
                  onTap: data.onPin,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      data.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 16,
                      color: data.isPinned ? c.primary : c.textSecondary,
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
          // Working directory（第一行）
          if (session.cwd != null && session.cwd!.isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 12,
                  color: c.primary.withAlpha(120),
                ),
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
          // Subtitle: cmd args · pid/exit · uptime
          ThemedText.mono(
            () {
              final cmd = [session.cmd, ...session.args].join(' ');
              final uptime = session.status == SessionStatus.exited
                  ? session.exitedAt != null
                        ? _timeSince(session.exitedAt!)
                        : ''
                  : 'up ${_timeSince(session.createdAt)}';
              if (session.status == SessionStatus.exited) {
                final exitInfo = 'exit ${session.exitCode ?? '?'}';
                return '$cmd · $exitInfo · $uptime';
              }
              return '$cmd · pid ${session.pid ?? '?'} · $uptime';
            }(),
            color: c.textSecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Mode badge + action buttons
          if (session.mode != null) ...[
            const SizedBox(height: AppSpacing.two),
            Row(
              children: [
                _ModeBadge(mode: session.mode!),
                const Spacer(),
                if (data.onKill != null)
                  _ActionButton(
                    icon: '⏹',
                    label: AppStrings.of.sessionsKillBtn,
                    color: c.danger,
                    onTap: data.onKill!,
                  ),
                if (data.onKill != null && (data.onDelete != null || canResume))
                  const SizedBox(width: 6),
                if (session.status == SessionStatus.exited &&
                    data.onDelete != null)
                  _ActionButton(
                    icon: '🗑',
                    label: AppStrings.of.sessionsDeleteBtn,
                    color: c.textSecondary,
                    onTap: data.onDelete!,
                  ),
                if (session.status == SessionStatus.exited &&
                    data.onDelete != null &&
                    canResume)
                  const SizedBox(width: 6),
                if (canResume)
                  Tooltip(
                    message: AppStrings.of.sessionResumeTooltip,
                    child: _ActionButton(
                      icon: '▶',
                      label: AppStrings.of.sessionResumeBtn,
                      color: c.success,
                      onTap: data.onResume!,
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
                  if (session.status != SessionStatus.exited &&
                      data.onKill != null)
                    _ActionButton(
                      icon: '⏹',
                      label: AppStrings.of.sessionsKillBtn,
                      color: c.danger,
                      onTap: data.onKill!,
                    ),
                  if (data.onKill != null &&
                      (data.onDelete != null || canResume) &&
                      session.status != SessionStatus.exited)
                    const SizedBox(width: 6),
                  if (session.status == SessionStatus.exited &&
                      data.onDelete != null)
                    _ActionButton(
                      icon: '🗑',
                      label: AppStrings.of.sessionsDeleteBtn,
                      color: c.textSecondary,
                      onTap: data.onDelete!,
                    ),
                  if (session.status == SessionStatus.exited &&
                      data.onDelete != null &&
                      canResume)
                    const SizedBox(width: 6),
                  if (canResume)
                    Tooltip(
                      message: AppStrings.of.sessionResumeTooltip,
                      child: _ActionButton(
                        icon: '▶',
                        label: AppStrings.of.sessionResumeBtn,
                        color: c.success,
                        onTap: data.onResume!,
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
