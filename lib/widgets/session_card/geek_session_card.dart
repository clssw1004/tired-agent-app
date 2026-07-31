import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/geek_action_button.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';

/// 极简极客风格 Session 卡片 — 纯终端排版，所有操作以文字按钮展示（免长按）。
///
/// 布局采用"对齐网格"：提示符 `>`/`│` 与正文统一 12px monospace，垂直对齐；
/// cmd/pid/uptime 合并单行，减少右对齐点，排版更整洁。
class GeekSessionCard extends SessionCardContract {
  const GeekSessionCard();

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

    // ── 合并信息行（cmd · pid/exit · uptime）────────────────────
    final cmd = [session.cmd, ...session.args].join(' ');
    final meta = session.status == SessionStatus.exited
        ? 'exit=${session.exitCode ?? '?'}'
        : 'pid=${session.pid ?? '?'}';
    final up = session.status == SessionStatus.exited
        ? (session.exitedAt != null ? 'ago=${_timeSince(session.exitedAt!)}' : '')
        : 'up=${_timeSince(session.createdAt)}';
    final cmdLine = up.isEmpty ? '│ $cmd · $meta' : '│ $cmd · $meta · $up';

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.two),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row1: > label + [mode] + *pin + status ───────────
            Row(
              children: [
                ThemedText('> ', fontSize: 12, fontFamily: 'monospace', color: c.primary),
                Expanded(
                  child: ThemedText(
                    session.label ?? session.cmd,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: c.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (session.mode != null) ...[
                  ThemedText('[${session.mode!.name}]', fontSize: 12, fontFamily: 'monospace', color: c.textSecondary),
                  const SizedBox(width: 8),
                ],
                if (data.isPinned) ...[
                  ThemedText('*pin', fontSize: 12, fontFamily: 'monospace', color: c.primary),
                  const SizedBox(width: 8),
                ],
                ThemedText(_statusLabel(session.status), fontSize: 12, fontFamily: 'monospace', color: statusColor),
              ],
            ),
            // ── Row2: cmd · pid/exit · uptime ────────────────────
            ThemedText(
              cmdLine,
              fontSize: 12, fontFamily: 'monospace', color: c.textSecondary, height: 1.5,
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            // ── Row3: cwd ────────────────────────────────────────
            if (session.cwd != null && session.cwd!.isNotEmpty)
              ThemedText('│ ${session.cwd!}', fontSize: 12, fontFamily: 'monospace', color: c.primary.withAlpha(140), maxLines: 1, overflow: TextOverflow.ellipsis),
            // ── Row4: Actions（可点击文字按钮，免长按）──────────
            if (data.onPin != null || data.onKill != null || data.onDelete != null || canResume)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (data.onPin != null)
                      GeekActionButton(label: data.isPinned ? '*unpin' : '*pin', onTap: data.onPin!, color: c.primary),
                    if (data.onKill != null && session.status != SessionStatus.exited)
                      GeekActionButton(label: 'kill', onTap: data.onKill!, color: c.danger),
                    if (session.status == SessionStatus.exited && data.onDelete != null)
                      GeekActionButton(label: 'delete', onTap: data.onDelete!, color: c.danger),
                    if (canResume)
                      GeekActionButton(label: 'resume', onTap: data.onResume!, color: c.success),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

