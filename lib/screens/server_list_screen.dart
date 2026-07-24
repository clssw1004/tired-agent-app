import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/server_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class ServerListScreen extends StatelessWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => auth.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Active manager indicator ──────────────────────────────
          if (auth.profiles.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.four,
                vertical: AppSpacing.two,
              ),
              child: _ManagerSwitcher(auth: auth),
            ),

          Expanded(
            child: auth.agents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ThemedText.small(
                          auth.sessionToken != null
                              ? 'No agents connected'
                              : 'Not connected',
                          color: AppColors.textSecondary,
                        ),
                        if (auth.sessionToken == null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.two),
                            child: ThemedText.small(
                              'Go to Settings to add or switch a manager',
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: auth.agents.length,
                    itemBuilder: (context, index) {
                      final agent = auth.agents[index];
                      return ServerCard(
                        agent: agent,
                        onTap: () => context.push('/server/${agent.id}'),
                      );
                    },
                  ),
          ),
          if (auth.sessionToken != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.four),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/server/new'),
                    icon: const Icon(Icons.add, size: 20),
                    label: ThemedText.body('Add Server'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact manager switcher pill shown at the top of the server list.
class _ManagerSwitcher extends StatelessWidget {
  final AuthProvider auth;

  const _ManagerSwitcher({required this.auth});

  @override
  Widget build(BuildContext context) {
    final active = auth.profiles.where((p) => p.id == auth.activeProfileId).firstOrNull;
    return Material(
      color: AppColors.backgroundElement,
      borderRadius: BorderRadius.circular(AppSpacing.three),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.three),
        onTap: () => _showPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.three,
            vertical: AppSpacing.two,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: auth.status == AuthStatus.authenticated
                      ? AppColors.success
                      : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.two),
              Expanded(
                child: ThemedText.small(
                  active?.name ?? 'Select manager',
                  color: AppColors.text,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.one),
              const Icon(Icons.unfold_more, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.backgroundElement,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.four),
              child: ThemedText.title('Switch Manager'),
            ),
            ...auth.profiles.map((p) => ListTile(
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.id == auth.activeProfileId
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: ThemedText.body(p.name),
                  subtitle: ThemedText.small(p.baseUrl, color: AppColors.textSecondary),
                  trailing: p.id == auth.activeProfileId
                      ? const Icon(Icons.check, color: AppColors.accent)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(p.id),
                )),
            const SizedBox(height: AppSpacing.two),
          ],
        ),
      ),
    );

    if (result != null && result != auth.activeProfileId && context.mounted) {
      try {
        await auth.switchTo(result);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}
