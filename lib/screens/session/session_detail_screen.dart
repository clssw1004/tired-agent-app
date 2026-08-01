import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/terminal_themes.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/protocol/sse_client.dart';
import 'package:tired_agent_app/services/session_api_service.dart';
import 'package:tired_agent_app/widgets/shell/pty_session_view.dart';

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
  Timer? _statusPoller;

  /// Cached from PtySessionView for AppBar display.
  SseConnectionStatus _ptyStatus = SseConnectionStatus.disconnected;

  /// Built once the connection becomes available.
  SessionApiService? _api;

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
      _api = SessionApiService(conn: conn, agentId: widget.agentId);
      final session = await _api!.getSession(widget.sessionId);
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

  // ── Lifecycle / Reconnect ──────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _conn != null) {
      // 切前台时直接重建 SSE 连接。token 由 main.dart 的 refreshAllSessions
      // 全局刷新，SSE 的 tokenProvider 按需获取最新 token，无需在此 ensureFreshSession。
      _reconnect();
    }
  }

  /// 重新建立 PTY 的 SSE 连接，完成后刷新 session 元信息。
  void _reconnect() {
    _ptyKey.currentState?.reconnect();
    _refreshSession();
  }

  /// 从服务端重新拉取 session 元信息（状态、label 等），更新 UI。
  Future<void> _refreshSession() async {
    if (!mounted || _conn == null) return;
    try {
      final session = await _api!.getSession(widget.sessionId);
      if (mounted) {
        setState(() => _session = session);
      }
    } catch (_) {
      // 静默失败——SSE 流数据不受影响。
    }
  }

  // ── AppBar helpers ───────────────────────────────────────────────

  Widget _appBarStatusDot() {
    final c = context.appColors;
    final Color color;
    switch (_ptyStatus) {
      case SseConnectionStatus.connected:
        color = c.success;
      case SseConnectionStatus.reconnecting:
        color = c.warning;
      case SseConnectionStatus.disconnected:
        color = c.textSecondary;
    }

    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 6)],
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
    final title =
        _session?.label ?? _session?.cmd ?? AppStrings.of.sessionTitle;
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _appBarStatusDot(),
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
          if (_ptyStatus != SseConnectionStatus.connected)
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
          ? Center(child: context.appComponents.buildLoading(context))
          : _error != null
          ? Center(child: ThemedText.small(_error!, color: c.danger))
          : _session != null && _conn != null
          ? PtySessionView(
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
