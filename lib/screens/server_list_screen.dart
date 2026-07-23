import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/server_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class ServerListScreen extends StatelessWidget {
  const ServerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => auth.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          if (auth.baseUrl != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.two),
              child: ThemedText.small(auth.baseUrl!, color: AppColors.textSecondary),
            ),
          Expanded(
            child: auth.agents.isEmpty
                ? Center(child: ThemedText.small('No agents connected'))
                : ListView.builder(
                    itemCount: auth.agents.length,
                    itemBuilder: (context, index) {
                      final agent = auth.agents[index];
                      return ServerCard(
                        agent: agent,
                        onTap: () => context.push('/server/${agent.id}'),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.four),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/server/new'),
                  icon: const Icon(Icons.add, size: 20),
                  label: ThemedText.body('Add Server'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
