import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          // ── Managers ────────────────────────────────────────────────
          _SectionHeader(label: 'Managers (${auth.profiles.length})'),
          const SizedBox(height: AppSpacing.two),

          if (auth.profiles.isEmpty)
            ThemedText.small('No managers saved', color: AppColors.textSecondary)
          else
            ...auth.profiles.map((profile) => _ManagerCard(
                  profile: profile,
                  isActive: profile.id == auth.activeProfileId,
                  isConnected: profile.id == auth.activeProfileId &&
                      auth.status == AuthStatus.authenticated,
                  onSwitch: () => _switchTo(context, auth, profile.id),
                  onDelete: () => _deleteManager(context, auth, profile),
                )),

          const SizedBox(height: AppSpacing.one),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addManager(context, auth),
              icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
              label: ThemedText.body('Add Manager', color: AppColors.accent),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accent.withAlpha(60)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.three),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.four),

          // ── Active connection ──────────────────────────────────────
          _SectionHeader(label: 'Active Connection'),
          const SizedBox(height: AppSpacing.two),
          _InfoTile(label: 'Manager', value: _activeName(auth)),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: 'Base URL', value: auth.baseUrl ?? '—'),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(
            label: 'Status',
            value: auth.status == AuthStatus.authenticated ? 'Connected' : 'Disconnected',
            valueColor: auth.status == AuthStatus.authenticated
                ? AppColors.success
                : AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: 'Agents', value: '${auth.agents.length}'),
          const SizedBox(height: AppSpacing.four),

          // ── About ──────────────────────────────────────────────────
          _SectionHeader(label: 'About'),
          const SizedBox(height: AppSpacing.two),
          _InfoTile(label: 'App', value: 'tiredAgentMobile'),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: 'Version', value: '1.0.0'),
          const SizedBox(height: AppSpacing.six),

          // ── Logout ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, auth),
              icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
              label: ThemedText.body('Logout', color: AppColors.danger),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.danger.withAlpha(80)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.three),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _activeName(AuthProvider auth) {
    if (auth.activeProfileId == null) return '—';
    final active = auth.profiles.where((p) => p.id == auth.activeProfileId).firstOrNull;
    return active?.name ?? '—';
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _switchTo(BuildContext context, AuthProvider auth, String id) async {
    if (id == auth.activeProfileId) return;
    try {
      await auth.switchTo(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ThemedText.small('Switched to ${_activeName(auth)}'),
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

  Future<void> _deleteManager(
      BuildContext context, AuthProvider auth, ManagerProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElement,
        title: Row(children: [
          const ThemedText('🗑️', fontSize: 20),
          const SizedBox(width: AppSpacing.two),
          ThemedText.title('Remove "${profile.name}"?'),
        ]),
        content: ThemedText.small(
          'This will delete the manager profile and its saved token. '
          'You can re-add it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: ThemedText.body('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: ThemedText.body('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await auth.removeManager(profile.id);
    }
  }

  Future<void> _addManager(BuildContext context, AuthProvider auth) async {
    final urlController = TextEditingController();
    final tokenController = TextEditingController();
    final nameController =
        TextEditingController(text: 'Manager ${auth.profiles.length + 1}');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElement,
        title: Row(children: [
          const ThemedText('➕', fontSize: 20),
          const SizedBox(width: AppSpacing.two),
          ThemedText.title('Add Manager'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Label'),
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.two),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Manager URL',
                  hintText: 'http://192.168.1.10:3099',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.two),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: 'Access Token'),
                obscureText: true,
                autocorrect: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: ThemedText.body('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: ThemedText.body('Connect'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final url = urlController.text.trim();
      final token = tokenController.text.trim();
      final name = nameController.text.trim();
      if (url.isEmpty || token.isEmpty) return;

      try {
        await auth.login(url, token, name: name.isNotEmpty ? name : null);
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

    urlController.dispose();
    tokenController.dispose();
    nameController.dispose();
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElement,
        title: Row(children: [
          const ThemedText('🚪', fontSize: 20),
          const SizedBox(width: AppSpacing.two),
          ThemedText.title('Logout?'),
        ]),
        content: ThemedText.small(
          'Disconnect from "${_activeName(auth)}". '
          'The profile will be kept for later use.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: ThemedText.body('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: ThemedText.body('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await auth.logout();
    }
  }
}

// ── Manager card ──────────────────────────────────────────────────────

class _ManagerCard extends StatelessWidget {
  final ManagerProfile profile;
  final bool isActive;
  final bool isConnected;
  final VoidCallback onSwitch;
  final VoidCallback onDelete;

  const _ManagerCard({
    required this.profile,
    required this.isActive,
    required this.isConnected,
    required this.onSwitch,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.one),
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withAlpha(18)
              : AppColors.backgroundElement,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: isActive
              ? Border.all(color: AppColors.accent.withAlpha(80), width: 1)
              : null,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.three,
            vertical: AppSpacing.one,
          ),
          title: ThemedText.body(profile.name),
          subtitle: ThemedText.small(
            profile.baseUrl,
            color: AppColors.textSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isConnected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                )
              else if (isActive && !isConnected)
                const ThemedText('⚠️', fontSize: 14),
              if (!isActive)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.textSecondary),
                  onPressed: onDelete,
                  tooltip: 'Remove',
                ),
            ],
          ),
          onTap: isActive ? null : onSwitch,
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundElement,
        borderRadius: BorderRadius.circular(AppSpacing.two),
      ),
      child: Row(
        children: [
          ThemedText.small(label, color: AppColors.textSecondary),
          const Spacer(),
          Flexible(
            child: ThemedText(
              value,
              color: valueColor ?? AppColors.text,
              fontSize: 12,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
