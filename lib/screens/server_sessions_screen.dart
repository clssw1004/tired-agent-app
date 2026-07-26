import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/providers/pinned_session_provider.dart';
import 'package:tired_agent_app/theme.dart';
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

  // ── Pin / unpin ────────────────────────────────────────────────────

  Future<void> _onPin(Session session) async {
    final pinService = context.read<PinnedSessionProvider>();
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn == null) return;

    final agentName = conn.agents
        .where((a) => a.id == widget.agentId)
        .firstOrNull
        ?.name;

    if (pinService.isPinned(
      profileId: widget.profileId,
      agentId: widget.agentId,
      sessionId: session.id,
    )) {
      // Already pinned → unpin.
      await pinService.unpinBySession(
        profileId: widget.profileId,
        agentId: widget.agentId,
        sessionId: session.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ThemedText.small('Session unpinned'),
            backgroundColor: AppColors.backgroundElement,
          ),
        );
      }
    } else {
      // Not pinned → show label dialog then pin.
      final formKey = GlobalKey<_PinLabelFormState>();
      final result = await NeonDialog.show<String?>(
        context: context,
        title: 'Pin Session',
        showRobot: true,
        maxWidth: 400,
        content: _PinLabelForm(
          key: formKey,
          initialLabel: session.label ?? session.cmd,
        ),
        actions: [
          NeonDialogAction(
            label: 'Cancel',
            onPressed: (ctx) => Navigator.of(ctx).pop(null),
          ),
          NeonDialogAction(
            label: 'Pin',
            isPrimary: true,
            onPressed: (ctx) {
              final label = formKey.currentState?.label;
              if (label != null && label.isNotEmpty) {
                Navigator.of(ctx).pop(label);
              }
            },
          ),
        ],
      );
      if (result == null || !mounted) return;
      await pinService.pin(
        profileId: widget.profileId,
        profileName: conn.profile.name,
        agentId: widget.agentId,
        agentName: agentName ?? widget.agentId,
        sessionId: session.id,
        sessionLabel: result,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ThemedText.small('Session pinned'),
            backgroundColor: AppColors.backgroundElement,
          ),
        );
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}s';
    if (s < 3600000) return '${s ~/ 60000}m';
    if (s < 86400000) return '${s ~/ 3600000}h';
    return '${s ~/ 86400000}d';
  }

  List<Session> get _visible {
    if (_statusFilter == null) return _sessions;
    return _sessions.where((s) => s.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    final agentName = _agentName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title(agentName ?? widget.agentId),
        actions: [
          // Status filter
          PopupMenuButton<_StatusFilter>(
            icon: const Icon(Icons.filter_list, color: AppColors.textSecondary),
            onSelected: (f) => setState(() => _statusFilter = f),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(
                value: SessionStatus.running,
                child: Text('Running'),
              ),
              const PopupMenuItem(
                value: SessionStatus.exited,
                child: Text('Exited'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'New Session',
            onPressed: () => context.push(
              '/profile/${widget.profileId}/agent/${widget.agentId}/create',
            ),
          ),
        ],
      ),
      body: _buildContent(conn),
    );
  }

  Widget _buildContent(ManagerConnection? conn) {
    if (conn == null) {
      return Center(child: ThemedText.small('Manager not found'));
    }

    if (_loading && _sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ── Prune bar ─────────────────────────────────────────────────
        if (_pruneInfo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.four,
              vertical: AppSpacing.two,
            ),
            color: AppColors.primary.withAlpha(15),
            child: Row(
              children: [
                const Icon(
                  Icons.cleaning_services,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.one),
                ThemedText.small(
                  'Pruned $_pruneInfo session(s)',
                  color: AppColors.primary,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _pruneInfo = null),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

        // ── Error banner ──────────────────────────────────────────────
        if (_error != null)
          Container(
            width: double.infinity,
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
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),

        // ── Header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.four,
            AppSpacing.two,
            AppSpacing.four,
            0,
          ),
          child: Row(
            children: [
              ThemedText.label(
                '${_visible.length} session(s)',
                color: AppColors.textSecondary,
              ),
              const Spacer(),
              GestureDetector(
                onTap:
                    (_sessions
                            .where((s) => s.status != SessionStatus.exited)
                            .length) >
                        0
                    ? _requestPrune
                    : null,
                child: ThemedText.small(
                  'Prune',
                  color:
                      (_sessions
                              .where((s) => s.status != SessionStatus.exited)
                              .length) >
                          0
                      ? AppColors.textSecondary
                      : AppColors.textSecondary.withAlpha(60),
                ),
              ),
              const SizedBox(width: AppSpacing.two),
              ThemedText.small(
                _loading ? '⟳' : '⟳ ${_timeSince(_lastLoaded)}',
                color: AppColors.textSecondary,
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
                    final pinService = context.watch<PinnedSessionProvider>();
                    return SessionCard(
                      session: session,
                      isPinned: pinService.isPinned(
                        profileId: widget.profileId,
                        agentId: widget.agentId,
                        sessionId: session.id,
                      ),
                      onPin: () => _onPin(session),
                      onKill: session.status != SessionStatus.exited
                          ? () => _requestKill(session.id)
                          : null,
                      onDelete: session.status == SessionStatus.exited
                          ? () => _requestDelete(session.id)
                          : null,
                      onTap: () => context.push(
                        '/session/${widget.profileId}/${widget.agentId}/${session.id}',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Pin label form — owns its TextEditingController to avoid
// `_dependents.isEmpty` crash on dialog close.
// ═══════════════════════════════════════════════════════════════════════

class _PinLabelForm extends StatefulWidget {
  final String initialLabel;
  const _PinLabelForm({super.key, required this.initialLabel});

  @override
  _PinLabelFormState createState() => _PinLabelFormState();
}

class _PinLabelFormState extends State<_PinLabelForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get label {
    final t = _controller.text.trim();
    return t.isNotEmpty ? t : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Display label'),
        autofocus: true,
      ),
    );
  }
}
