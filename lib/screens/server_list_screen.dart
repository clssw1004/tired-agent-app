import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/providers/server_provider.dart';
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
        title: ThemedText.title('Agents'),
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
      itemCount: auth.connections.length + 1, // +1 for Add Manager button
      itemBuilder: (context, index) {
        if (index == auth.connections.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.three),
            child: OutlinedButton.icon(
              onPressed: () => _showAddManager(context, auth),
              icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
              label: ThemedText.body(
                'Add Manager',
                color: AppColors.accent,
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accent.withAlpha(60)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.three),
              ),
            ),
          );
        }
        final conn = auth.connections[index];
        return _ManagerCard(
          connection: conn,
          onAddAgent: () => _showAddAgent(context, auth, conn),
          onReconnect: () => _showReconnect(context, auth, conn),
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

  Future<void> _showAddAgent(
    BuildContext context,
    AuthProvider auth,
    ManagerConnection conn,
  ) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final tokenController = TextEditingController();

    final result = await NeonDialog.show<bool>(
      context: context,
      title: 'Add Agent to ${conn.profile.name}',
      maxWidth: 420,
      showRobot: true,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autocorrect: false,
            ),
            const SizedBox(height: AppSpacing.three),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://agent.local:8444',
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: AppSpacing.three),
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
        NeonDialogAction(
          label: 'Cancel',
          onPressed: (ctx) => Navigator.of(ctx).pop(false),
        ),
        NeonDialogAction(
          label: 'Add',
          isPrimary: true,
          onPressed: (ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
    );

    if (result == true && context.mounted) {
      final name = nameController.text.trim();
      final url = urlController.text.trim();
      final token = tokenController.text.trim();
      nameController.dispose();
      urlController.dispose();
      tokenController.dispose();
      if (name.isEmpty || url.isEmpty || token.isEmpty) return;

      try {
        final serverProvider = context.read<ServerProvider>();
        await serverProvider.addServer(
          conn.profile.id,
          name,
          url,
          token,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ThemedText.small('Agent "$name" added'),
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

  Future<void> _showReconnect(
    BuildContext context,
    AuthProvider auth,
    ManagerConnection conn,
  ) async {
    final tokenController = TextEditingController();

    final result = await NeonDialog.show<bool>(
      context: context,
      title: 'Reconnect ${conn.profile.name}',
      maxWidth: 380,
      showRobot: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedText.small(
            'The session has expired. Enter the API token to reconnect.',
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.three),
          TextField(
            controller: tokenController,
            decoration: const InputDecoration(labelText: 'Access Token'),
            obscureText: true,
            autocorrect: false,
          ),
        ],
      ),
      actions: [
        NeonDialogAction(
          label: 'Cancel',
          onPressed: (ctx) => Navigator.of(ctx).pop(false),
        ),
        NeonDialogAction(
          label: 'Reconnect',
          isPrimary: true,
          onPressed: (ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
    );

    final token = tokenController.text.trim();
    tokenController.dispose();

    if (result == true && token.isNotEmpty && context.mounted) {
      try {
        await conn.connect(apiToken: token);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ThemedText.small('${conn.profile.name} reconnected'),
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

// ═══════════════════════════════════════════════════════════════════════
// Manager card
// ═══════════════════════════════════════════════════════════════════════

class _ManagerCard extends StatelessWidget {
  final ManagerConnection connection;
  final VoidCallback? onAddAgent;
  final VoidCallback? onReconnect;

  const _ManagerCard({required this.connection, this.onAddAgent, this.onReconnect});

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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.three),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(
            color: connStatus == ConnectionStatus.connected
                ? AppColors.primary.withAlpha(60)
                : AppColors.border.withAlpha(80),
            width: connStatus == ConnectionStatus.connected ? 0.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.three,
                AppSpacing.two,
                AppSpacing.two,
                AppSpacing.one,
              ),
              child: Row(
                children: [
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
                  Expanded(
                    child: ThemedText.body(
                      profile.name,
                      color: AppColors.text,
                    ),
                  ),
                  ThemedText.label(
                    statusLabel,
                    color: statusColor,
                  ),
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
                ],
              ),
            ),

            // ── Reconnect button (when not connected) ─────────────
            if (connStatus != ConnectionStatus.connected)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.three + 10 + AppSpacing.two,
                  bottom: 4,
                ),
                child: GestureDetector(
                  onTap: onReconnect,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: AppColors.primary.withAlpha(180),
                      ),
                      const SizedBox(width: 6),
                      ThemedText.small(
                        connStatus == ConnectionStatus.error
                            ? 'Token expired — Tap to reconnect'
                            : 'Tap to reconnect',
                        color: AppColors.primary.withAlpha(180),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Agent list ───────────────────────────────────────
            if (connection.agents.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.three + 10 + AppSpacing.two,
                  0,
                  AppSpacing.three,
                  AppSpacing.two,
                ),
                child: ThemedText.small(
                  connStatus == ConnectionStatus.connected
                      ? 'No agents available'
                      : 'Connecting…',
                  color: AppColors.textSecondary,
                ),
              )
            else
              ...connection.agents.map(
                (agent) => _AgentRow(
                  agent: agent,
                  profileId: profile.id,
                ),
              ),
            // ── Add Agent button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.three + 10 + AppSpacing.two,
                top: 4,
                bottom: 8,
              ),
              child: GestureDetector(
                onTap: connStatus == ConnectionStatus.connected
                    ? onAddAgent
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 14,
                      color: connStatus == ConnectionStatus.connected
                          ? AppColors.primary.withAlpha(180)
                          : AppColors.textSecondary.withAlpha(80),
                    ),
                    const SizedBox(width: 6),
                    ThemedText.small(
                      'Add Agent',
                      color: connStatus == ConnectionStatus.connected
                          ? AppColors.primary.withAlpha(180)
                          : AppColors.textSecondary.withAlpha(80),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
// Agent row inside a Manager card
// ═══════════════════════════════════════════════════════════════════════

class _AgentRow extends StatelessWidget {
  final AgentInfo agent;
  final String profileId;

  const _AgentRow({required this.agent, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
      ),
      child: InkWell(
        onTap: () => context.push(
          '/profile/$profileId/agent/${agent.id}',
        ),
        borderRadius: BorderRadius.circular(AppSpacing.one),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.two,
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _agentOnlineColor(agent.state),
                  shape: BoxShape.circle,
                  boxShadow: agent.state == AgentState.online
                      ? [
                          BoxShadow(
                            color: AppColors.success.withAlpha(80),
                            blurRadius: 3,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.two),
              Expanded(
                child: ThemedText.small(
                  agent.name,
                  color: AppColors.text,
                ),
              ),
              ThemedText.label(
                agent.baseUrl,
                color: AppColors.textSecondary,
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _agentOnlineColor(AgentState s) {
    switch (s) {
      case AgentState.online:
        return AppColors.success;
      case AgentState.offline:
        return AppColors.danger;
      case AgentState.unknown:
        return AppColors.textSecondary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════