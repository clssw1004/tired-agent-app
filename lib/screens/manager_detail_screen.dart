import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/add_agent_form.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Displays all agents for a given manager, with an option to add new ones.
class ManagerDetailScreen extends StatefulWidget {
  final String profileId;

  const ManagerDetailScreen({super.key, required this.profileId});

  @override
  State<ManagerDetailScreen> createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends State<ManagerDetailScreen> {
  List<AgentInfo> _agents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load agents from cache immediately (no re-auth during build).
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn != null) {
      _agents = List.from(conn.agents);
    }
    _loading = false;
    // Refresh in background after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAgents());
  }

  Future<void> _loadAgents() async {
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await conn.connect();
      if (!mounted) return;
      setState(() {
        _agents = List.from(conn.agents);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showAddAgent() async {
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn == null || conn.status != ConnectionStatus.connected) return;

    final formKey = GlobalKey<AddAgentFormState>();

    final formData = await NeonDialog.show<AddAgentFormData?>(
      context: context,
      title: 'Add Agent',
      maxWidth: 480,
      content: AddAgentForm(key: formKey),
      actions: [
        NeonDialogAction(
          label: 'Cancel',
          onPressed: (ctx) => Navigator.of(ctx).pop(null),
        ),
        NeonDialogAction(
          label: 'Register',
          isPrimary: true,
          onPressed: (ctx) {
            final data = formKey.currentState?.data;
            if (data != null &&
                data.url.isNotEmpty &&
                data.token.isNotEmpty &&
                data.name.isNotEmpty) {
              Navigator.of(ctx).pop(data);
            }
          },
        ),
      ],
    );

    if (formData != null && mounted) {
      try {
        await conn.transport.addAgent(
          conn.managerRef,
          name: formData.name,
          baseUrl: formData.url,
          token: formData.token,
        );
        await _loadAgents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ThemedText.small('Agent ${formData.name} added'),
              backgroundColor: AppColors.backgroundElement,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add agent: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAgent(AgentInfo agent) async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: 'Remove agent "${agent.name}"?',
      showRobot: true,
      content: ThemedText.small(
        'Unregisters the agent and removes its sessions. '
        'You can re-add it later.',
      ),
      confirmText: 'Remove',
      confirmIsDanger: true,
    );
    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn == null || conn.status != ConnectionStatus.connected) return;

    try {
      await conn.transport.deleteAgent(conn.managerRef, agent.id);
      await _loadAgents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ThemedText.small('Agent ${agent.name} removed'),
            backgroundColor: AppColors.backgroundElement,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove agent: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title(conn?.profile.name ?? 'Manager'),
        actions: [
          if (conn?.status == ConnectionStatus.connected)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              tooltip: 'Add Agent',
              onPressed: _showAddAgent,
            ),
        ],
      ),
      body: _buildBody(conn),
    );
  }

  Widget _buildBody(ManagerConnection? conn) {
    if (conn == null) {
      return Center(child: ThemedText.small('Manager not found'));
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.four),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: AppColors.danger),
              const SizedBox(height: AppSpacing.two),
              ThemedText.small(_error!, color: AppColors.danger),
              const SizedBox(height: AppSpacing.three),
              ElevatedButton(
                onPressed: _loadAgents,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_agents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.four),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dns_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.three),
              ThemedText.title('No Agents', color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.one),
              ThemedText.small(
                'Register an agent to start creating sessions',
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.four),
              ElevatedButton.icon(
                onPressed: _showAddAgent,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Agent'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAgents,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.four,
          AppSpacing.two,
          AppSpacing.four,
          AppSpacing.four,
        ),
        itemCount: _agents.length,
        itemBuilder: (context, index) {
          final agent = _agents[index];
          return _ManagerAgentCard(
            agent: agent,
            profileId: widget.profileId,
            onDelete: () => _deleteAgent(agent),
          );
        },
      ),
    );
  }
}

/// An agent card in the manager detail page.
class _ManagerAgentCard extends StatelessWidget {
  final AgentInfo agent;
  final String profileId;
  final VoidCallback? onDelete;

  const _ManagerAgentCard({
    required this.agent,
    required this.profileId,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.three),
      child: GestureDetector(
        onTap: () => context.push('/profile/$profileId/agent/${agent.id}'),
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
                // Status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _agentColor(agent.state),
                    shape: BoxShape.circle,
                    boxShadow: agent.state == AgentState.online
                        ? [
                            BoxShadow(
                              color: AppColors.success.withAlpha(80),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.three),
                // Name + URL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThemedText.body(agent.name, color: AppColors.text),
                      const SizedBox(height: 2),
                      ThemedText.label(
                        agent.baseUrl,
                        color: AppColors.textSecondary,
                      ),
                      if (agent.platform != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _platformIcon(agent.platform!.os),
                            const SizedBox(width: 4),
                            ThemedText.mono(
                              '${agent.platform!.os} · ${agent.platform!.arch}',
                              color: AppColors.primary.withAlpha(120),
                            ),
                          ],
                        ),
                      ],
                    ],
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
                    tooltip: 'Remove agent',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _agentColor(AgentState s) {
    switch (s) {
      case AgentState.online:
        return AppColors.success;
      case AgentState.offline:
        return AppColors.danger;
      case AgentState.pending:
        return AppColors.textSecondary;
    }
  }

  static Widget _platformIcon(String os) {
    IconData icon;
    Color color;
    switch (os) {
      case 'win32':
        icon = Icons.window;
        color = AppColors.primary;
      case 'darwin':
        icon = Icons.laptop_mac;
        color = AppColors.text;
      case 'linux':
        icon = Icons.terminal;
        color = AppColors.warning;
      default:
        icon = Icons.devices;
        color = AppColors.textSecondary;
    }
    return Icon(icon, size: 14, color: color.withAlpha(160));
  }
}
