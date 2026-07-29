import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';
import 'package:tired_agent_app/services/session_api_service.dart';

/// Callback when a session is selected in the picker.
/// [sessionId] — the UUID of the selected session.
/// [displayName] — optional human-readable name from the jsonl tail.
typedef SessionSelectedCallback = void Function(String sessionId, String? displayName);

/// Embedded widget shown after directory selection for claude sessions.
/// Scans ~/.claude/projects/ via backend and displays session list.
class ClaudeProjectsPicker extends StatefulWidget {
  final String cwd;
  final String profileId;
  final String agentId;
  final SessionSelectedCallback onSelected;

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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ClaudeProjectsPicker old) {
    super.didUpdateWidget(old);
    if (old.cwd != widget.cwd) {
      _selectedSessionId = null;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) return;
      final api = SessionApiService(conn: conn, agentId: widget.agentId);
      final info = await api.getClaudeProjects(path: widget.cwd);
      if (mounted) setState(() { _info = info; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    String pad(int n) => n.toString().padLeft(2, '0');
    final time = '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
    if (sameDay) return time;
    return '${pad(dt.month)}/${pad(dt.day)} $time';
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
    if (sessions.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.border.withAlpha(40)),
        ),
        child: ThemedText.small(
          AppStrings.of.claudeProjectsNoSessions,
          color: c.textSecondary,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: ThemedText.mono(
              '${AppStrings.of.claudeProjectsTitle} (${sessions.length})',
              color: c.primary,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (context, idx) {
                final s = sessions[idx];
                final selected = s.sessionId == _selectedSessionId;
                final displayName = s.displayName ?? s.sessionId.substring(0, 8);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSessionId = selected ? null : s.sessionId;
                    });
                    if (!selected) widget.onSelected(s.sessionId, s.displayName);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? c.primary.withAlpha(12)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: c.border.withAlpha(selected ? 50 : 20),
                          width: selected ? 1 : 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? c.primary : c.textSecondary.withAlpha(80),
                              width: selected ? 2 : 1.5,
                            ),
                            color: selected ? c.primary.withAlpha(20) : Colors.transparent,
                          ),
                          child: selected
                              ? Icon(Icons.check, size: 12, color: c.primary)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ThemedText.mono(
                                displayName,
                                color: selected ? c.primary : c.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  ThemedText.small(
                                    _formatTime(s.lastModified),
                                    color: c.textSecondary.withAlpha(180),
                                  ),
                                  const SizedBox(width: 8),
                                  ThemedText.small(
                                    _formatSize(s.size),
                                    color: c.textSecondary.withAlpha(120),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
