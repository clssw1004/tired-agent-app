import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Result returned when a session is selected in [ResumeSessionDialog].
class ResumeSelection {
  final String sessionId;
  final String? displayName;

  const ResumeSelection({required this.sessionId, this.displayName});
}

/// Neon-styled dialog that lists Claude historical sessions for a given
/// directory and lets the user pick one to resume.
///
/// Returns a [ResumeSelection] if the user picks a session, or `null` if
/// they cancel.
class ResumeSessionDialog {
  ResumeSessionDialog._();

  /// Show the dialog with a pre-loaded list of [sessions].
  ///
  /// [currentSessionId] is the currently selected session (if any) so the
  /// dialog can highlight it.
  static Future<ResumeSelection?> show({
    required BuildContext context,
    required List<ClaudeProjectSession> sessions,
    String? currentSessionId,
  }) {
    return showDialog<ResumeSelection>(
      context: context,
      builder: (ctx) => _ResumeDialogContent(
        sessions: sessions,
        currentSessionId: currentSessionId,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Dialog content
// ═══════════════════════════════════════════════════════════════════════════

class _ResumeDialogContent extends StatefulWidget {
  final List<ClaudeProjectSession> sessions;
  final String? currentSessionId;

  const _ResumeDialogContent({
    required this.sessions,
    this.currentSessionId,
  });

  @override
  State<_ResumeDialogContent> createState() => _ResumeDialogContentState();
}

class _ResumeDialogContentState extends State<_ResumeDialogContent> {
  String? _selectedId;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentSessionId;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(int ts) {
    final diff = DateTime.now().millisecondsSinceEpoch - ts;
    if (diff <= 0) return AppStrings.of.timeJustNow;
    if (diff < 60000) return '${diff ~/ 1000}${AppStrings.of.timeSecondsAgo}';
    if (diff < 3600000) return '${diff ~/ 60000}${AppStrings.of.timeMinutesAgo}';
    if (diff < 86400000) return '${diff ~/ 3600000}${AppStrings.of.timeHoursAgo}';
    if (diff < 604800000) return '${diff ~/ 86400000}${AppStrings.of.timeDaysAgo}';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.month)}/${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.primary.withAlpha(50), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: c.primary.withAlpha(15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.border.withAlpha(120), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: c.primary, size: 22),
                  const SizedBox(width: 10),
                  ThemedText.title('${AppStrings.of.claudeProjectsTitle} (${widget.sessions.length})'),
                ],
              ),
            ),

            // ── Session list ──────────────────────────────────────
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: widget.sessions.length,
                itemBuilder: (context, idx) {
                  final s = widget.sessions[idx];
                  final selected = s.sessionId == _selectedId;
                  final displayName = s.displayName ?? s.sessionId.substring(0, 8);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedId = s.sessionId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? c.primary.withAlpha(10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? c.primary.withAlpha(70)
                              : c.border.withAlpha(25),
                          width: selected ? 1 : 0.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: c.primary.withAlpha(12),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Radio indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? c.primary
                                    : c.textSecondary.withAlpha(80),
                                width: selected ? 2 : 1.5,
                              ),
                              color: selected
                                  ? c.primary.withAlpha(20)
                                  : Colors.transparent,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: c.primary.withAlpha(30),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: c.primary,
                                        boxShadow: [
                                          BoxShadow(
                                            color: c.primary.withAlpha(50),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          // Info
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
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 11,
                                      color: c.textSecondary.withAlpha(140),
                                    ),
                                    const SizedBox(width: 4),
                                    ThemedText.small(
                                      _formatTime(s.lastModified),
                                      color: c.textSecondary.withAlpha(180),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.storage,
                                      size: 11,
                                      color: c.textSecondary.withAlpha(100),
                                    ),
                                    const SizedBox(width: 4),
                                    ThemedText.small(
                                      _formatSize(s.size),
                                      color: c.textSecondary.withAlpha(120),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Check icon for selected
                          if (selected)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.check_circle,
                                size: 18,
                                color: c.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Action bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10,
                      ),
                    ),
                    child: ThemedText.small(AppStrings.of.cancel, color: c.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _selectedId != null
                        ? () {
                            final session = widget.sessions.firstWhere(
                              (s) => s.sessionId == _selectedId,
                            );
                            Navigator.of(context).pop(
                              ResumeSelection(
                                sessionId: session.sessionId,
                                displayName: session.displayName,
                              ),
                            );
                          }
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: c.primary,
                      disabledForegroundColor: c.textSecondary.withAlpha(80),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: c.primary.withAlpha(_selectedId != null ? 50 : 15),
                          width: 0.5,
                        ),
                      ),
                      backgroundColor: c.primary.withAlpha(8),
                    ),
                    child: ThemedText.small(
                      AppStrings.of.sessionResumeBtn,
                      color: _selectedId != null ? c.primary : c.textSecondary.withAlpha(80),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
