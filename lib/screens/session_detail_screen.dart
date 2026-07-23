import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/claude_chat_view.dart';
import 'package:tired_agent_app/widgets/pty_session_view.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class SessionDetailScreen extends StatefulWidget {
  final String serverId;
  final String sessionId;

  const SessionDetailScreen({
    super.key,
    required this.serverId,
    required this.sessionId,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Session? _session;
  ServerRef? _ref;
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
      final ref = await auth.getServerRef(widget.serverId);
      if (ref == null) {
        setState(() { _error = 'Server credentials missing'; _loading = false; });
        return;
      }
      final session = await auth.authService.transport.getSession(ref, widget.sessionId, agentId: widget.serverId);
      if (mounted) setState(() { _session = session; _ref = ref; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title(_session?.label ?? _session?.cmd ?? 'Session'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: ThemedText.small(_error!, color: AppColors.danger))
              : _session != null && _ref != null
                  ? _session!.mode == SessionMode.persistent
                      ? ClaudeChatView(serverRef: _ref!, agentId: widget.serverId, session: _session!)
                      : PtySessionView(serverRef: _ref!, agentId: widget.serverId, session: _session!)
                  : Center(child: ThemedText.small('Session not found')),
    );
  }
}
