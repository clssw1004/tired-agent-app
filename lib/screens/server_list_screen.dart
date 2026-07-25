import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/add_manager_form.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
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
        title: ThemedText.title('Agents'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
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
                ? _buildEmptyState(context, auth)
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
                    label: const Text('Add Agent'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AuthProvider auth) {
    // First launch — no profiles at all → welcome guide
    if (auth.profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.smart_toy,
                size: 80,
                color: AppColors.primary.withAlpha(180),
              ),
              const SizedBox(height: AppSpacing.four),
              ThemedText.title(
                'Welcome to tiredAgent',
                color: AppColors.text,
              ),
              const SizedBox(height: AppSpacing.two),
              ThemedText(
                '添加一个 Manager 服务器来管理你的\n代理服务器和会话',
                color: AppColors.textSecondary,
                fontSize: 12,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.six),
              ElevatedButton.icon(
                onPressed: () => _showAddManager(context, auth),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Manager'),
              ),
            ],
          ),
        ),
      );
    }

    // Has profiles but not connected → hint text
    return Center(
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
                'Select a manager above or go to Settings to add one',
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddManager(BuildContext context, AuthProvider auth) async {
    final formKey = GlobalKey<AddManagerFormState>();

    final formData = await NeonDialog.show<AddManagerFormData?>(
      context: context,
      title: 'Add Manager',
      maxWidth: 480,
      content: AddManagerForm(
        key: formKey,
        initialName: 'Manager ${auth.profiles.length + 1}',
      ),
      actions: [
        NeonDialogAction(
          label: 'Cancel',
          onPressed: (ctx) => Navigator.of(ctx).pop(null),
        ),
        NeonDialogAction(
          label: 'Connect',
          isPrimary: true,
          onPressed: (ctx) {
            final data = formKey.currentState?.data;
            if (data != null) Navigator.of(ctx).pop(data);
          },
        ),
      ],
    );

    if (formData != null && context.mounted) {
      if (formData.url.isEmpty || formData.token.isEmpty) return;

      try {
        await auth.login(
          formData.url,
          formData.token,
          name: formData.name.isNotEmpty ? formData.name : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ThemedText.small('Manager added'),
              backgroundColor: AppColors.backgroundElement,
            ),
          );
        }
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

/// Compact manager switcher pill shown at the top of the server list.
class _ManagerSwitcher extends StatelessWidget {
  final AuthProvider auth;

  const _ManagerSwitcher({required this.auth});

  @override
  Widget build(BuildContext context) {
    final active = auth.profiles
        .where((p) => p.id == auth.activeProfileId)
        .firstOrNull;
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
              const Icon(
                Icons.unfold_more,
                size: 16,
                color: AppColors.textSecondary,
              ),
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
            ...auth.profiles.map(
              (p) => ListTile(
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: p.id == auth.activeProfileId
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                title: ThemedText.body(p.name),
                subtitle: ThemedText.small(
                  p.baseUrl,
                  color: AppColors.textSecondary,
                ),
                trailing: p.id == auth.activeProfileId
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(p.id),
              ),
            ),
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
