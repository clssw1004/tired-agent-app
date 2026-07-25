import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/neon_card.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/session_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

typedef _StatusFilter = SessionStatus?;

class ServerSessionsScreen extends StatefulWidget {
  final String profileId;
  final String agentId;

  const ServerSessionsScreen({
    super.key,
    required this.profileId,
    required this.agentId,
  });

  @override
  State<ServerSessionsScreen> createState() => _ServerSessionsScreenState();
}

class _ServerSessionsScreenState extends State<ServerSessionsScreen> {
  List<Session> _sessions = [];
  bool _loading = true;
  String? _error;
  _StatusFilter? _statusFilter;
  int _lastLoaded = 0;
  Timer? _autoRefreshTimer;
  Timer? _tickTimer;

  int? _pruneInfo;

  @override
  void initState() {
    super.initState();
    _load();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadSilent(),
    );
    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  String? get _agentName {
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    return conn?.agents.where((a) => a.id == widget.agentId).firstOrNull?.name;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _loadSilent();
    setState(() => _loading = false);
  }

  Future<void> _loadSilent() async {
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) {
        if (mounted) setState(() => _error = 'Not connected');
        return;
      }
      await conn.ensureFreshSession();
      final mgrRef = ServerRef(
        id: '__manager__',
        name: conn.profile.name,
        baseUrl: conn.profile.baseUrl,
        token: conn.profile.sessionToken!,
      );
      final sessions = await conn.transport.listSessions(
        mgrRef,
        agentId: widget.agentId,
      );
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _error = null;
          _lastLoaded = DateTime.now().millisecondsSinceEpoch;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  // ── Actions ────────────────────────────────────────────────────────

  void _requestKill(String sessionId) {
    _showConfirm(
      title: 'Kill this session?',
      desc: 'The running process will be terminated and removed from the list.',
      onConfirm: () async {
        final auth = context.read<AuthProvider>();
        final conn = auth.connectionFor(widget.profileId);
        if (conn == null) return;
        await conn.ensureFreshSession();
        final mgrRef = ServerRef(
          id: '__manager__',
          name: conn.profile.name,
          baseUrl: conn.profile.baseUrl,
          token: conn.profile.sessionToken!,
        );
        await conn.transport.killSession(
          mgrRef,
          sessionId,
          agentId: widget.agentId,
        );
        await _load();
      },
    );
  }

  void _requestDelete(String sessionId) {
    _showConfirm(
      title: 'Delete session log?',
      desc:
          'Removes the database row and the on-disk output log. Cannot be undone.',
      onConfirm: () async {
        final auth = context.read<AuthProvider>();
        final conn = auth.connectionFor(widget.profileId);
        if (conn == null) return;
        await conn.ensureFreshSession();
        final mgrRef = ServerRef(
          id: '__manager__',
          name: conn.profile.name,
          baseUrl: conn.profile.baseUrl,
          token: conn.profile.sessionToken!,
        );
        await conn.transport.deleteSession(
          mgrRef,
          sessionId,
          agentId: widget.agentId,
        );
        await _load();
      },
    );
  }

  void _requestPrune() {
    _showConfirm(
      title: 'Clean stale sessions?',
      desc:
          'Drops all sessions that have been inactive for more than 24 hours.',
      onConfirm: () async {
        final auth = context.read<AuthProvider>();
        final conn = auth.connectionFor(widget.profileId);
        if (conn == null) return;
        await conn.ensureFreshSession();
        final mgrRef = ServerRef(
          id: '__manager__',
          name: conn.profile.name,
          baseUrl: conn.profile.baseUrl,
          token: conn.profile.sessionToken!,
        );
        final result = await conn.transport.pruneSessions(
          mgrRef,
          agentId: widget.agentId,
        );
        setState(() => _pruneInfo = result['removed'] as int?);
        await _load();
      },
    );
  }

  Future<void> _showConfirm({
    required String title,
    required String desc,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: title,
      showRobot: true,
      content: ThemedText.small(desc),
      confirmText: 'Confirm',
      confirmIsDanger: true,
    );
    if (confirmed == true && mounted) {
      try {
        await onConfirm();
      } catch (e) {
        if (mounted) {
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

  // ── Helpers ─────────────────────────────────────────────────────────

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}s ago';
    if (s < 3600000) return '${s ~/ 60000}m ago';
    if (s < 86400000) return '${s ~/ 3600000}h ago';
    return '${s ~/ 86400000}d ago';
  }

  int _count(SessionStatus? status) {
    if (status == null) return _sessions.length;
    return _sessions.where((s) => s.status == status).length;
  }

  List<Session> get _visible {
    if (_statusFilter == null) return _sessions;
    return _sessions.where((s) => s.status == _statusFilter).toList();
  }

  static const _filters = <_StatusFilter>[
    null,
    SessionStatus.starting,
    SessionStatus.running,
    SessionStatus.exited,
  ];
  static const _filterLabels = ['all', 'starting', 'running', 'exited'];

  @override
  Widget build(BuildContext context) {
    final exitedCount = _count(SessionStatus.exited);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title(_agentName ?? 'Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => context.push(
              '/profile/${widget.profileId}/agent/${widget.agentId}/create',
            ),
            tooltip: 'New Session',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
      ),
      body: Column(
        children: [
          // ── Toolbar: filters + refresh + prune ────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.four,
              vertical: AppSpacing.two,
            ),
            child: Row(
              children: [
                ...List.generate(_filters.length, (i) {
                  final f = _filters[i];
                  final active = _statusFilter == f;
                  final cnt = _count(f);
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.one),
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.two,
                          vertical: AppSpacing.one,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.surfaceAlt
                              : AppColors.backgroundElement,
                          borderRadius: BorderRadius.circular(AppSpacing.three),
                          border: Border.all(
                            color: active
                                ? AppColors.primary.withAlpha(80)
                                : Colors.transparent,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ThemedText.small(
                              _filterLabels[i],
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            if (cnt > 0) ...[
                              const SizedBox(width: 4),
                              ThemedText.small(
                                '$cnt',
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                if (_lastLoaded > 0)
                  ThemedText.small(
                    _loading ? '⟳' : '⟳ ${_timeSince(_lastLoaded)}',
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),

          // ── Error / Prune info ─────────────────────────────────────
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.four,
                vertical: AppSpacing.one,
              ),
              padding: const EdgeInsets.all(AppSpacing.three),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.two),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ThemedText.small(_error!, color: AppColors.danger),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _error = null),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.danger,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

          if (_pruneInfo != null)
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.four,
                vertical: AppSpacing.one,
              ),
              padding: const EdgeInsets.all(AppSpacing.three),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(AppSpacing.two),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ThemedText.small(
                      'Cleaned up $_pruneInfo stale sessions.',
                      color: AppColors.success,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _pruneInfo = null),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

          // ── Session list ────────────────────────────────────────────
          Expanded(
            child: _visible.isEmpty
                ? Center(
                    child: ThemedText.small(
                      _loading ? 'Loading…' : 'No sessions',
                      color: AppColors.textSecondary,
                    ),
                  )
                : ListView.builder(
                    itemCount: _visible.length,
                    itemBuilder: (context, index) {
                      final session = _visible[index];
                      return SessionCard(
                        session: session,
                        onTap: () => context.push(
                          '/session/${widget.profileId}/${widget.agentId}/${session.id}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
