import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/add_manager_form.dart';
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
          SectionHeader(label: 'Managers (${auth.connections.length})'),
          const SizedBox(height: AppSpacing.two),

          if (auth.connections.isEmpty)
            ThemedText.small(
              'No managers saved',
              color: AppColors.textSecondary,
            )
          else
            ...auth.connections.map(
              (conn) => _ManagerCard(
                connection: conn,
                onDelete: () => _deleteManager(context, auth, conn.profile),
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

          // ── Active connections ──────────────────────────────────────
          SectionHeader(label: 'Connections'),
          const SizedBox(height: AppSpacing.two),
          ...auth.connections.map(
            (conn) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.one),
              child: _InfoTile(
                label: conn.profile.name,
                value: _statusLabel(conn.status),
                valueColor: _statusColor(conn.status),
              ),
            ),
          ),
          if (auth.connections.isEmpty)
            _InfoTile(
              label: 'Status',
              value: 'No managers',
              valueColor: AppColors.textSecondary,
            ),
          const SizedBox(height: AppSpacing.four),

          // ── About ──────────────────────────────────────────────────
          SectionHeader(label: 'About'),
          const SizedBox(height: AppSpacing.two),
          _InfoTile(label: 'App', value: 'TiredAgent'),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: 'Version', value: '1.0.0'),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }

  String _statusLabel(ConnectionStatus s) {
    switch (s) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting…';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.idle:
        return 'Disconnected';
    }
  }

  Color _statusColor(ConnectionStatus s) {
    switch (s) {
      case ConnectionStatus.connected:
        return AppColors.success;
      case ConnectionStatus.connecting:
        return AppColors.warning;
      case ConnectionStatus.error:
        return AppColors.danger;
      case ConnectionStatus.idle:
        return AppColors.textSecondary;
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────

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
    final formKey = GlobalKey<AddManagerFormState>();

    final formData = await NeonDialog.show<AddManagerFormData?>(
      context: context,
      title: 'Add Manager',
      maxWidth: 480,
      content: AddManagerForm(
        key: formKey,
        initialName: 'Manager ${auth.connections.length + 1}',
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

// ── Manager card ──────────────────────────────────────────────────────

class _ManagerCard extends StatelessWidget {
  final ManagerConnection connection;
  final VoidCallback onDelete;

  const _ManagerCard({required this.connection, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final profile = connection.profile;
    final connected = connection.status == ConnectionStatus.connected;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.one),
      child: Container(
        decoration: BoxDecoration(
          color: connected
              ? AppColors.accent.withAlpha(18)
              : AppColors.backgroundElement,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: connected
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
              if (connected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
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
