import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Geek-mode text-only card for a session.
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.four,
        vertical: AppSpacing.one,
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: c.border.withAlpha(60), width: 0.5),
          ),
          padding: const EdgeInsets.all(AppSpacing.two),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: label [mode] [status] pin ─────────────
              Row(
                children: [
                  ThemedText.mono(session.label ?? session.cmd, color: c.text, maxLines: 1, overflow: TextOverflow.ellipsis),
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
              const SizedBox(height: 2),
              // ── Subtitle: cmd args ─────────────────────────────
              ThemedText(
                () {
                  final cmd = [session.cmd, ...session.args].join(' ');
                  if (session.status == SessionStatus.exited) {
                    final exitInfo = 'exit ${session.exitCode ?? '?'}';
                    final ago = session.exitedAt != null ? ' ${_timeSince(session.exitedAt!)}' : '';
                    return '$cmd  $exitInfo$ago';
                  }
                  return '$cmd  pid ${session.pid ?? '?'}';
                }(),
                fontSize: 11, fontFamily: 'monospace', color: c.textSecondary, maxLines: 2, overflow: TextOverflow.ellipsis),
              // ── CWD ────────────────────────────────────────────
              if (session.cwd != null && session.cwd!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ThemedText(session.cwd!, fontSize: 11, fontFamily: 'monospace', color: c.primary.withAlpha(140), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              // ── Action buttons row ─────────────────────────────
              if (onKill != null || onDelete != null || canResume || onPin != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.one),
                  child: Wrap(
                    spacing: AppSpacing.one,
                    children: [
                      if (onPin != null)
                        _GeekAction(label: isPinned ? '*unpin' : '*pin', color: c.primary, onTap: onPin!),
                      if (onKill != null && session.status != SessionStatus.exited)
                        _GeekAction(label: 'kill', color: c.danger, onTap: onKill!),
                      if (session.status == SessionStatus.exited && onDelete != null)
                        _GeekAction(label: 'delete', color: c.textSecondary, onTap: onDelete!),
                      if (canResume)
                        _GeekAction(label: 'resume', color: c.success, onTap: onResume!),
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

class _GeekAction extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GeekAction({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(70), width: 0.5),
          borderRadius: BorderRadius.circular(1),
        ),
        child: ThemedText(label, fontSize: 11, fontFamily: 'monospace', color: color),
      ),
    );
  }
}
