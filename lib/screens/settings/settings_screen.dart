import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/utils/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final settings = context.watch<AppSettingsProvider>();
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(AppStrings.of.settingsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          // ── Theme mode ─────────────────────────────────────────
          context.appComponents.buildSectionHeader(context, '${AppStrings.of.settingsTheme} — ${AppStrings.of.settingsMode}'),
          const SizedBox(height: AppSpacing.two),
          _ThemeTile(
            label: AppStrings.of.settingsThemeDark,
            selected: settings.themeMode == ThemeMode.dark,
            onTap: () => settings.setThemeMode(ThemeMode.dark),
          ),
          const SizedBox(height: AppSpacing.one),
          _ThemeTile(
            label: AppStrings.of.settingsThemeLight,
            selected: settings.themeMode == ThemeMode.light,
            onTap: () => settings.setThemeMode(ThemeMode.light),
          ),
          const SizedBox(height: AppSpacing.one),
          _ThemeTile(
            label: AppStrings.of.settingsThemeSystem,
            selected: settings.themeMode == ThemeMode.system,
            onTap: () => settings.setThemeMode(ThemeMode.system),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── Theme style ─────────────────────────────────────────
          context.appComponents.buildSectionHeader(context, '${AppStrings.of.settingsTheme} — ${AppStrings.of.settingsStyle}'),
          const SizedBox(height: AppSpacing.two),
          _ThemeTile(
            label: 'neon',
            selected: settings.themeFlavor == ThemeFlavor.neon,
            onTap: () => settings.setThemeFlavor(ThemeFlavor.neon),
          ),
          const SizedBox(height: AppSpacing.one),
          _ThemeTile(
            label: 'geek',
            selected: settings.themeFlavor == ThemeFlavor.geek,
            onTap: () => settings.setThemeFlavor(ThemeFlavor.geek),
          ),
          const SizedBox(height: AppSpacing.one),
          _ThemeTile(
            label: 'Material 3',
            selected: settings.themeFlavor == ThemeFlavor.material,
            onTap: () => settings.setThemeFlavor(ThemeFlavor.material),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── Language ─────────────────────────────────────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsLanguage),
          const SizedBox(height: AppSpacing.two),
          _ThemeTile(
            label: AppStrings.of.settingsLanguageZh,
            selected: settings.locale.languageCode == 'zh',
            onTap: () => settings.setLocale(const Locale('zh')),
          ),
          const SizedBox(height: AppSpacing.one),
          _ThemeTile(
            label: AppStrings.of.settingsLanguageEn,
            selected: settings.locale.languageCode == 'en',
            onTap: () => settings.setLocale(const Locale('en')),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── Terminal (navigates to dedicated page) ───────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsTerminal),
          const SizedBox(height: AppSpacing.two),
          _NavigationTile(
            label: AppStrings.of.settingsTerminal,
            onTap: () => context.push('/settings/terminal'),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── About ────────────────────────────────────────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsAbout),
          const SizedBox(height: AppSpacing.two),
          _InfoTile(label: AppStrings.of.settingsApp, value: 'TiredAgent'),
          const SizedBox(height: AppSpacing.one),
          _InfoTile(label: AppStrings.of.settingsVersion, value: '1.0.0'),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Theme/Language tile
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
            if (selected) Icon(Icons.check, size: 18, color: c.primary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Navigation tile (tap → push route)
// ═══════════════════════════════════════════════════════════════════════════

class _NavigationTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavigationTile({required this.label, required this.onTap});

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
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(color: c.border.withAlpha(40), width: 0.5),
        ),
        child: Row(
          children: [
            ThemedText.body(label, color: c.text),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: c.textSecondary),
          ],
        ),
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
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
      decoration: BoxDecoration(
        color: c.backgroundElement,
        borderRadius: BorderRadius.circular(AppSpacing.two),
      ),
      child: Row(
        children: [
          ThemedText.small(label, color: c.textSecondary),
          const Spacer(),
          Flexible(
            child: ThemedText(
              value,
              color: c.text,
              fontSize: 12,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
