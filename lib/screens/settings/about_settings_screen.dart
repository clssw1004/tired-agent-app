import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

/// 独立关于页：应用名 + 版本 + 构建号（version/build 同步自 pubspec.yaml）。
class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(AppStrings.of.settingsAbout),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsApp,
              value: 'TiredAgent',
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          const _AppVersionTile(),
        ],
      ),
    );
  }
}

/// 版本/构建号 tile：从 native versionName/versionCode 读运行时版本号，
/// 构建号单独一行展示，避免升级时遗漏同步。
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
              SettingsTileData(
                label: AppStrings.of.settingsVersion,
                value: version,
              ),
            ),
            const SizedBox(height: AppSpacing.one),
            context.appComponents.buildSettingsTile(
              context,
              SettingsTileData(
                label: AppStrings.of.aboutBuildNumber,
                value: build,
              ),
            ),
          ],
        );
      },
    );
  }
}
