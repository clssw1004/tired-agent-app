import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/neon_dialog.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/forms/add_manager_form.dart';
import 'package:tired_agent_app/widgets/forms/reconnect_form.dart';
import 'package:tired_agent_app/widgets/manager_card/contract.dart';

class ServerListScreen extends StatelessWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(AppStrings.of.managersTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      floatingActionButton: auth.connections.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddManager(context, auth),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Expanded(
            child: auth.connections.isEmpty
                ? _buildWelcomeEmpty(context, auth)
                : _buildManagerList(context, auth),
          ),
        ],
      ),
    );
  }

  // ── Welcome state (no profiles) ─────────────────────────────────────

  Widget _buildWelcomeEmpty(BuildContext context, AuthProvider auth) {
    final c = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 80, color: c.primary.withAlpha(180)),
            const SizedBox(height: AppSpacing.four),
            ThemedText.title(AppStrings.of.managersWelcome),
            const SizedBox(height: AppSpacing.two),
            ThemedText(
              AppStrings.of.managersWelcomeDesc,
              color: c.textSecondary,
              fontSize: 12,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.six),
            ElevatedButton.icon(
              onPressed: () => _showAddManager(context, auth),
              icon: const Icon(Icons.add, size: 20),
              label: Text(AppStrings.of.managersAdd),
            ),
          ],
        ),
      ),
    );
  }

  // ── Manager list ────────────────────────────────────────────────────

  Widget _buildManagerList(BuildContext context, AuthProvider auth) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.four,
        AppSpacing.two,
        AppSpacing.four,
        AppSpacing.four,
      ),
      itemCount: auth.connections.length,
      itemBuilder: (context, index) {
        final conn = auth.connections[index];
        return context.appComponents.buildManagerCard(
          context,
          ManagerCardData(
            connection: conn,
            onTap: () => _onTapCard(context, auth, conn),
            onDelete: () => _deleteManager(context, auth, conn),
          ),
        );
      },
    );
  }

  // ── Add Manager dialog ──────────────────────────────────────────────

  Future<void> _showAddManager(BuildContext context, AuthProvider auth) async {
    final formKey = GlobalKey<AddManagerFormState>();

    final formData = await NeonDialog.show<AddManagerFormData?>(
      context: context,
      title: AppStrings.of.managersAdd,
      maxWidth: 480,
      content: AddManagerForm(
        key: formKey,
        initialName: AppStrings.of.managersDefaultName(
          auth.connections.length + 1,
        ),
      ),
      actions: [
        NeonDialogAction(
          label: AppStrings.of.cancel,
          onPressed: (ctx) => Navigator.of(ctx).pop(null),
        ),
        NeonDialogAction(
          label: AppStrings.of.managersConnect,
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
              content: ThemedText.small(AppStrings.of.managersAdded),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final c = context.appColors;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: c.danger),
          );
        }
      }
    }
  }

  Future<void> _showReconnectDialog(
    BuildContext context,
    AuthProvider auth,
    ManagerConnection conn,
  ) async {
    final formKey = GlobalKey<ReconnectFormState>();

    final result = await NeonDialog.show<String?>(
      context: context,
      title: '${AppStrings.of.reconnectLabel} ${conn.profile.name}',
      maxWidth: 380,
      showRobot: true,
      content: ReconnectForm(key: formKey),
      actions: [
        NeonDialogAction(
          label: AppStrings.of.cancel,
          onPressed: (ctx) => Navigator.of(ctx).pop(null),
        ),
        NeonDialogAction(
          label: AppStrings.of.reconnectLabel,
          isPrimary: true,
          onPressed: (ctx) {
            final token = formKey.currentState?.token;
            if (token != null && token.isNotEmpty) {
              Navigator.of(ctx).pop(token);
            }
          },
        ),
      ],
    );

    if (result != null && context.mounted) {
      debugPrint('[Reconnect] token received, connecting…');
      final ok = await auth.reconnect(conn.profile.id, result);
      debugPrint('[Reconnect] ok=$ok');
      if (context.mounted) {
        final c = context.appColors;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ThemedText.small(
                '${conn.profile.name} ${AppStrings.of.managersReconnected}',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                conn.error ?? AppStrings.of.managersReconnectFailed,
              ),
              backgroundColor: c.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _onTapCard(
    BuildContext context,
    AuthProvider auth,
    ManagerConnection conn,
  ) async {
    // Already connected → navigate directly.
    if (conn.status == ConnectionStatus.connected) {
      if (context.mounted) context.push('/profile/${conn.profile.id}');
      return;
    }

    // Silent retry with stored credentials.
    await conn.connect();

    if (conn.status == ConnectionStatus.connected && context.mounted) {
      context.push('/profile/${conn.profile.id}');
      return;
    }

    // Any failure → show reconnect dialog (token expired or cleared).
    if (context.mounted) {
      await _showReconnectDialog(context, auth, conn);
    }
  }

  Future<void> _deleteManager(
    BuildContext context,
    AuthProvider auth,
    ManagerConnection conn,
  ) async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: AppStrings.of.managersRemoveTitle(conn.profile.name),
      showRobot: true,
      content: ThemedText.small(AppStrings.of.managersRemoveDesc),
      confirmText: AppStrings.of.managersRemove,
      confirmIsDanger: true,
    );
    if (confirmed == true && context.mounted) {
      await auth.removeManager(conn.profile.id);
    }
  }
}
