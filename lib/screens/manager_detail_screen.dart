import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/add_agent_form.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/agent_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';
import 'package:tired_agent_app/utils/app_strings.dart';

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
      title: AppStrings.of.agentAddTitle,
      maxWidth: 480,
      content: AddAgentForm(key: formKey),
      actions: [
        NeonDialogAction(
          label: AppStrings.of.cancel,
          onPressed: (ctx) => Navigator.of(ctx).pop(null),
        ),
        NeonDialogAction(
          label: AppStrings.of.agentRegister,
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
              content: ThemedText.small(
                AppStrings.of.agentAdded(formData.name),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final c = context.appColors;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of.agentAddFailed(e.toString())),
              backgroundColor: c.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAgent(AgentInfo agent) async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: AppStrings.of.agentRemoveTitle(agent.name),
      showRobot: true,
      content: ThemedText.small(AppStrings.of.agentRemoveDesc),
      confirmText: AppStrings.of.removeLabel,
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
            content: ThemedText.small(AppStrings.of.agentRemoved(agent.name)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final c = context.appColors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of.agentRemoveFailed(e.toString())),
            backgroundColor: c.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(
          conn?.profile.name ?? AppStrings.of.agentManagerNotFound,
        ),
        actions: [
          if (conn?.status == ConnectionStatus.connected)
            IconButton(
              icon: Icon(Icons.add, color: c.primary),
              tooltip: AppStrings.of.agentAddTooltip,
              onPressed: _showAddAgent,
            ),
        ],
      ),
      body: _buildBody(conn),
    );
  }

  Widget _buildBody(ManagerConnection? conn) {
    if (conn == null) {
      return Center(
        child: ThemedText.small(AppStrings.of.agentManagerNotFound),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final c = context.appColors;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.four),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: c.danger),
              const SizedBox(height: AppSpacing.two),
              ThemedText.small(_error!, color: c.danger),
              const SizedBox(height: AppSpacing.three),
              ElevatedButton(
                onPressed: _loadAgents,
                child: Text(AppStrings.of.agentRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_agents.isEmpty) {
      final c = context.appColors;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.four),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dns_outlined, size: 64, color: c.textSecondary),
              const SizedBox(height: AppSpacing.three),
              ThemedText.title(
                AppStrings.of.agentNoAgents,
                color: c.textSecondary,
              ),
              const SizedBox(height: AppSpacing.one),
              ThemedText.small(
                AppStrings.of.agentNoAgentsDesc,
                color: c.textSecondary,
              ),
              const SizedBox(height: AppSpacing.four),
              ElevatedButton.icon(
                onPressed: _showAddAgent,
                icon: const Icon(Icons.add, size: 20),
                label: Text(AppStrings.of.agentAddTooltip),
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
          return AgentCard(
            agent: agent,
            profileId: widget.profileId,
            onDelete: () => _deleteAgent(agent),
          );
        },
      ),
    );
  }
}
