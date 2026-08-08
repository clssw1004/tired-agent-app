import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

/// 设置主页：导航枢纽 + 快捷开关。成组的偏好设置收纳进各自二级页
/// （外观 / 终端设置 / 键盘方案 / 关于）。
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
          // ── 外观（独立设置页）───────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsAppearance,
          ),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsAppearance,
              navigation: true,
              onTap: () => context.push('/settings/appearance'),
            ),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── 终端（独立设置页）───────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsTerminal,
          ),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsTerminal,
              navigation: true,
              onTap: () => context.push('/settings/terminal'),
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.kbdSchemeSelect,
              navigation: true,
              onTap: () => context.push('/settings/keyboard'),
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

          // ── About ──────────────────────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsAbout,
          ),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsAbout,
              navigation: true,
              onTap: () => context.push('/settings/about'),
            ),
          ),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}
