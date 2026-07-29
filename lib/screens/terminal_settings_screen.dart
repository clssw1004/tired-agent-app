import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/terminal_themes.dart';
import 'package:tired_agent_app/widgets/buffer_size_tile.dart';
import 'package:tired_agent_app/widgets/section_header.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Terminal settings screen — buffer size and future xterm/PTY options.
class TerminalSettingsScreen extends StatelessWidget {
  const TerminalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final settings = context.watch<AppSettingsProvider>();
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(AppStrings.of.settingsTerminal),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          // ── Buffer size ──────────────────────────────────────────
          SectionHeader(label: AppStrings.of.settingsBufferSize),
          const SizedBox(height: AppSpacing.two),
          BufferSizeTile(
            currentSize: settings.terminalBufferSize,
            onChanged: (size) => settings.setTerminalBufferSize(size),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── Terminal Theme ────────────────────────────────────────
          SectionHeader(label: AppStrings.of.settingsTerminalTheme),
          const SizedBox(height: AppSpacing.two),
          ...List.generate(TerminalThemePreset.values.length, (i) {
            final preset = TerminalThemePreset.values[i];
            final selected = settings.terminalThemePreset == preset;
            final locale = settings.locale;
            final name = locale.languageCode == 'zh'
                ? TerminalThemes.displayNameZh(preset)
                : TerminalThemes.displayNameEn(preset);
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < TerminalThemePreset.values.length - 1
                    ? AppSpacing.one
                    : 0,
              ),
              child: _ThemeTile(
                label: name,
                selected: selected,
                onTap: () => settings.setTerminalThemePreset(preset),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Theme selection tile
// ═══════════════════════════════════════════════════════════════════════════

class _ThemeTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.three,
          vertical: AppSpacing.two,
        ),
        decoration: BoxDecoration(
          color: selected ? c.primary.withAlpha(10) : c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(
            color: selected ? c.primary.withAlpha(60) : c.border.withAlpha(40),
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            ThemedText.body(label, color: selected ? c.primary : c.text),
            const Spacer(),
            if (selected)
              Icon(Icons.check, size: 18, color: c.primary),
          ],
        ),
      ),
    );
  }
}