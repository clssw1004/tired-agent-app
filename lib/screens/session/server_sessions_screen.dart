import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/providers/pinned_session_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/neon_dialog.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/forms/label_form_field.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';
import 'package:tired_agent_app/services/session_api_service.dart';

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

  /// Convenience: build [SessionApiService] from the current connection.
  SessionApiService? get _api {
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn == null || conn.profile.sessionToken == null) return null;
    return SessionApiService(conn: conn, agentId: widget.agentId);
  }

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
      final api = _api;
      if (api == null) {
        if (mounted) {
          setState(() => _error = AppStrings.of.sessionsNotConnected);
        }
        return;
      }
      final sessions = await api.listSessions();
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

  // ── Resume ───────────────────────────────────────────────────────────

  Future<void> _requestResume(Session session) async {
    final api = _api;
    if (api == null) return;

    final newLabel = session.label != null
        ? session.label!
        : 'resume-${session.id.substring(0, 8)}';

    // Resume value priority: extra.claudeSessionId > extra.claudeName > label
    final resumeValue =
        (session.extra?['claudeSessionId'] as String?) ??
        (session.extra?['claudeName'] as String?) ??
        session.label;

    final spec = SessionSpec(
      cmd: 'claude',
      args: ['--name', newLabel, '--resume', resumeValue ?? session.id],
      cwd: session.cwd,
      cols: session.cols,
      rows: session.rows,
      label: newLabel,
      mode: SessionMode.process,
      extra: {'claudeName': newLabel},
    );

    try {
      final newSession = await api.createSession(spec);
      if (mounted) {
        context.push(
          '/session/${widget.profileId}/${widget.agentId}/${newSession.id}',
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

  // ── Actions ────────────────────────────────────────────────────────

  void _requestKill(String sessionId) {
    _showConfirm(
      title: AppStrings.of.sessionsKillTitle,
      desc: AppStrings.of.sessionsKillDesc,
      onConfirm: () async {
        final api = _api;
        if (api == null) return;
        await api.killSession(sessionId);
        await _load();
      },
    );
  }

  void _requestDelete(String sessionId) {
    _showConfirm(
      title: AppStrings.of.sessionsDeleteTitle,
      desc: AppStrings.of.sessionsDeleteDesc,
      onConfirm: () async {
        final api = _api;
        if (api == null) return;
        await api.deleteSession(sessionId);
        await _load();
      },
    );
  }

  void _requestPrune() {
    final resumableIds = <String>{};
    final pruneTargets = <String>[];
    for (final s in _sessions) {
      if (s.status != SessionStatus.exited) continue;
      if (s.cmd == 'claude' &&
          (s.extra?['claudeSessionId'] != null ||
              s.extra?['claudeName'] != null ||
              s.label != null)) {
        resumableIds.add(s.id);
      } else {
        pruneTargets.add(s.id);
      }
    }

    if (pruneTargets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ThemedText.small(AppStrings.of.sessionsNoneToPrune),
        ),
      );
      return;
    }

    final resumableCount = resumableIds.length;
    _showConfirm(
      title: AppStrings.of.sessionsPruneTitle,
      desc: resumableCount > 0
          ? '${AppStrings.of.sessionsPruneDesc}（${AppStrings.of.sessionsPruneSkipped(resumableCount)}）'
          : AppStrings.of.sessionsPruneDesc,
      onConfirm: () async {
        final api = _api;
        if (api == null) return;
        int removed = 0;
        for (final sid in pruneTargets) {
          try {
            await api.deleteSession(sid);
            removed++;
          } catch (_) {}
        }
        setState(() => _pruneInfo = removed);
        await _load();
      },
    );
  }

  Future<void> _showConfirm({
    required String title,
    required String desc,
    required Future<void> Function() onConfirm,
  }) async {
    final c = context.appColors;
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: title,
      showRobot: true,
      content: ThemedText.small(desc),
      confirmText: AppStrings.of.confirm,
      confirmIsDanger: true,
    );
    if (confirmed == true && mounted) {
      try {
        await onConfirm();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: c.danger),
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
            content: ThemedText.small(AppStrings.of.sessionsUnpinned),
          ),
        );
      }
    } else {
      // Not pinned → show label dialog then pin.
      final formKey = GlobalKey<LabelFormFieldState>();
      final result = await NeonDialog.show<String?>(
        context: context,
        title: AppStrings.of.sessionsPinTitle,
        showRobot: true,
        content: LabelFormField(
          key: formKey,
          initialText: session.label ?? session.cmd,
          labelText: AppStrings.of.sessionsPinLabel,
        ),
        actions: [
          NeonDialogAction(
            label: AppStrings.of.cancel,
            onPressed: (ctx) => Navigator.of(ctx).pop(null),
          ),
          NeonDialogAction(
            label: AppStrings.of.pinLabel,
            isPrimary: true,
            onPressed: (ctx) {
              final label = formKey.currentState?.text;
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
            content: ThemedText.small(AppStrings.of.sessionsPinned),
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
    final c = context.appColors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(agentName ?? widget.agentId),
        actions: [
          // Status filter
          PopupMenuButton<_StatusFilter>(
            icon: Icon(Icons.filter_list, color: c.textSecondary),
            onSelected: (f) => setState(() => _statusFilter = f),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: null,
                child: Text(AppStrings.of.sessionsFilterAll),
              ),
              PopupMenuItem(
                value: SessionStatus.running,
                child: Text(AppStrings.of.sessionsFilterRunning),
              ),
              PopupMenuItem(
                value: SessionStatus.exited,
                child: Text(AppStrings.of.sessionsFilterExited),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.add, color: c.primary),
            tooltip: AppStrings.of.sessionsNewTooltip,
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
      return Center(
        child: ThemedText.small(AppStrings.of.sessionsManagerNotFound),
      );
    }

    if (_loading && _sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final c = context.appColors;

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
            color: c.primary.withAlpha(15),
            child: Row(
              children: [
                Icon(Icons.cleaning_services, size: 14, color: c.primary),
                const SizedBox(width: AppSpacing.one),
                ThemedText.small(
                  AppStrings.of.sessionsPruned(_pruneInfo!),
                  color: c.primary,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _pruneInfo = null),
                  child: Icon(Icons.close, size: 14, color: c.textSecondary),
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
              color: c.danger.withAlpha(20),
              borderRadius: BorderRadius.circular(AppSpacing.two),
            ),
            child: Row(
              children: [
                Expanded(child: ThemedText.small(_error!, color: c.danger)),
                TextButton(
                  onPressed: _load,
                  child: Text(AppStrings.of.agentRetry),
                ),
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
                AppStrings.of.sessionsCount(_visible.length),
                color: c.textSecondary,
              ),
              const Spacer(),
              GestureDetector(
                onTap:
                    (_sessions
                        .where((s) => s.status != SessionStatus.exited)
                        .isNotEmpty)
                    ? _requestPrune
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.two,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          (_sessions
                              .where((s) => s.status != SessionStatus.exited)
                              .isNotEmpty)
                          ? c.primary.withAlpha(70)
                          : c.primary.withAlpha(30),
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.one),
                  ),
                  child: ThemedText.small(
                    AppStrings.of.sessionsPruneBtn,
                    color:
                        (_sessions
                            .where((s) => s.status != SessionStatus.exited)
                            .isNotEmpty)
                        ? c.primary
                        : c.primary.withAlpha(60),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.two),
              ThemedText.small(
                _loading ? '⟳' : '⟳ ${_timeSince(_lastLoaded)}',
                color: c.textSecondary,
              ),
            ],
          ),
        ),

        // ── Session list ────────────────────────────────────────────
        Expanded(
          child: _visible.isEmpty
              ? Center(
                  child: ThemedText.small(
                    _loading
                        ? AppStrings.of.sessionsLoading
                        : AppStrings.of.sessionsEmpty,
                    color: c.textSecondary,
                  ),
                )
              : ListView.builder(
                  itemCount: _visible.length,
                  itemBuilder: (context, index) {
                    final session = _visible[index];
                    final pinService = context.watch<PinnedSessionProvider>();
                    return context.appComponents.buildSessionCard(
                      context,
                      SessionCardData(
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
                        onResume:
                            (session.status == SessionStatus.exited &&
                                session.cmd == 'claude' &&
                                (session.extra?['claudeSessionId'] != null ||
                                    session.extra?['claudeName'] != null ||
                                    session.label != null))
                                ? () => _requestResume(session)
                                : null,
                        onTap: () => context.push(
                          '/session/${widget.profileId}/${widget.agentId}/${session.id}',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
