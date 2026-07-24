import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          // ── Connection ──────────────────────────────────────────────
          _SectionHeader(label: 'Connection'),
          const SizedBox(height: AppSpacing.two),
          _InfoTile(label: 'Base URL', value: auth.baseUrl ?? '—'),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(
            label: 'Status',
            value: auth.status == AuthStatus.authenticated ? 'Connected' : 'Disconnected',
            valueColor: auth.status == AuthStatus.authenticated ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.three),

          // ── Agents ─────────────────────────────────────────────────
          _SectionHeader(label: 'Agents (${auth.agents.length})'),
          const SizedBox(height: AppSpacing.two),
          if (auth.agents.isEmpty)
            ThemedText.small('No agents connected', color: AppColors.textSecondary)
          else
            ...auth.agents.map((agent) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.one),
              child: _InfoTile(
                label: agent.name,
                value: agent.baseUrl,
              ),
            )),
          const SizedBox(height: AppSpacing.three),

          // ── About ──────────────────────────────────────────────────
          _SectionHeader(label: 'About'),
          const SizedBox(height: AppSpacing.two),
          _InfoTile(label: 'App', value: 'tiredAgentMobile'),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: 'Version', value: '1.0.0'),
          const SizedBox(height: AppSpacing.six),

          // ── Logout ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, auth),
              icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
              label: ThemedText.body('Logout', color: AppColors.danger),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.danger.withAlpha(80)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.three),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElement,
        title: Row(children: [
          const ThemedText('🚪', fontSize: 20),
          const SizedBox(width: AppSpacing.two),
          ThemedText.title('Logout?'),
        ]),
        content: ThemedText.small('You will need to re-enter your API token.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: ThemedText.body('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: ThemedText.body('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await auth.logout();
    }
  }
}

// ── Helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.three, vertical: AppSpacing.two),
      decoration: BoxDecoration(
        color: AppColors.backgroundElement,
        borderRadius: BorderRadius.circular(AppSpacing.two),
      ),
      child: Row(
        children: [
          ThemedText.small(label, color: AppColors.textSecondary),
          const Spacer(),
          Flexible(
            child: ThemedText(
              value,
              color: valueColor ?? AppColors.text,
              fontSize: 12,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
