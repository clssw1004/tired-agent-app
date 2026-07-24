import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/neon_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class ServerCard extends StatelessWidget {
  final AgentInfo agent;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ServerCard({
    super.key,
    required this.agent,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.four,
        vertical: AppSpacing.one,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText.mono(agent.name),
                const SizedBox(height: 2),
                ThemedText.mono(agent.baseUrl, color: AppColors.textSecondary),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 20,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
