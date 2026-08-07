import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/time_ago.dart';
import 'package:tired_agent_app/widgets/common/geek_action_button.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';

/// 极简极客风格 Session 卡片 — 纯终端排版，所有操作以文字按钮展示（免长按）。
///
/// 布局采用"对齐网格"：提示符 `>`/`│` 与正文统一 12px monospace，垂直对齐；
/// cmd/pid/uptime 合并单行，减少右对齐点，排版更整洁。
class GeekSessionCard extends SessionCardContract {
  const GeekSessionCard();

  String _statusLabel(SessionStatus s) => switch (s) {
    SessionStatus.running => '+running',
    SessionStatus.starting => '~start',
    SessionStatus.exited => '!exited',
  };

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
    final statusColor = switch (session.status) {
      SessionStatus.running => c.success,
      SessionStatus.starting => c.warning,
      SessionStatus.exited => c.textSecondary,
    };

    // ── 合并信息行（cmd · pid/exit · uptime）────────────────────
    final cmd = [session.cmd, ...session.args].join(' ');
    final meta = session.status == SessionStatus.exited
        ? 'exit ${session.exitCode ?? '?'}'
        : 'pid ${session.pid ?? '?'}';
    final up = session.status == SessionStatus.exited
        ? (session.exitedAt != null ? 'ago ${timeAgo(session.exitedAt!)}' : '')
        : 'up ${timeAgo(session.createdAt)}';
    // 仅命令；pid/exit/up 全部交给左下角 Row3 状态行（避免 pid 重复）
    final cmdLine = cmd;

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.four,
          vertical: AppSpacing.two,
        ),
        decoration: BoxDecoration(
          // 卡片底部分割线 + label 浮在分割线上方（终端 tab 标题感）
          border: Border(bottom: BorderSide(color: c.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row0: [ LABEL ] + [process] + *pin（标签右贴 process/pin）─
            Row(
              children: [
                ThemedText.mono(
                  '[ ${session.label ?? session.cmd} ]',
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: AppSpacing.one),
                if (session.mode != null)
                  ThemedText.mono(
                    '[${session.mode!.name}]',
                    color: c.textSecondary,
                  ),
                const SizedBox(width: AppSpacing.one),
                if (data.isPinned) ThemedText.mono('*pin', color: c.primary),
              ],
            ),
            // ── Row1: /cwd（终端顶部 cwd，路径感）──────────────
            if (session.cwd != null && session.cwd!.isNotEmpty)
              ThemedText.mono(
                '─ ${session.cwd!}',
                color: c.primary.withAlpha(140),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // ── Row2: $ cmd（终端 prompt 主内容）─────────────
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: ThemedText.mono(
                '\$ $cmdLine',
                color: c.textSecondary,
                height: 1.5,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ── Row4: 左下角 status/pid/up，右下 actions ───────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ThemedText.mono(
                      session.status == SessionStatus.exited
                          ? '${_statusLabel(session.status)} · $meta${up.isEmpty ? '' : ' · $up'}'
                          : '${_statusLabel(session.status)} · pid ${session.pid ?? '?'} · $up',
                      color: statusColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (data.onPin != null ||
                    data.onKill != null ||
                    data.onDelete != null ||
                    canResume)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data.onPin != null)
                          GeekActionButton(
                            label: data.isPinned ? '*unpin' : '*pin',
                            onTap: data.onPin!,
                            color: c.primary,
                          ),
                        if (data.onPin != null &&
                            (data.onKill != null ||
                                data.onDelete != null ||
                                canResume))
                          const SizedBox(width: AppSpacing.two),
                        if (data.onKill != null &&
                            session.status != SessionStatus.exited)
                          GeekActionButton(
                            label: 'kill',
                            onTap: data.onKill!,
                            color: c.danger,
                          ),
                        if (canResume)
                          GeekActionButton(
                            label: 'resume',
                            onTap: data.onResume!,
                            color: c.success,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
