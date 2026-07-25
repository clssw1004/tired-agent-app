import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/section_header.dart';
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          // ── Managers ────────────────────────────────────────────────
          SectionHeader(label: 'Managers (${auth.profiles.length})'),
          const SizedBox(height: AppSpacing.two),

          if (auth.profiles.isEmpty)
            ThemedText.small(
              'No managers saved',
              color: AppColors.textSecondary,
            )
          else
            ...auth.profiles.map(
              (profile) => _ManagerCard(
                profile: profile,
                isActive: profile.id == auth.activeProfileId,
                isConnected:
                    profile.id == auth.activeProfileId &&
                    auth.status == AuthStatus.authenticated,
                onSwitch: () => _switchTo(context, auth, profile.id),
                onDelete: () => _deleteManager(context, auth, profile),
              ),
            ),

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
          SectionHeader(label: 'Active Connection'),
          const SizedBox(height: AppSpacing.two),
          _InfoTile(label: 'Manager', value: _activeName(auth)),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: 'Base URL', value: auth.baseUrl ?? '—'),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(
            label: 'Status',
            value: auth.status == AuthStatus.authenticated
                ? 'Connected'
                : 'Disconnected',
            valueColor: auth.status == AuthStatus.authenticated
                ? AppColors.success
                : AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: 'Agents', value: '${auth.agents.length}'),
          const SizedBox(height: AppSpacing.four),

          // ── About ──────────────────────────────────────────────────
          SectionHeader(label: 'About'),
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
    final active = auth.profiles
        .where((p) => p.id == auth.activeProfileId)
        .firstOrNull;
    return active?.name ?? '—';
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _switchTo(
    BuildContext context,
    AuthProvider auth,
    String id,
  ) async {
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
    BuildContext context,
    AuthProvider auth,
    ManagerProfile profile,
  ) async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: 'Remove "${profile.name}"?',
      showRobot: true,
      content: ThemedText.small(
        'This will delete the manager profile and its saved token. '
        'You can re-add it later.',
      ),
      confirmText: 'Remove',
      confirmIsDanger: true,
    );
    if (confirmed == true && context.mounted) {
      await auth.removeManager(profile.id);
    }
  }

  Future<void> _addManager(BuildContext context, AuthProvider auth) async {
    final formKey = GlobalKey<_AddManagerFormState>();

    final formData = await NeonDialog.show<_AddManagerFormData?>(
      context: context,
      title: 'Add Manager',
      maxWidth: 480,
      content: _AddManagerForm(
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

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: 'Logout?',
      showRobot: true,
      content: ThemedText.small(
        'Disconnect from "${_activeName(auth)}". '
        'The profile will be kept for later use.',
      ),
      confirmText: 'Logout',
      confirmIsDanger: true,
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
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({required this.label, required this.value, this.valueColor});

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

/// Form data returned by [_AddManagerForm].
class _AddManagerFormData {
  final String name;
  final String url;
  final String token;
  const _AddManagerFormData(this.name, this.url, this.token);
}

/// Stateful form widget that owns its [TextEditingController]s and disposes
/// them in sync with the dialog's widget tree lifecycle.
class _AddManagerForm extends StatefulWidget {
  final String initialName;

  const _AddManagerForm({super.key, required this.initialName});

  @override
  _AddManagerFormState createState() => _AddManagerFormState();
}

class _AddManagerFormState extends State<_AddManagerForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _urlController = TextEditingController();
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  _AddManagerFormData get data => _AddManagerFormData(
        _nameController.text.trim(),
        _urlController.text.trim(),
        _tokenController.text.trim(),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Label',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.three,
                vertical: AppSpacing.three,
              ),
            ),
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.three),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Manager URL',
              hintText: 'http://192.168.1.10:3099',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.three,
                vertical: AppSpacing.three,
              ),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.three),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Access Token',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.three,
                vertical: AppSpacing.three,
              ),
            ),
            obscureText: true,
            autocorrect: false,
          ),
        ],
      ),
    );
  }
}