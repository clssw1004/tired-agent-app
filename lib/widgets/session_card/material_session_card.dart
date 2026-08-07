import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';

/// Material Design 3 风格 Session 卡片 — 原生 M3 组件（Card/InkWell/FilledButton），
/// 删除交互为滑动删除（Dismissible endToStart）。
///
/// 布局紧凑：Card margin 收紧、cmd/meta/cwd 三行分摊，操作按钮 compact，卡片更宽更扁。
class MD3SessionCard extends SessionCardContract {
  const MD3SessionCard();

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s <= 0) return '0s';
    if (s < 60000) return '${s ~/ 1000}s';
    if (s < 3600000) return '${s ~/ 60000}m';
    if (s < 86400000) return '${s ~/ 3600000}h';
    return '${s ~/ 86400000}d';
  }

  @override
  Widget build(BuildContext context, SessionCardData data) {
    final session = data.session;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final canResume =
        session.status == SessionStatus.exited &&
        data.onResume != null &&
        session.cmd == 'claude' &&
        (session.extra?['claudeSessionId'] != null ||
            session.extra?['claudeName'] != null ||
            session.label != null);

    // ── 合并信息行（cmd · pid/exit · up · /cwd）────────────────
    final cmd = [session.cmd, ...session.args].join(' ');
    final meta = session.status == SessionStatus.exited
        ? 'exit ${session.exitCode ?? '?'}'
        : 'pid ${session.pid ?? '?'}';
    final up = session.status == SessionStatus.exited
        ? (session.exitedAt != null
              ? 'ago ${_timeSince(session.exitedAt!)}'
              : '')
        : 'up ${_timeSince(session.createdAt)}';
    // 三行独立：cmd / pid/exit · up / /cwd
    final cwd = session.cwd != null && session.cwd!.isNotEmpty
        ? session.cwd!
        : '';
    final metaLine = session.status == SessionStatus.exited
        ? (up.isEmpty ? meta : '$meta · $up')
        : '$meta · $up';

    final card = Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label + pin + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.label ?? session.cmd,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (data.onPin != null)
                    IconButton(
                      onPressed: data.onPin,
                      icon: Icon(
                        data.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        size: 18,
                        color: data.isPinned
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _StatusChip(status: session.status, scheme: scheme),
                ],
              ),
              const SizedBox(height: 4),
              // /cwd（第一行紧接标签）
              if (cwd.isNotEmpty)
                Text(
                  cwd,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // cmd（主行）
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  cmd,
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // pid/exit · up（次行）
              Text(
                metaLine,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Actions: kill / resume（compact 按钮）
              if ((data.onKill != null &&
                      session.status != SessionStatus.exited) ||
                  canResume)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (data.onKill != null &&
                          session.status != SessionStatus.exited)
                        TextButton.icon(
                          onPressed: data.onKill,
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('kill'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                      if (canResume)
                        FilledButton.tonalIcon(
                          onPressed: data.onResume,
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('resume'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey(session.id),
      // 仅 exited（有 onDelete）时可滑动删除
      direction: data.onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      // 滑动触发页面删除（弹确认框 + 接口 + 刷新），返回 false 让 item 由页面刷新管理，
      // 避免 Dismissible 自移除与异步列表刷新冲突。
      confirmDismiss: (_) async {
        if (data.onDelete == null) return false;
        data.onDelete!();
        return false;
      },
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: card,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SessionStatus status;
  final ColorScheme scheme;

  const _StatusChip({required this.status, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SessionStatus.running => ('running', scheme.primary),
      SessionStatus.starting => ('starting', scheme.tertiary),
      SessionStatus.exited => ('exited', scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
