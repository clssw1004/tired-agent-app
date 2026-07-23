import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/session_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final ref = await auth.getServerRef(widget.serverId);
      if (ref == null) {
        setState(() => _error = 'Server credentials missing');
        return;
      }
      _ref = ref;
      final sessions = await auth.authService.transport.listSessions(ref, agentId: widget.serverId);
      if (mounted) setState(() { _sessions = sessions; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title(_ref?.name ?? 'Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () {
              // Session creation will be implemented later
            },
            tooltip: 'New Session',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: ThemedText.small(_error!, color: AppColors.danger))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _sessions.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 200),
                            Center(child: ThemedText.small('No sessions yet — tap + to create')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final session = _sessions[index];
                            return SessionCard(
                              session: session,
                              onTap: () => context.push('/session/${widget.serverId}-${session.id}'),
                            );
                          },
                        ),
                ),
    );
  }
}
