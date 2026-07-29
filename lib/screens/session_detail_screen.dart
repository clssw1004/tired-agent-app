import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/terminal_themes.dart';
import 'package:tired_agent_app/widgets/claude_chat_view.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/neon_loading.dart';
import 'package:tired_agent_app/widgets/pty_session_view.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';
import 'package:tired_agent_app/utils/app_strings.dart';

class SessionDetailScreen extends StatefulWidget {
  final String profileId;
  final String agentId;
  final String sessionId;

  const SessionDetailScreen({
    super.key,
    required this.profileId,
    required this.agentId,
    required this.sessionId,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with WidgetsBindingObserver {
  Session? _session;
  ManagerConnection? _conn;
  String? _error;
  bool _loading = true;

  final GlobalKey<PtySessionViewState> _ptyKey = GlobalKey();
  final GlobalKey<ClaudeChatViewState> _chatKey = GlobalKey();
  Timer? _statusPoller;

  /// Cached from PtySessionView for AppBar display.
  PtyConnectionStatus _ptyStatus = PtyConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    // Poll PTY status for AppBar indicator (every second).
    _statusPoller = Timer.periodic(const Duration(seconds: 1), (_) {
      final status = _ptyKey.currentState?.connectionStatus;
      if (status != null && status != _ptyStatus) {
        setState(() => _ptyStatus = status);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusPoller?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) {
        setState(() {
          _error = AppStrings.of.sessionNotConnected;
          _loading = false;
        });
        return;
      }
      await conn.ensureFreshSession();
      final mgrRef = ServerRef(
        id: '__manager__',
        name: conn.profile.name,
        baseUrl: conn.profile.baseUrl,
        token: conn.profile.sessionToken!,
      );
      final session = await conn.transport.getSession(
        mgrRef,
        widget.sessionId,
        agentId: widget.agentId,
      );
      if (mounted) {
        setState(() {
          _session = session;
          _conn = conn;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// Build manager-level ref for kill/delete API calls.
  ServerRef _mgrRef() => ServerRef(
    id: '__manager__',
    name: _conn!.profile.name,
    baseUrl: _conn!.profile.baseUrl,
    token: _conn!.profile.sessionToken!,
  );

  // ── Lifecycle / Reconnect ──────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _conn != null) {
      // 切前台时直接重建 SSE 连接。token 由 main.dart 的 refreshAllSessions
      // 全局刷新，SSE 的 tokenProvider 按需获取最新 token，无需在此 ensureFreshSession。
      _reconnect();
    }
  }

  /// 重新建立 SSE 连接（PTY 或 Chat），完成后刷新 session 元信息。
  void _reconnect() {
    if (_session?.mode == SessionMode.persistent) {
      _chatKey.currentState?.reconnect();
    } else {
      _ptyKey.currentState?.reconnect();
    }
    _refreshSession();
  }

  /// 从服务端重新拉取 session 元信息（状态、label 等），更新 UI。
  Future<void> _refreshSession() async {
    if (!mounted || _conn == null) return;
    try {
      final session = await _conn!.transport.getSession(
        _mgrRef(),
        widget.sessionId,
        agentId: widget.agentId,
      );
      if (mounted) {
        setState(() => _session = session);
      }
    } catch (_) {
      // 静默失败——SSE 流数据不受影响。
    }
  }

  // ── Kill / Delete (persistent sessions) ──────────────────────────

  Future<void> _requestKill() async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: AppStrings.of.sessionKillTitle,
      showRobot: true,
      content: ThemedText.small(
        AppStrings.of.sessionKillDesc,
      ),
      confirmText: AppStrings.of.sessionKillBtn,
      confirmIsDanger: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await _conn!.transport.killSession(
        _mgrRef(),
        widget.sessionId,
        agentId: widget.agentId,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        final c = context.appColors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of.sessionKillFailed(e.toString())),
            backgroundColor: c.danger,
          ),
        );
      }
    }
  }

  Future<void> _requestDelete() async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: AppStrings.of.sessionDeleteTitle,
      showRobot: true,
      content: ThemedText.small(
        AppStrings.of.sessionDeleteDesc,
      ),
      confirmText: AppStrings.of.sessionDeleteBtn,
      confirmIsDanger: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await _conn!.transport.deleteSession(
        _mgrRef(),
        widget.sessionId,
        agentId: widget.agentId,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        final c = context.appColors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of.sessionDeleteFailed(e.toString())),
            backgroundColor: c.danger,
          ),
        );
      }
    }
  }

  String _generateLabel() {
    final chars = 'abcdefghijkmnpqrstuvwxyz23456789';
    final rnd = List.generate(8, (_) => chars[Random().nextInt(chars.length)]).join();
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    final stamp = '${now.year}${pad(now.month)}${pad(now.day)}T${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';
    return '${rnd}_$stamp';
  }

  Future<void> _requestResume() async {
    if (_session == null || _conn == null) return;

    final newLabel = _session!.label != null
        ? '${_session!.label}-r'
        : _generateLabel();

    // Resume value priority: claudeSessionId > extra.claudeName > label
    final resumeValue = _session!.claudeSessionId ??
        (_session!.extra?['claudeName'] as String?) ??
        _session!.label;

    final spec = SessionSpec(
      cmd: 'claude',
      args: ['--name', newLabel, '--resume', resumeValue ?? _session!.id],
      cwd: _session!.cwd,
      cols: _session!.cols,
      rows: _session!.rows,
      label: newLabel,
      mode: SessionMode.persistent,
      extra: {'claudeName': newLabel},
    );

    try {
      final newSession = await _conn!.transport.createSession(
        _mgrRef(), spec, agentId: widget.agentId,
      );
      if (mounted) {
        context.replace('/session/${widget.profileId}/${widget.agentId}/${newSession.id}');
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

  // ── AppBar helpers ───────────────────────────────────────────────

  Widget _appBarStatusDot() {
    final c = context.appColors;
    final Color color;
    switch (_ptyStatus) {
      case PtyConnectionStatus.connected:
        color = c.success;
      case PtyConnectionStatus.reconnecting:
        color = c.warning;
      case PtyConnectionStatus.disconnected:
        color = c.textSecondary;
    }

    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withAlpha(100), blurRadius: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch terminal theme preset so the screen rebuilds when the user changes
    // theme in settings and navigates back.
    context.select<AppSettingsProvider, TerminalThemePreset>(
      (p) => p.terminalThemePreset,
    );
    final isPersistent = _session?.mode == SessionMode.persistent;
    final isClaude = _session?.cmd == 'claude';
    final sessionStatus = _session?.status;
    final canResume = sessionStatus == SessionStatus.exited && isClaude &&
        (_session!.claudeSessionId != null ||
         _session!.extra?['claudeName'] != null ||
         _session!.label != null);
    final title = _session?.label ?? _session?.cmd ?? AppStrings.of.sessionTitle;
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status dot — meaningful for PTY, hidden for persistent.
            if (!isPersistent) _appBarStatusDot(),
            Flexible(
              child: ThemedText(
                title,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Persistent session: kill / delete
          if (isPersistent && sessionStatus != SessionStatus.exited)
            IconButton(
              icon: Icon(Icons.stop_circle_outlined, color: c.danger),
              tooltip: AppStrings.of.sessionKillTooltip,
              onPressed: _requestKill,
            ),
          if (canResume)
            IconButton(
              icon: Icon(Icons.replay, color: c.success),
              tooltip: AppStrings.of.sessionResumeTooltip,
              onPressed: _requestResume,
            ),
          if (isPersistent && sessionStatus == SessionStatus.exited)
            IconButton(
              icon: Icon(Icons.delete_outline, color: c.textSecondary),
              tooltip: AppStrings.of.sessionDeleteTooltip,
              onPressed: _requestDelete,
            ),
          // PTY: reconnect
          if (!isPersistent && _ptyStatus != PtyConnectionStatus.connected)
            IconButton(
              icon: Icon(Icons.refresh, color: c.primary),
              tooltip: AppStrings.of.sessionReconnectTooltip,
              onPressed: _reconnect,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: _loading
          ? Center(child: NeonLoading())
          : _error != null
              ? Center(
                  child: ThemedText.small(_error!, color: c.danger),
                )
              : _session != null && _conn != null
                  ? isPersistent
                      ? ClaudeChatView(
                          key: _chatKey,
                          serverRef: _conn!.managerRef,
                          agentId: widget.agentId,
                          session: _session!,
                          tokenProvider: () async => _conn!.profile.sessionToken,
                        )
                      : PtySessionView(
                          key: _ptyKey,
                          serverRef: _conn!.managerRef,
                          agentId: widget.agentId,
                          session: _session!,
                          tokenProvider: () async => _conn!.profile.sessionToken,
                        )
                  : Center(child: ThemedText.small(AppStrings.of.sessionNotFound)),
    );
  }
}
