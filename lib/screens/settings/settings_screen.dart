import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

          // ── Notifications ──────────────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsNotifications,
          ),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsSessionExitNotifications,
              switchValue: settings.sessionExitNotifications,
              onSwitchChanged: (v) => settings.setSessionExitNotifications(v),
            ),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── About（version/build 同步自 pubspec.yaml）────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsAbout),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(label: AppStrings.of.settingsApp, value: 'TiredAgent'),
          ),
          const SizedBox(height: AppSpacing.one),
          const _AppVersionTile(),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}

/// 关于区版本/build tile：从 pubspec.yaml（通过 native versionName/versionCode）
/// 读运行时版本号，构建号单独一行展示，避免升级时遗漏同步。
class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '—';
        final build = snapshot.data?.buildNumber ?? '—';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            context.appComponents.buildSettingsTile(
              context,
              SettingsTileData(label: AppStrings.of.settingsVersion, value: version),
            ),
            const SizedBox(height: AppSpacing.one),
            context.appComponents.buildSettingsTile(
              context,
              SettingsTileData(label: AppStrings.of.aboutBuildNumber, value: build),
            ),
          ],
        );
      },
    );
  }
}
