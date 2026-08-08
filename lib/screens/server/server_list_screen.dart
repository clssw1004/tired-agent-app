import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/screens/server/add_agent_screen.dart'
    show AddAgentPageArgs;
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/agent_card/contract.dart';
import 'package:tired_agent_app/widgets/common/neon_dialog.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/forms/add_agent_form.dart';
import 'package:tired_agent_app/widgets/forms/add_manager_form.dart';
import 'package:tired_agent_app/widgets/forms/reconnect_form.dart';

/// 首页：manager 详情。
///
/// AppBar 标题是 manager 切换器（切换展示哪个 manager），body 是当前
/// manager 的 agent 列表（可添加/编辑/删除/进入会话）。无 manager 时显示
/// 欢迎页。默认展示的 manager 由 `AppSettingsProvider.defaultManagerId`
/// 决定（null = 跟随第一个）。
class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  static const _kAddManagerMenu = '__add_manager__';
  static const _kDeleteManagerMenu = '__delete_manager__';

  /// 当前选中的 manager（profile.id）。
  String? _selectedId;
  List<AgentInfo> _agents = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final settings = context.read<AppSettingsProvider>();
    _selectedId = _resolveInitial(auth, settings);
    final conn = _selectedId != null ? auth.connectionFor(_selectedId!) : null;
    // 同步读缓存，避免首帧闪 loading；首帧后异步刷新。
    _agents = List.from(conn?.agents ?? []);
    _loading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAgents());
    // 轮询 agent 状态：online/offline 由服务端健康探测产生，需定期拉取。
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadSilent(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── 选中解析 ─────────────────────────────────────────────────────

  String? _resolveInitial(AuthProvider auth, AppSettingsProvider settings) {
    final pref = settings.defaultManagerId;
    if (pref != null && auth.connectionFor(pref) != null) return pref;
    return auth.connections.isEmpty ? null : auth.connections.first.profile.id;
  }

  /// 返回当前有效选中：`_selectedId` 若仍存在则用它，否则回退第一个。
  String? _resolveSelected(AuthProvider auth) {
    final id = _selectedId;
    if (id != null && auth.connectionFor(id) != null) return id;
    return auth.connections.isEmpty ? null : auth.connections.first.profile.id;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c = context.appColors;
    final effectiveId = _resolveSelected(auth);
    // manager 被删时同步回退到第一个并刷新。
    if (effectiveId != _selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedId == effectiveId) return;
        setState(() => _selectedId = effectiveId);
        _loadAgents();
      });
    }
    final current = effectiveId == null
        ? null
        : auth.connectionFor(effectiveId);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: _buildSwitcher(auth, effectiveId, current),
        actions: [
          if (current?.status == ConnectionStatus.connected)
            IconButton(
              icon: Icon(Icons.add, color: c.primary),
              tooltip: AppStrings.of.agentAddTooltip,
              onPressed: () => _showAddAgent(current!),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: auth.connections.isEmpty
          ? _buildWelcomeEmpty(auth)
          : _buildAgentList(current),
    );
  }

  // ── 顶部 manager 切换器 ──────────────────────────────────────────

  Widget _buildSwitcher(
    AuthProvider auth,
    String? effectiveId,
    ManagerConnection? current,
  ) {
    final c = context.appColors;
    return PopupMenuButton<String>(
      tooltip: AppStrings.of.managersTitle,
      onSelected: (v) => _onMenuSelected(auth, v),
      itemBuilder: (_) => [
        for (final conn in auth.connections)
          PopupMenuItem<String>(
            value: conn.profile.id,
            height: 44,
            child: Row(
              children: [
                if (conn.profile.id == effectiveId)
                  Icon(Icons.check, size: 18, color: c.primary)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: AppSpacing.two),
                Expanded(
                  child: ThemedText.body(
                    conn.profile.name,
                    color: c.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: _kAddManagerMenu,
          child: Row(
            children: [
              Icon(Icons.add, size: 18, color: c.primary),
              const SizedBox(width: AppSpacing.two),
              ThemedText.body(AppStrings.of.managersAdd, color: c.primary),
            ],
          ),
        ),
        if (effectiveId != null)
          PopupMenuItem<String>(
            value: _kDeleteManagerMenu,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: c.danger),
                const SizedBox(width: AppSpacing.two),
                ThemedText.body(AppStrings.of.managersRemove, color: c.danger),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.one),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ThemedText.title(
                current?.profile.name ?? AppStrings.of.managersTitle,
                color: c.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 20, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  void _onMenuSelected(AuthProvider auth, String value) {
    switch (value) {
      case _kAddManagerMenu:
        _showAddManager(auth);
        return;
      case _kDeleteManagerMenu:
        _deleteCurrentManager(auth);
        return;
      default:
        _switchTo(auth, value);
    }
  }

  void _switchTo(AuthProvider auth, String id) {
    if (id == _selectedId) return;
    final conn = auth.connectionFor(id);
    setState(() {
      _selectedId = id;
      _agents = List.from(conn?.agents ?? []);
      _error = null;
    });
    _loadAgents();
  }

  Future<void> _deleteCurrentManager(AuthProvider auth) async {
    final id = _selectedId;
    if (id == null) return;
    final conn = auth.connectionFor(id);
    if (conn == null) return;
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: AppStrings.of.managersRemoveTitle(conn.profile.name),
      showRobot: true,
      content: ThemedText.small(AppStrings.of.managersRemoveDesc),
      confirmText: AppStrings.of.managersRemove,
      confirmIsDanger: true,
    );
    if (confirmed == true && mounted) {
      await auth.removeManager(id);
      if (!mounted) return;
      // 选中在 build 里自动回退到第一个并刷新。
      setState(() => _selectedId = null);
    }
  }

  // ── Agent 列表（当前 manager） ────────────────────────────────────

  Widget _buildAgentList(ManagerConnection? conn) {
    if (conn == null) return const SizedBox.shrink();
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError(conn);
    }
    if (_agents.isEmpty) {
      return _buildEmpty(conn);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.two,
        AppSpacing.two,
        AppSpacing.two,
        AppSpacing.four,
      ),
      itemCount: _agents.length,
      itemBuilder: (_, index) {
        final agent = _agents[index];
        return context.appComponents.buildAgentCard(
          context,
          AgentCardData(
            agent: agent,
            onTap: () =>
                context.push('/profile/${conn.profile.id}/agent/${agent.id}'),
            onEdit: () => _showEditAgent(conn, agent),
            onDelete: () => _deleteAgent(conn, agent),
          ),
        );
      },
    );
  }

  Widget _buildError(ManagerConnection conn) {
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: _loadAgents,
                  child: Text(AppStrings.of.agentRetry),
                ),
                const SizedBox(width: AppSpacing.two),
                TextButton(
                  onPressed: () => _showReconnectDialog(conn),
                  child: Text(AppStrings.of.reconnectLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ManagerConnection conn) {
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
              onPressed: () => _showAddAgent(conn),
              icon: const Icon(Icons.add, size: 20),
              label: Text(AppStrings.of.agentAddTooltip),
            ),
          ],
        ),
      ),
    );
  }

  // ── 数据加载 ─────────────────────────────────────────────────────

  Future<void> _loadAgents() async {
    final auth = context.read<AuthProvider>();
    final id = _selectedId;
    if (id == null) return;
    final conn = auth.connectionFor(id);
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
        _error = conn.status == ConnectionStatus.connected
            ? null
            : (conn.error ?? AppStrings.of.statusDisconnected);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// 静默轮询 agent 状态：不翻转连接状态、不闪 loading，失败保留上次列表。
  Future<void> _loadSilent() async {
    final auth = context.read<AuthProvider>();
    final id = _selectedId;
    if (id == null) return;
    final conn = auth.connectionFor(id);
    if (conn == null || conn.status != ConnectionStatus.connected) return;
    try {
      await conn.refreshAgents();
      if (!mounted) return;
      setState(() {
        _agents = List.from(conn.agents);
        _error = null;
      });
    } catch (_) {
      // 瞬时失败忽略，下次轮询再试。
    }
  }

  // ── Add / Edit / Delete agent ────────────────────────────────────

  Future<void> _showAddAgent(ManagerConnection conn) async {
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
      await _loadAgents();
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

  Future<void> _showEditAgent(ManagerConnection conn, AgentInfo agent) async {
    final formData = await context.push<AddAgentFormData>(
      '/profile/${conn.profile.id}/add-agent',
      extra: AddAgentPageArgs(
        agentId: agent.id,
        initialName: agent.name,
        initialUrl: agent.baseUrl,
      ),
    );
    if (formData == null || !mounted) return;
    try {
      await conn.transport.updateAgent(
        conn.managerRef,
        agent.id,
        name: formData.name,
        baseUrl: formData.url,
        token: formData.token.isEmpty ? null : formData.token,
      );
      await _loadAgents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ThemedText.small(
              AppStrings.of.agentUpdated(formData.name),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final c = context.appColors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of.agentUpdateFailed(e.toString())),
            backgroundColor: c.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteAgent(ManagerConnection conn, AgentInfo agent) async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: AppStrings.of.agentRemoveTitle(agent.name),
      showRobot: true,
      content: ThemedText.small(AppStrings.of.agentRemoveDesc),
      confirmText: AppStrings.of.removeLabel,
      confirmIsDanger: true,
    );
    if (confirmed != true || !mounted) return;
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

  // ── 重连 ─────────────────────────────────────────────────────────

  Future<void> _showReconnectDialog(ManagerConnection conn) async {
    final formKey = GlobalKey<ReconnectFormState>();

    final result = await NeonDialog.show<String?>(
      context: context,
      title: '${AppStrings.of.reconnectLabel} ${conn.profile.name}',
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

    if (result != null && mounted) {
      final auth = context.read<AuthProvider>();
      debugPrint('[Reconnect] token received, connecting…');
      final ok = await auth.reconnect(conn.profile.id, result);
      debugPrint('[Reconnect] ok=$ok');
      if (mounted) {
        final c = context.appColors;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ThemedText.small(
                '${conn.profile.name} ${AppStrings.of.managersReconnected}',
              ),
            ),
          );
          _loadAgents();
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

  // ── Add Manager dialog ────────────────────────────────────────────

  Future<void> _showAddManager(AuthProvider auth) async {
    final initialName = AppStrings.of.managersDefaultName(
      auth.connections.length + 1,
    );
    final formData = await context.push<AddManagerFormData>(
      '/add-manager',
      extra: initialName,
    );
    if (formData == null || !mounted) return;
    if (formData.url.isEmpty || formData.token.isEmpty) return;
    try {
      final added = await auth.login(
        formData.url,
        formData.token,
        name: formData.name.isNotEmpty ? formData.name : null,
      );
      // 添加后切到新 manager。
      if (mounted) {
        setState(() => _selectedId = added.profile.id);
        _loadAgents();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: ThemedText.small(AppStrings.of.managersAdded)),
        );
      }
    } catch (e) {
      if (mounted) {
        final c = context.appColors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: c.danger),
        );
      }
    }
  }

  // ── Welcome state (no profiles) ─────────────────────────────────────

  Widget _buildWelcomeEmpty(AuthProvider auth) {
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
              onPressed: () => _showAddManager(auth),
              icon: const Icon(Icons.add, size: 20),
              label: Text(AppStrings.of.managersAdd),
            ),
          ],
        ),
      ),
    );
  }
}
