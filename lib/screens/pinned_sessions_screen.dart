import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/pinned_session.dart';
import 'package:tired_agent_app/providers/pinned_session_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Shows all pinned sessions grouped by manager.
class PinnedSessionsScreen extends StatelessWidget {
  const PinnedSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pinService = context.watch<PinnedSessionProvider>();
    final all = pinService.getAll();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('Sessions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
      ),
      body: all.isEmpty ? _buildEmpty(context) : _buildList(context, pinService, all),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.push_pin_outlined,
              size: 64,
              color: AppColors.primary.withAlpha(120),
            ),
            const SizedBox(height: AppSpacing.four),
            ThemedText.title('No pinned sessions'),
            const SizedBox(height: AppSpacing.two),
            ThemedText(
              '在 Agent 的会话列表里点击 📌\n将常用会话固定到此处',
              color: AppColors.textSecondary,
              fontSize: 12,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    PinnedSessionProvider pinService,
    List<PinnedSession> all,
  ) {
    final grouped = pinService.getGroupedByProfile();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.four,
        AppSpacing.two,
        AppSpacing.four,
        AppSpacing.four,
      ),
      children: grouped.entries.map((entry) {
        final profileName = entry.key;
        final sessions = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.two,
              ),
              child: ThemedText.title(
                profileName,
                color: AppColors.primary,
              ),
            ),
            // Session cards
            ...sessions.map((pinned) => _PinnedSessionCard(
                  pinned: pinned,
                  onTap: () => context.push(
                    '/session/${pinned.profileId}/${pinned.agentId}/${pinned.sessionId}',
                  ),
                  onUnpin: () => _unpin(context, pinService, pinned),
                )),
            const SizedBox(height: AppSpacing.two),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _unpin(
    BuildContext context,
    PinnedSessionProvider pinService,
    PinnedSession pinned,
  ) async {
    final ok = await NeonDialog.showConfirm(
      context: context,
      title: 'Unpin session?',
      showRobot: true,
      content: ThemedText.small(
        'Remove "${pinned.sessionLabel}" from pinned sessions?',
      ),
      confirmText: 'Unpin',
    );
    if (ok == true) {
      await pinService.unpin(pinned.id);
    }
  }
}

/// A single pinned session card.
class _PinnedSessionCard extends StatelessWidget {
  final PinnedSession pinned;
  final VoidCallback onTap;
  final VoidCallback onUnpin;

  const _PinnedSessionCard({
    required this.pinned,
    required this.onTap,
    required this.onUnpin,
  });

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}s ago';
    if (s < 3600000) return '${s ~/ 60000}m ago';
    if (s < 86400000) return '${s ~/ 3600000}h ago';
    return '${s ~/ 86400000}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.two),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onUnpin,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.two),
            border: Border.all(
              color: AppColors.primary.withAlpha(40),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.three),
            child: Row(
              children: [
                // Pin icon
                Icon(
                  Icons.push_pin,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.two),
                // Label + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThemedText.body(
                        pinned.sessionLabel,
                        color: AppColors.text,
                      ),
                      const SizedBox(height: 2),
                      ThemedText(
                        '${pinned.agentName} · ${pinned.sessionType.toUpperCase()} · pinned ${_timeSince(pinned.pinnedAtMs)}',
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
