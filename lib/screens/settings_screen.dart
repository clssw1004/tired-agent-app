import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/section_header.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('Settings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          // ── About ──────────────────────────────────────────────────
          SectionHeader(label: 'About'),
          const SizedBox(height: AppSpacing.two),
          _InfoTile(label: 'App', value: 'TiredAgent'),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: 'Version', value: '1.0.0'),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Info tile
// ═══════════════════════════════════════════════════════════════════════════

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
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
              color: AppColors.text,
              fontSize: 12,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
