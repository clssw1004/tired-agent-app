import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/claude_chat_view.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/neon_loading.dart';
import 'package:tired_agent_app/widgets/pty_session_view.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

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

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Session? _session;
  ManagerConnection? _conn;
  String? _error;
  bool _loading = true;

  final GlobalKey<PtySessionViewState> _ptyKey = GlobalKey();
  Timer? _statusPoller;

  /// Cached from PtySessionView for AppBar display.
  PtyConnectionStatus _ptyStatus = PtyConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
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
    _statusPoller?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) {
        setState(() {
          _error = 'Manager not connected';
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

  /// Manually trigger PTY reconnection.
  void _reconnect() {
    _ptyKey.currentState?.reconnect();
  }

  // ── Kill / Delete (persistent sessions) ──────────────────────────

  Future<void> _requestKill() async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: 'Kill this session?',
      showRobot: true,
      content: ThemedText.small(
        'The running process will be terminated.',
      ),
      confirmText: 'Kill',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kill failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _requestDelete() async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: 'Delete session log?',
      showRobot: true,
      content: ThemedText.small(
        'Removes the database row and the on-disk output log. '
        'Cannot be undone.',
      ),
      confirmText: 'Delete',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // ── AppBar helpers ───────────────────────────────────────────────

  Widget _appBarStatusDot() {
    final Color color;
    switch (_ptyStatus) {
      case PtyConnectionStatus.connected:
        color = AppColors.success;
      case PtyConnectionStatus.reconnecting:
        color = AppColors.warning;
      case PtyConnectionStatus.disconnected:
        color = AppColors.textSecondary;
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
    final isPersistent = _session?.mode == SessionMode.persistent;
    final sessionStatus = _session?.status;
    final title = _session?.label ?? _session?.cmd ?? 'Session';

    return Scaffold(
      backgroundColor: AppColors.background,
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
          if (isPersistent && sessionStatus == SessionStatus.running)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined,
                  color: AppColors.danger),
              tooltip: 'Kill session',
              onPressed: _requestKill,
            ),
          if (isPersistent && sessionStatus == SessionStatus.exited)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.textSecondary),
              tooltip: 'Delete session',
              onPressed: _requestDelete,
            ),
          // PTY: reconnect
          if (!isPersistent && _ptyStatus != PtyConnectionStatus.connected)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              tooltip: 'Reconnect',
              onPressed: _reconnect,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
      ),
      body: _loading
          ? const Center(child: NeonLoading())
          : _error != null
              ? Center(
                  child: ThemedText.small(_error!, color: AppColors.danger),
                )
              : _session != null && _conn != null
                  ? isPersistent
                      ? ClaudeChatView(
                          serverRef: _conn!.managerRef,
                          agentId: widget.agentId,
                          session: _session!,
                        )
                      : PtySessionView(
                          key: _ptyKey,
                          serverRef: _conn!.managerRef,
                          agentId: widget.agentId,
                          session: _session!,
                        )
                  : Center(child: ThemedText.small('Session not found')),
    );
  }
}
