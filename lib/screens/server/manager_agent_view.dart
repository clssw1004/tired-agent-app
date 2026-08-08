import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/screens/server/add_agent_screen.dart'
    show AddAgentPageArgs;
import 'package:tired_agent_app/screens/server/manager_group_header.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/agent_card/contract.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/forms/add_agent_form.dart';

/// 首页 Manager-Agent 分组视图。
///
/// 每个 manager 一个 [ManagerGroupHeader]，下方列出其 agent（只读）。
/// 数据全部反应式读取 `AuthProvider.connections`（生产上 boot() 已给每个 conn
/// 挂 listener 转发通知），不做本地 agents 缓存；折叠状态与 5s 轮询 timer 为
/// 本地状态，dispose 时取消 timer。
class ManagerAgentView extends StatefulWidget {
  const ManagerAgentView({super.key});

  @override
  State<ManagerAgentView> createState() => _ManagerAgentViewState();
}

class _ManagerAgentViewState extends State<ManagerAgentView> {
  /// 折叠的 manager（按 profile.id，内存态，切模式/重建后重置）。
  final Set<String> _collapsed = {};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // 轮询 agent 状态：online/offline 由服务端健康探测产生，客户端需定期
    // 拉取 listAgents 才能看到变化（对齐 manager_detail 的 _loadSilent）。
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollSilently(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.two,
        AppSpacing.two,
        AppSpacing.two,
        AppSpacing.four,
      ),
      itemCount: auth.connections.length,
      itemBuilder: (context, index) {
        final conn = auth.connections[index];
        final collapsed = _collapsed.contains(conn.profile.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ManagerGroupHeader(
              connection: conn,
              collapsed: collapsed,
              agentCount: conn.agents.length,
              onToggle: () => _toggle(conn),
              onAddAgent: () => _addAgent(conn),
              onOpenDetail: () => _openDetail(conn),
            ),
            if (!collapsed) _buildGroupBody(context, conn),
          ],
        );
      },
    );
  }

  // ── Group body ────────────────────────────────────────────────────

  Widget _buildGroupBody(BuildContext context, ManagerConnection conn) {
    final c = context.appColors;
    switch (conn.status) {
      case ConnectionStatus.connected:
        if (conn.agents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.three,
              0,
              AppSpacing.three,
              AppSpacing.three,
            ),
            child: ThemedText.small(
              AppStrings.of.agentNoAgents,
              color: c.textSecondary,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final agent in conn.agents)
              context.appComponents.buildAgentCard(
                context,
                AgentCardData(
                  agent: agent,
                  onTap: () => context.push(
                    '/profile/${conn.profile.id}/agent/${agent.id}',
                  ),
                  // 只读：不传 onEdit/onDelete，三套卡自动隐藏编辑/删除按钮
                ),
              ),
          ],
        );
      case ConnectionStatus.connecting:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.three,
            0,
            AppSpacing.three,
            AppSpacing.three,
          ),
          child: ThemedText.small(
            AppStrings.of.statusConnecting,
            color: c.warning,
          ),
        );
      case ConnectionStatus.error:
      case ConnectionStatus.idle:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.three,
            0,
            AppSpacing.three,
            AppSpacing.three,
          ),
          child: Row(
            children: [
              Expanded(
                child: ThemedText.small(
                  conn.error ?? AppStrings.of.statusDisconnected,
                  color: c.danger,
                ),
              ),
              TextButton(
                onPressed: () => _retry(conn),
                child: Text(AppStrings.of.agentRetry),
              ),
            ],
          ),
        );
    }
  }

  // ── 交互 ──────────────────────────────────────────────────────────

  void _toggle(ManagerConnection conn) {
    setState(() {
      if (!_collapsed.remove(conn.profile.id)) {
        _collapsed.add(conn.profile.id);
      }
    });
  }

  void _openDetail(ManagerConnection conn) {
    context.push('/profile/${conn.profile.id}');
  }

  /// 行内重试：静默用存证 token 重连，失败仅行内错误 + snackbar。
  Future<void> _retry(ManagerConnection conn) async {
    await conn.connect();
    if (!mounted) return;
    if (conn.status == ConnectionStatus.connected) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(conn.error ?? AppStrings.of.managersReconnectFailed),
        backgroundColor: context.appColors.danger,
      ),
    );
  }

  /// 静默轮询 agent 状态：不翻转连接状态、失败保留上次列表。
  Future<void> _pollSilently() async {
    final auth = context.read<AuthProvider>();
    if (!mounted) return;
    for (final conn in List<ManagerConnection>.of(auth.connections)) {
      if (conn.status != ConnectionStatus.connected) continue;
      try {
        await conn.refreshAgents();
      } catch (_) {
        // 瞬时失败忽略，下轮再试。
      }
    }
  }

  /// ＋agent：镜像 manager_detail 的 _showAddAgent。
  Future<void> _addAgent(ManagerConnection conn) async {
    if (conn.status != ConnectionStatus.connected) return;
    final formData = await context.push<AddAgentFormData>(
      '/profile/${conn.profile.id}/add-agent',
      extra: const AddAgentPageArgs(),
    );
    if (formData == null || !mounted) return;
    try {
      await conn.transport.addAgent(
        conn.managerRef,
        name: formData.name,
        baseUrl: formData.url,
        token: formData.token,
      );
      await conn.refreshAgents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ThemedText.small(AppStrings.of.agentAdded(formData.name)),
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
