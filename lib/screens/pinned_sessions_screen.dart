import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Shows all pinned sessions grouped by manager.
///
/// Pin UI will be added in a later phase — for now this is a placeholder
/// that guides users to pin sessions from the agent session list.
class PinnedSessionsScreen extends StatelessWidget {
  const PinnedSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('Sessions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
      ),
      body: Center(
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
              ThemedText.title(
                auth.connections.isEmpty
                    ? 'No managers connected'
                    : 'No pinned sessions',
              ),
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
      ),
    );
  }
}
