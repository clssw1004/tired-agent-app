import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Embedded widget shown after directory selection for claude sessions.
/// Scans ~/.claude/projects/ via backend and displays session list.
class ClaudeProjectsPicker extends StatefulWidget {
  final String cwd;
  final String profileId;
  final String agentId;
  final ValueChanged<String> onSelected;

  const ClaudeProjectsPicker({
    super.key,
    required this.cwd,
    required this.profileId,
    required this.agentId,
    required this.onSelected,
  });

  @override
  State<ClaudeProjectsPicker> createState() => _ClaudeProjectsPickerState();
}

class _ClaudeProjectsPickerState extends State<ClaudeProjectsPicker> {
  ClaudeProjectInfo? _info;
  bool _loading = true;
  String? _error;
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) return;
      await conn.ensureFreshSession();
      final mgrRef = ServerRef(
        id: '__manager__',
        name: conn.profile.name,
        baseUrl: conn.profile.baseUrl,
        token: conn.profile.sessionToken!,
      );
      final info = await conn.transport.getClaudeProjects(
        mgrRef,
        path: widget.cwd,
        agentId: widget.agentId,
      );
      if (mounted) setState(() { _info = info; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return AppStrings.of.timeJustNow;
    if (s < 3600000) return '${s ~/ 60000}${AppStrings.of.timeMinutesAgo}';
    if (s < 86400000) return '${s ~/ 3600000}${AppStrings.of.timeHoursAgo}';
    return '${s ~/ 86400000}${AppStrings.of.timeDaysAgo}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            ThemedText.small(AppStrings.of.claudeProjectsLoading),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.danger.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ThemedText.small(_error!, color: c.danger),
      );
    }

    final sessions = _info?.sessions ?? [];
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ThemedText.mono(
              '${AppStrings.of.claudeProjectsTitle} (${sessions.length})',
              color: c.primary,
            ),
          ),
          ...sessions.map((s) {
            final selected = s.sessionId == _selectedSessionId;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSessionId =
                      selected ? null : s.sessionId;
                });
                if (!selected) widget.onSelected(s.sessionId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? c.primary.withAlpha(12)
                      : Colors.transparent,
                  border: Border(
                    top: BorderSide(color: c.border.withAlpha(30)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 16,
                      color: selected
                          ? c.primary
                          : c.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ThemedText.code(
                        s.sessionId.substring(0, 8),
                        color: c.textCode,
                      ),
                    ),
                    ThemedText.small(
                      _timeSince(s.lastModified),
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    ThemedText.small(
                      _formatSize(s.size),
                      color: c.textSecondary.withAlpha(150),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
