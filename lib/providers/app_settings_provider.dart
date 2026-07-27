import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置 Provider — 管理主题模式 + 语言偏好
///
/// 提供运行时切换和持久化能力，切换后立即生效无需重启。
class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider() : _themeMode = ThemeMode.dark, _locale = const Locale('zh');

  // ── 持久化 Key ──────────────────────────────────────────────────
  static const _kThemeMode = 'app_theme_mode';
  static const _kLocale = 'app_locale';

  ThemeMode _themeMode;
  Locale _locale;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  // 是否为暗色（供 callers 便捷判断）
  bool get isDark => _themeMode == ThemeMode.dark;

  // ── 加载 ─────────────────────────────────────────────────────────

  /// 从 SharedPreferences 加载已持久化的设置。
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 主题
    final themeStr = prefs.getString(_kThemeMode);
    if (themeStr != null) {
      _themeMode = switch (themeStr) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    }

    // 语言
    final localeStr = prefs.getString(_kLocale);
    if (localeStr != null) {
      _locale = Locale(localeStr);
    }
  }

  // ── 主题切换 ─────────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> toggleTheme() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  // ── 语言切换 ─────────────────────────────────────────────────────

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, locale.languageCode);
  }
}
