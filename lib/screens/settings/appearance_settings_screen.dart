import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

/// 独立外观设置页：主题（风格/模式）+ 语言 + 首页展示模式。
///
/// 收纳主设置页的成组偏好设置，取代原独立主题设置页。
class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final settings = context.watch<AppSettingsProvider>();
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(AppStrings.of.settingsAppearance),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.four),
        children: [
          // ── 主题：风格 ────────────────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsStyle,
          ),
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

          // ── 主题：模式 ────────────────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsMode,
          ),
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

          // ── 语言 ─────────────────────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsLanguage,
          ),
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

          // ── 首页展示模式 ─────────────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsHomeDisplayMode,
          ),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.homeModeManagerList,
              selected: settings.homeDisplayMode == HomeDisplayMode.managerList,
              onTap: () =>
                  settings.setHomeDisplayMode(HomeDisplayMode.managerList),
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.homeModeManagerAgent,
              selected:
                  settings.homeDisplayMode == HomeDisplayMode.managerAgent,
              onTap: () =>
                  settings.setHomeDisplayMode(HomeDisplayMode.managerAgent),
            ),
          ),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}
