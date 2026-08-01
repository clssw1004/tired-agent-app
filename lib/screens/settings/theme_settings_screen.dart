import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

/// 独立主题设置页：风格（neon/geek/material）+ 模式（dark/light/system）。
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final settings = context.watch<AppSettingsProvider>();
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(AppStrings.of.settingsTheme),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          // ── 风格 ─────────────────────────────────────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsStyle),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: 'neon',
              selected: settings.themeFlavor == ThemeFlavor.neon,
              onTap: () => settings.setThemeFlavor(ThemeFlavor.neon),
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: 'geek',
              selected: settings.themeFlavor == ThemeFlavor.geek,
              onTap: () => settings.setThemeFlavor(ThemeFlavor.geek),
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: 'material-3',
              selected: settings.themeFlavor == ThemeFlavor.material,
              onTap: () => settings.setThemeFlavor(ThemeFlavor.material),
            ),
          ),
          const SizedBox(height: AppSpacing.four),

          // ── 模式 ─────────────────────────────────────────────
          context.appComponents.buildSectionHeader(context, AppStrings.of.settingsMode),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsThemeDark,
              selected: settings.themeMode == ThemeMode.dark,
              onTap: () => settings.setThemeMode(ThemeMode.dark),
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsThemeLight,
              selected: settings.themeMode == ThemeMode.light,
              onTap: () => settings.setThemeMode(ThemeMode.light),
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsThemeSystem,
              selected: settings.themeMode == ThemeMode.system,
              onTap: () => settings.setThemeMode(ThemeMode.system),
            ),
          ),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}
