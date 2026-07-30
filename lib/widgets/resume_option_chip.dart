import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/services/session_api_service.dart';
import 'package:tired_agent_app/widgets/resume_session_dialog.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// A self-contained inline chip that loads Claude historical sessions for
/// the given [cwd] and opens a [ResumeSessionDialog] on tap.
///
/// Reports selection changes via [onChanged] — null means cleared.
/// Renders [SizedBox.shrink] when [enabled] is false or no sessions exist,
/// making it suitable for direct use in a [Wrap] alongside option chips.
class ResumeOptionChip extends StatefulWidget {
  final String profileId;
  final String agentId;
  final String? cwd;
  final bool enabled;
  final ResumeSelection? selection;
  final ValueChanged<ResumeSelection?> onChanged;

  const ResumeOptionChip({
    super.key,
    required this.profileId,
    required this.agentId,
    this.cwd,
    this.enabled = true,
    this.selection,
    required this.onChanged,
  });

  @override
  State<ResumeOptionChip> createState() => _ResumeOptionChipState();
}

class _ResumeOptionChipState extends State<ResumeOptionChip> {
  List<ClaudeProjectSession> _sessions = [];
  bool _loaded = false;

  @override
  void didUpdateWidget(ResumeOptionChip old) {
    super.didUpdateWidget(old);
    if (old.cwd != widget.cwd || old.enabled != widget.enabled) {
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.enabled || widget.cwd == null) {
      setState(() {
        _sessions = [];
        _loaded = true;
      });
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) return;
      final api = SessionApiService(conn: conn, agentId: widget.agentId);
      final info = await api.getClaudeProjects(path: widget.cwd!);
      if (mounted) {
        setState(() {
          _sessions = info.sessions;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sessions = [];
          _loaded = true;
        });
      }
    }
  }

  bool get _canResume => widget.enabled && _loaded && _sessions.isNotEmpty;

  Future<void> _onTap() async {
    if (widget.selection != null) {
      widget.onChanged(null);
      return;
    }
    final result = await ResumeSessionDialog.show(
      context: context,
      sessions: _sessions,
      currentSessionId: widget.selection?.sessionId,
    );
    if (result != null && mounted) {
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canResume) return const SizedBox.shrink();

    final c = context.appColors;
    final active = widget.selection != null;
    final displayName = widget.selection?.displayName;
    final label = active && displayName != null
        ? '--resume: $displayName'
        : '--resume';

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.one,
        ),
        decoration: BoxDecoration(
          color: active ? c.primary.withAlpha(8) : c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.three),
          border: Border.all(
            color: active ? c.primary.withAlpha(100) : c.border.withAlpha(40),
            width: active ? 1 : 0.5,
          ),
          boxShadow: active
              ? [BoxShadow(color: c.primary.withAlpha(15), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 13,
              color: active ? c.primary : c.textSecondary,
            ),
            const SizedBox(width: 4),
            ThemedText.mono(label, color: active ? c.primary : c.textSecondary),
            if (active) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 14, color: c.primary),
            ],
            if (!active)
              Icon(Icons.arrow_drop_down, size: 14, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
