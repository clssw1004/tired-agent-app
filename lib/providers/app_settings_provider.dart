import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xterm2/xterm.dart' show TerminalTheme;

import 'package:tired_agent_app/utils/terminal_themes.dart';

/// 主题风格枚举
enum ThemeFlavor {
  neon,
  geek,
  material,
}

/// 终端缓冲区大小预设选项（行数）
const List<int> kTerminalBufferPresets = [
  1000,
  2000,
  3000,
  5000,
  8000,
  10000,
];

/// 应用设置 Provider — 管理主题模式 + 语言偏好 + 终端配置
///
/// 提供运行时切换和持久化能力，切换后立即生效无需重启。
class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider()
    : _themeFlavor = ThemeFlavor.neon,
      _themeMode = ThemeMode.dark,
      _locale = const Locale('zh'),
      _terminalBufferSize = kDefaultBufferSize,
      _terminalThemePreset = TerminalThemePreset.classic;

  // ── 持久化 Key ──────────────────────────────────────────────────
  static const _kThemeFlavor = 'app_theme_flavor';
  static const _kThemeMode = 'app_theme_mode';
  static const _kLocale = 'app_locale';
  static const _kTerminalBufferSize = 'terminal_buffer_size';

  static const _kTerminalTheme = 'terminal_theme';
  static const _kSessionExitNotifications = 'session_exit_notifications';

  /// 默认终端缓冲区大小。
  static const int kDefaultBufferSize = 5000;

  ThemeFlavor _themeFlavor;
  ThemeMode _themeMode;
  Locale _locale;
  int _terminalBufferSize;
  TerminalThemePreset _terminalThemePreset;
  bool _sessionExitNotifications = true;

  ThemeFlavor get themeFlavor => _themeFlavor;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  int get terminalBufferSize => _terminalBufferSize;
  TerminalThemePreset get terminalThemePreset => _terminalThemePreset;
  TerminalTheme get terminalTheme => TerminalThemes.of(_terminalThemePreset);

  /// 会话结束时是否发送本地通知。
  bool get sessionExitNotifications => _sessionExitNotifications;

  // 是否为暗色（供 callers 便捷判断）
  bool get isDark => _themeMode == ThemeMode.dark;

  // ── 加载 ─────────────────────────────────────────────────────────

  /// 从 SharedPreferences 加载已持久化的设置。
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 主题风格
    final flavorStr = prefs.getString(_kThemeFlavor);
    if (flavorStr != null) {
      _themeFlavor = switch (flavorStr) {
        'neon' => ThemeFlavor.neon,
        'cyberpunk' => ThemeFlavor.neon, // 旧值迁移
        'geek' => ThemeFlavor.geek,
        'minimal' => ThemeFlavor.geek, // 旧值迁移
        'material' => ThemeFlavor.material,
        _ => ThemeFlavor.neon,
      };
    }

    // 主题模式
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

    // 终端缓冲区大小
    _terminalBufferSize =
        prefs.getInt(_kTerminalBufferSize) ?? kDefaultBufferSize;

    // 终端主题
    final terminalThemeStr = prefs.getString(_kTerminalTheme);
    if (terminalThemeStr != null) {
      _terminalThemePreset = TerminalThemePreset.values.firstWhere(
        (e) => e.name == terminalThemeStr,
        orElse: () => TerminalThemePreset.classic,
      );
    }

    // 会话退出通知
    _sessionExitNotifications =
        prefs.getBool(_kSessionExitNotifications) ?? true;

    notifyListeners();
  }

  // ── 主题风格切换 ────────────────────────────────────────────────

  Future<void> setThemeFlavor(ThemeFlavor flavor) async {
    if (_themeFlavor == flavor) return;
    _themeFlavor = flavor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeFlavor, flavor.name);
  }

  // ── 主题模式切换 ─────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> toggleTheme() async {
    final next = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
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

  // ── 终端缓冲区大小 ───────────────────────────────────────────────

  Future<void> setTerminalBufferSize(int size) async {
    if (_terminalBufferSize == size) return;
    _terminalBufferSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTerminalBufferSize, size);
  }

  // ── 终端主题 ───────────────────────────────────────────────────────

  Future<void> setTerminalThemePreset(TerminalThemePreset preset) async {
    if (_terminalThemePreset == preset) return;
    _terminalThemePreset = preset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTerminalTheme, preset.name);
  }

  // ── 会话退出通知 ───────────────────────────────────────────────────

  Future<void> setSessionExitNotifications(bool enabled) async {
    if (_sessionExitNotifications == enabled) return;
    _sessionExitNotifications = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSessionExitNotifications, enabled);
  }
}
