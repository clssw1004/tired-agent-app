import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/add_manager_form.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class ServerListScreen extends StatelessWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('Managers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
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
            ThemedText.title('Welcome to tiredAgent'),
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
        return _ManagerCard(
          connection: conn,
          onTap: () => _onTapCard(context, auth, conn),
          onDelete: () => _deleteManager(context, auth, conn),
        );
      },
    );
  }

  // ── Add Manager dialog ──────────────────────────────────────────────

  Future<void> _showAddManager(
    BuildContext context,
    AuthProvider auth,
  ) async {
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

  Future<void> _showReconnectDialog(
    BuildContext context,
    AuthProvider auth,
    ManagerConnection conn,
  ) async {
    final formKey = GlobalKey<_ReconnectFormState>();

    final result = await NeonDialog.show<String?>(
      context: context,
      title: 'Reconnect ${conn.profile.name}',
      maxWidth: 380,
      showRobot: true,
      content: _ReconnectForm(key: formKey),
      actions: [
        NeonDialogAction(
          label: 'Cancel',
          onPressed: (ctx) => Navigator.of(ctx).pop(null),
        ),
        NeonDialogAction(
          label: 'Reconnect',
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
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ThemedText.small('${conn.profile.name} reconnected'),
              backgroundColor: AppColors.backgroundElement,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(conn.error ?? 'Reconnect failed'),
              backgroundColor: AppColors.danger,
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
    // Silent retry with stored credentials (handles transient network errors).
    await conn.connect();
    if (conn.status == ConnectionStatus.connected) return;

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
      title: 'Remove "${conn.profile.name}"?',
      showRobot: true,
      content: ThemedText.small(
        'This will delete the manager profile and its saved token. '
        'You can re-add it later.',
      ),
      confirmText: 'Remove',
      confirmIsDanger: true,
    );
    if (confirmed == true && context.mounted) {
      await auth.removeManager(conn.profile.id);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Manager card
// ═══════════════════════════════════════════════════════════════════════

class _ManagerCard extends StatelessWidget {
  final ManagerConnection connection;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _ManagerCard({required this.connection, this.onTap, this.onDelete});

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}s ago';
    if (s < 3600000) return '${s ~/ 60000}m ago';
    if (s < 86400000) return '${s ~/ 3600000}h ago';
    return '${s ~/ 86400000}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final profile = connection.profile;
    final connStatus = connection.status;

    // Status color + label
    Color statusColor;
    String statusLabel;
    switch (connStatus) {
      case ConnectionStatus.connected:
        statusColor = AppColors.success;
        statusLabel = 'Connected';
      case ConnectionStatus.connecting:
        statusColor = AppColors.warning;
        statusLabel = 'Connecting…';
      case ConnectionStatus.error:
        statusColor = AppColors.danger;
        statusLabel = 'Error';
      case ConnectionStatus.idle:
        statusColor = AppColors.textSecondary;
        statusLabel = 'Disconnected';
    }

    // Agent summary (only meaningful when connected)
    final agents = connection.agents;
    final totalAgents = agents.length;
    final onlineAgents = agents.where((a) => a.state == AgentState.online).length;
    final offlineAgents = agents.where((a) => a.state == AgentState.offline).length;
    final unknownAgents = agents.where((a) => a.state == AgentState.unknown).length;
    final hasAgentInfo = totalAgents > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.three),
      child: GestureDetector(
        onTap: () {
          if (connStatus == ConnectionStatus.connected) {
            context.push('/profile/${profile.id}');
          } else {
            onTap?.call();
          }
        },
        onLongPress: onDelete,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.two),
            border: Border.all(
              color: connStatus == ConnectionStatus.connected
                  ? AppColors.primary.withAlpha(60)
                  : AppColors.border.withAlpha(80),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.three,
                  AppSpacing.two,
                  AppSpacing.one,
                  AppSpacing.one,
                ),
                child: Row(
                  children: [
                    // Status dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: connStatus == ConnectionStatus.connected
                            ? [
                                BoxShadow(
                                  color: statusColor.withAlpha(80),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.two),
                    // Name + URL
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ThemedText.body(
                            profile.name,
                            color: AppColors.text,
                          ),
                          ThemedText.label(
                            profile.baseUrl,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    // Status label
                    ThemedText.label(
                      statusLabel,
                      color: statusColor,
                    ),
                    // Error info icon
                    if (connection.error != null)
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        onPressed: () => _showError(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    // Delete button
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => onDelete?.call(),
                        tooltip: 'Remove manager',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                  ],
                ),
              ),

              // ── Secondary info row ─────────────────────────────
              if (hasAgentInfo || profile.lastUsedMs > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.three,
                    0,
                    AppSpacing.three,
                    AppSpacing.two,
                  ),
                  child: Row(
                    children: [
                      if (hasAgentInfo)
                        Expanded(
                          child: ThemedText.mono(
                            '$totalAgents agents · '
                            '$onlineAgents online · '
                            '$offlineAgents offline'
                            '${unknownAgents > 0 ? ' · $unknownAgents unknown' : ''}',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (profile.lastUsedMs > 0)
                        ThemedText.mono(
                          _timeSince(profile.lastUsedMs),
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(connection.error!),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Reconnect form
// ═══════════════════════════════════════════════════════════════════════

/// Reconnect form — owns its [TextEditingController] and disposes it in
/// [State.dispose], in sync with the widget tree lifecycle.
class _ReconnectForm extends StatefulWidget {
  const _ReconnectForm({super.key});

  @override
  _ReconnectFormState createState() => _ReconnectFormState();
}

class _ReconnectFormState extends State<_ReconnectForm> {
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String? get token {
    final t = _tokenController.text.trim();
    return t.isNotEmpty ? t : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedText.small(
          'Session expired. Enter the API token to reconnect.',
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.three),
        TextField(
          controller: _tokenController,
          decoration: const InputDecoration(labelText: 'Access Token'),
          obscureText: true,
          autocorrect: false,
        ),
      ],
    );
  }
}