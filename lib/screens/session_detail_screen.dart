import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/claude_chat_view.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title(_session?.label ?? _session?.cmd ?? 'Session'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
      ),
      body: _loading
          ? const Center(child: NeonLoading())
          : _error != null
          ? Center(child: ThemedText.small(_error!, color: AppColors.danger))
          : _session != null && _conn != null
          ? _session!.mode == SessionMode.persistent
                ? ClaudeChatView(
                    serverRef: _conn!.managerRef,
                    agentId: widget.agentId,
                    session: _session!,
                  )
                : PtySessionView(
                    serverRef: _conn!.managerRef,
                    agentId: widget.agentId,
                    session: _session!,
                  )
          : Center(child: ThemedText.small('Session not found')),
    );
  }
}
