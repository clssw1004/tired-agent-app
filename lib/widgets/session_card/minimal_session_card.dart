import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';

/// 极简极客风格 Session 卡片 — 纯终端排版，所有操作以文字按钮展示（免长按）。
class MinimalSessionCard extends SessionCardContract {
  const MinimalSessionCard();

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
  Widget build(BuildContext context, SessionCardData data) {
    final session = data.session;
    final c = context.appColors;
    final canResume = session.status == SessionStatus.exited &&
        data.onResume != null &&
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
      onTap: data.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.two),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border.withAlpha(40), width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label (left) + status (right) ────────────────────
            Row(
              children: [
                ThemedText('> ', fontSize: 12, fontFamily: 'monospace', color: c.primary),
                Expanded(
                  child: ThemedText.mono(session.label ?? session.cmd, color: c.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (session.mode != null) ...[
                  ThemedText('[${session.mode!.name}]', fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
                  const SizedBox(width: 6),
                ],
                if (data.isPinned)
                  ThemedText('*pin ', fontSize: 11, fontFamily: 'monospace', color: c.primary),
                ThemedText(_statusLabel(session.status), fontSize: 11, fontFamily: 'monospace', color: statusColor),
              ],
            ),
            // ── cmd (left) + uptime (right) ──────────────────────
            Row(
              children: [
                Expanded(
                  child: ThemedText(
                    '│ ${() {
                      final cmd = [session.cmd, ...session.args].join(' ');
                      if (session.status == SessionStatus.exited) {
                        return '$cmd  exit=${session.exitCode ?? '?'}';
                      }
                      return '$cmd  pid=${session.pid ?? '?'}';
                    }()}',
                    fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                ThemedText(
                  session.status == SessionStatus.exited
                      ? session.exitedAt != null ? 'ago=${_timeSince(session.exitedAt!)}' : ''
                      : 'up=${_timeSince(session.createdAt)}',
                  fontSize: 11, fontFamily: 'monospace', color: c.textSecondary),
              ],
            ),
            if (session.cwd != null && session.cwd!.isNotEmpty)
              ThemedText('│ ${session.cwd!}', fontSize: 11, fontFamily: 'monospace', color: c.primary.withAlpha(140), maxLines: 1, overflow: TextOverflow.ellipsis),
            // ── Actions: 可点击文字按钮（免长按）───────────────
            if (data.onPin != null || data.onKill != null || data.onDelete != null || canResume)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (data.onPin != null)
                      _TermBtn(data.isPinned ? '*unpin' : '*pin', onTap: data.onPin!, color: c.primary),
                    if (data.onKill != null && session.status != SessionStatus.exited)
                      _TermBtn('kill', onTap: data.onKill!, color: c.danger),
                    if (session.status == SessionStatus.exited && data.onDelete != null)
                      _TermBtn('delete', onTap: data.onDelete!, color: c.danger),
                    if (canResume)
                      _TermBtn('resume', onTap: data.onResume!, color: c.success),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 终端风格的可点击文字按钮。
class _TermBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _TermBtn(this.label, {required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ThemedText(label, fontSize: 11, fontFamily: 'monospace', color: color),
      ),
    );
  }
}
