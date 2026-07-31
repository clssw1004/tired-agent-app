import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Geek-mode 纯终端风格卡片 — 填满宽度。
class GeekSessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback? onKill;
  final VoidCallback? onDelete;
  final VoidCallback? onResume;
  final bool isPinned;
  final VoidCallback? onPin;

  const GeekSessionCard({
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
    if (s <= 0) return '0s';
    if (s < 60000) return '${s ~/ 1000}s';
    if (s < 3600000) return '${s ~/ 60000}m';
    if (s < 86400000) return '${s ~/ 3600000}h';
    return '${s ~/ 86400000}d';
  }

  String _statusLabel(SessionStatus s) => switch (s) {
    SessionStatus.running => '+running',
    SessionStatus.starting => '~start',
    SessionStatus.exited => '!exited',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final canResume = session.status == SessionStatus.exited &&
        onResume != null &&
        session.cmd == 'claude' &&
        (session.extra?['claudeSessionId'] != null ||
         session.extra?['claudeName'] != null ||
         session.label != null);
    final statusColor = switch (session.status) {
      SessionStatus.running => c.success,
      SessionStatus.starting => c.warning,
      SessionStatus.exited => c.textSecondary,
    };

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.two),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border.withAlpha(40), width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ThemedText('> ', fontSize: 12, fontFamily: 'monospace', color: c.primary),
                Expanded(
                  child: ThemedText.mono(session.label ?? session.cmd, color: c.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (session.mode != null) ...[
                  const SizedBox(width: 4),
                  ThemedText('[${session.mode!.name}]', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
                ],
                const SizedBox(width: 4),
                ThemedText(_statusLabel(session.status), fontSize: 11, fontFamily: 'monospace', color: statusColor),
                if (isPinned)
                  ThemedText(' *pin', fontSize: 11, fontFamily: 'monospace', color: c.primary),
              ],
            ),
            ThemedText(
              '│ ${() {
                final cmd = [session.cmd, ...session.args].join(' ');
                final uptime = session.status == SessionStatus.exited
                    ? session.exitedAt != null ? 'ago=${_timeSince(session.exitedAt!)}' : ''
                    : 'up=${_timeSince(session.createdAt)}';
                if (session.status == SessionStatus.exited) {
                  final exitInfo = 'exit=${session.exitCode ?? '?'}';
                  return '$cmd  $exitInfo  $uptime';
                }
                return '$cmd  pid=${session.pid ?? '?'}  $uptime';
              }()}',
              fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (session.cwd != null && session.cwd!.isNotEmpty)
              ThemedText('│ ${session.cwd!}', fontSize: 11, fontFamily: 'monospace', color: c.primary.withAlpha(140), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (onKill != null || onDelete != null || canResume || onPin != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ThemedText(
                  '│ ${[
                    if (onPin != null) isPinned ? '*unpin' : '*pin',
                    if (onKill != null && session.status != SessionStatus.exited) 'kill',
                    if (session.status == SessionStatus.exited && onDelete != null) 'delete',
                    if (canResume) 'resume',
                  ].join('  ')}',
                  fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
