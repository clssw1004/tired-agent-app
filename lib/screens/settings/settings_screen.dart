import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

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
          // ── Theme（独立设置页）───────────────────────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsTheme),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsTheme,
              navigation: true,
              onTap: () => context.push('/settings/theme'),
            ),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── Language ─────────────────────────────────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsLanguage),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsLanguageZh,
              selected: settings.locale.languageCode == 'zh',
              onTap: () => settings.setLocale(const Locale('zh')),
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsLanguageEn,
              selected: settings.locale.languageCode == 'en',
              onTap: () => settings.setLocale(const Locale('en')),
            ),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── Terminal（独立设置页）────────────────────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsTerminal),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsTerminal,
              navigation: true,
              onTap: () => context.push('/settings/terminal'),
            ),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── About ────────────────────────────────────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsAbout),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(label: AppStrings.of.settingsApp, value: 'TiredAgent'),
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(label: AppStrings.of.settingsVersion, value: '1.0.0'),
          ),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}
