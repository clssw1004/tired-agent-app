import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
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
    final auth = context.watch<AuthProvider>();
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

          // ── 默认管理器 ───────────────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.settingsDefaultManager,
          ),
          const SizedBox(height: AppSpacing.two),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.settingsDefaultManager,
              value: _defaultManagerName(auth, settings.defaultManagerId),
              onTap: () => _pickDefaultManager(context),
            ),
          ),
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }
}

/// 当前默认 manager 的展示名；未指定或已失效时显示「自动」。
String _defaultManagerName(AuthProvider auth, String? id) {
  if (id == null) return AppStrings.of.defaultManagerAuto;
  return auth.connectionFor(id)?.profile.name ??
      AppStrings.of.defaultManagerAuto;
}

/// 弹出「默认管理器」选择 bottom sheet：自动（跟随第一个）+ 全部 manager。
void _pickDefaultManager(BuildContext context) {
  final settings = context.read<AppSettingsProvider>();
  final auth = context.read<AuthProvider>();
  final c = context.appColors;
  final currentId = settings.defaultManagerId;

  showModalBottomSheet(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.four),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: c.primary, size: 20),
                const SizedBox(width: AppSpacing.two),
                ThemedText.title(
                  AppStrings.of.settingsDefaultManager,
                  color: c.primary,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          ListTile(
            dense: true,
            leading: Icon(
              Icons.auto_fix_high,
              color: currentId == null ? c.primary : c.textSecondary,
              size: 18,
            ),
            title: ThemedText.body(
              AppStrings.of.defaultManagerAuto,
              color: currentId == null ? c.primary : c.text,
            ),
            trailing: currentId == null
                ? Icon(Icons.check, color: c.primary, size: 18)
                : null,
            onTap: () async {
              Navigator.of(ctx).pop();
              await settings.setDefaultManagerId(null);
            },
          ),
          for (final conn in auth.connections)
            ListTile(
              dense: true,
              leading: Icon(
                Icons.hub_outlined,
                color: conn.profile.id == currentId
                    ? c.primary
                    : c.textSecondary,
                size: 18,
              ),
              title: ThemedText.body(
                conn.profile.name,
                color: conn.profile.id == currentId ? c.primary : c.text,
              ),
              trailing: conn.profile.id == currentId
                  ? Icon(Icons.check, color: c.primary, size: 18)
                  : null,
              onTap: () async {
                Navigator.of(ctx).pop();
                await settings.setDefaultManagerId(conn.profile.id);
              },
            ),
        ],
      ),
    ),
  );
}
