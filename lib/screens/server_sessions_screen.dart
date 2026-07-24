import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/neon_card.dart';
import 'package:tired_agent_app/widgets/session_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

typedef _StatusFilter = SessionStatus?;

class ServerSessionsScreen extends StatefulWidget {
  final String serverId;

  const ServerSessionsScreen({super.key, required this.serverId});

  @override
  State<ServerSessionsScreen> createState() => _ServerSessionsScreenState();
}

class _ServerSessionsScreenState extends State<ServerSessionsScreen> {
  List<Session> _sessions = [];
  bool _loading = true;
  String? _error;
  ServerRef? _ref;
  _StatusFilter _statusFilter = null;
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
    final agents = context.read<AuthProvider>().agents;
    return agents.where((a) => a.id == widget.serverId).firstOrNull?.name;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _loadSilent();
    setState(() => _loading = false);
  }

  Future<void> _loadSilent() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.ensureFreshSession();
      _ref = auth.managerRef;
      if (_ref == null) {
        if (mounted) setState(() => _error = 'Not authenticated');
        return;
      }
      final sessions = await auth.authService.transport.listSessions(
        _ref!,
        agentId: widget.serverId,
      );
      if (mounted)
        setState(() {
          _sessions = sessions;
          _error = null;
          _lastLoaded = DateTime.now().millisecondsSinceEpoch;
        });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  // ── Actions ────────────────────────────────────────────────────────

  void _requestKill(String sessionId) {
    _showConfirm(
      icon: '⚠️',
      title: 'Kill this session?',
      desc: 'The running process will be terminated and removed from the list.',
      onConfirm: () async {
        if (_ref == null) return;
        await context.read<AuthProvider>().authService.transport.killSession(
          _ref!,
          sessionId,
          agentId: widget.serverId,
        );
        await _load();
      },
    );
  }

  void _requestDelete(String sessionId) {
    _showConfirm(
      icon: '🗑️',
      title: 'Delete session log?',
      desc:
          'Removes the database row and the on-disk output log. Cannot be undone.',
      onConfirm: () async {
        if (_ref == null) return;
        await context.read<AuthProvider>().authService.transport.deleteSession(
          _ref!,
          sessionId,
          agentId: widget.serverId,
        );
        await _load();
      },
    );
  }

  void _requestPrune() {
    _showConfirm(
      icon: '🧹',
      title: 'Clean stale sessions?',
      desc:
          'Drops all sessions that have been inactive for more than 24 hours.',
      onConfirm: () async {
        if (_ref == null) return;
        final result = await context
            .read<AuthProvider>()
            .authService
            .transport
            .pruneSessions(_ref!, agentId: widget.serverId);
        setState(() => _pruneInfo = result['removed'] as int?);
        await _load();
      },
    );
  }

  Future<void> _showConfirm({
    required String icon,
    required String title,
    required String desc,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElement,
        title: Row(
          children: [
            ThemedText(icon, fontSize: 20),
            const SizedBox(width: AppSpacing.two),
            ThemedText.title(title),
          ],
        ),
        content: ThemedText.small(desc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: ThemedText.body('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              foregroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.two),
                side: BorderSide(
                  color: AppColors.danger.withAlpha(80),
                  width: 0.5,
                ),
              ),
            ),
            child: ThemedText.body('Confirm', color: AppColors.danger),
          ),
        ],
      ),
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
            onPressed: () =>
                context.push('/server/${widget.serverId}/create-session'),
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

          // ── Clean zombies button ───────────────────────────────────
          if (_sessions.isNotEmpty && exitedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : _requestPrune,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.backgroundElement),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.one,
                    ),
                  ),
                  child: ThemedText.small(
                    'Clean zombies ($exitedCount) — removes sessions >24h old',
                  ),
                ),
              ),
            ),

          // ── Session list ───────────────────────────────────────────
          Expanded(
            child: _loading && _sessions.isEmpty
                ? _buildSkeleton()
                : _visible.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.two,
                        bottom: AppSpacing.six,
                      ),
                      itemCount: _visible.length,
                      itemBuilder: (context, index) {
                        final session = _visible[index];
                        return SessionCard(
                          session: session,
                          onTap: () => context.push(
                            '/session/${widget.serverId}/${session.id}',
                          ),
                          onKill: session.status != SessionStatus.exited
                              ? () => _requestKill(session.id)
                              : null,
                          onDelete: session.status == SessionStatus.exited
                              ? () => _requestDelete(session.id)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),

      // ── Confirmation dialog ────────────────────────────────────────
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.two),
      itemCount: 5,
      itemBuilder: (_, __) => NeonCard(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.four,
          vertical: AppSpacing.one,
        ),
        child: SizedBox(
          height: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSpacing.one),
                ),
              ),
              const SizedBox(height: AppSpacing.two),
              Container(
                width: 200,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSpacing.one),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ThemedText('⌨️', fontSize: 48),
          const SizedBox(height: AppSpacing.four),
          ThemedText.body(
            _sessions.isEmpty ? 'No sessions' : 'No matching sessions',
          ),
          const SizedBox(height: AppSpacing.two),
          ThemedText.small(
            _sessions.isEmpty
                ? 'Create a session to start a command on this agent.'
                : 'Try a different status filter.',
          ),
        ],
      ),
    );
  }
}
