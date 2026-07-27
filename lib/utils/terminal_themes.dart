import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

/// xterm2 终端配色预设标识符。
///
/// 通过 [TerminalThemes.of] 获取对应的 [TerminalTheme] 实例。
enum TerminalThemePreset {
  /// VS Code 风格深色（#1E1E1E 背景）— 与 xterm2 的 defaultTheme 一致。
  classic,

  /// 经典黑底白字。
  whiteOnBlack,

  /// Solarized Dark 经典配色。
  solarizedDark,

  /// Dracula 流行深色主题。
  dracula,

  /// 霓虹青紫风 — 匹配 App 的 cyberpunk 设计语言。
  neon,
}

/// xterm2 终端主题预设集合。
///
/// 所有定义集中于此文件，不分散于各页面 widget 中。
/// 如需新增主题，在此文件添加枚举值和对应 [TerminalTheme] 常量即可。
class TerminalThemes {
  TerminalThemes._();

  /// 根据预设标识符获取对应的 [TerminalTheme]。
  static TerminalTheme of(TerminalThemePreset preset) => _all[preset]!;

  /// 预设主题的中文名称（用于 UI 展示）。
  static String displayNameZh(TerminalThemePreset preset) => switch (preset) {
        TerminalThemePreset.classic => '默认',
        TerminalThemePreset.whiteOnBlack => '白底黑字',
        TerminalThemePreset.solarizedDark => 'Solarized Dark',
        TerminalThemePreset.dracula => 'Dracula',
        TerminalThemePreset.neon => '霓虹',
      };

  /// 预设主题的英文名称（用于 UI 展示）。
  static String displayNameEn(TerminalThemePreset preset) => switch (preset) {
        TerminalThemePreset.classic => 'Classic',
        TerminalThemePreset.whiteOnBlack => 'White on Black',
        TerminalThemePreset.solarizedDark => 'Solarized Dark',
        TerminalThemePreset.dracula => 'Dracula',
        TerminalThemePreset.neon => 'Neon',
      };

  static const Map<TerminalThemePreset, TerminalTheme> _all = {
    // ── Classic (VS Code Dark, #1E1E1E) ──────────────────────────────
    TerminalThemePreset.classic: TerminalTheme(
      cursor: Color(0XAAAEAFAD),
      selection: Color(0XAAAEAFAD),
      foreground: Color(0XFFCCCCCC),
      background: Color(0XFF1E1E1E),
      black: Color(0XFF000000),
      red: Color(0XFFCD3131),
      green: Color(0XFF0DBC79),
      yellow: Color(0XFFE5E510),
      blue: Color(0XFF2472C8),
      magenta: Color(0XFFBC3FBC),
      cyan: Color(0XFF11A8CD),
      white: Color(0XFFE5E5E5),
      brightBlack: Color(0XFF666666),
      brightRed: Color(0XFFF14C4C),
      brightGreen: Color(0XFF23D18B),
      brightYellow: Color(0XFFF5F543),
      brightBlue: Color(0XFF3B8EEA),
      brightMagenta: Color(0XFFD670D6),
      brightCyan: Color(0XFF29B8DB),
      brightWhite: Color(0XFFFFFFFF),
      searchHitBackground: Color(0XFFFFFF2B),
      searchHitBackgroundCurrent: Color(0XFF31FF26),
      searchHitForeground: Color(0XFF000000),
    ),

    // ── White on Black ───────────────────────────────────────────────
    TerminalThemePreset.whiteOnBlack: TerminalTheme(
      cursor: Color(0XFFAEAFAD),
      selection: Color(0XFFAEAFAD),
      foreground: Color(0XFFFFFFFF),
      background: Color(0XFF000000),
      black: Color(0XFF000000),
      red: Color(0XFFCD3131),
      green: Color(0XFF0DBC79),
      yellow: Color(0XFFE5E510),
      blue: Color(0XFF2472C8),
      magenta: Color(0XFFBC3FBC),
      cyan: Color(0XFF11A8CD),
      white: Color(0XFFE5E5E5),
      brightBlack: Color(0XFF666666),
      brightRed: Color(0XFFF14C4C),
      brightGreen: Color(0XFF23D18B),
      brightYellow: Color(0XFFF5F543),
      brightBlue: Color(0XFF3B8EEA),
      brightMagenta: Color(0XFFD670D6),
      brightCyan: Color(0XFF29B8DB),
      brightWhite: Color(0XFFFFFFFF),
      searchHitBackground: Color(0XFFFFFF2B),
      searchHitBackgroundCurrent: Color(0XFF31FF26),
      searchHitForeground: Color(0XFF000000),
    ),

    // ── Solarized Dark ───────────────────────────────────────────────
    TerminalThemePreset.solarizedDark: TerminalTheme(
      cursor: Color(0XFF839496),
      selection: Color(0XFF335E6A),
      foreground: Color(0XFF839496),
      background: Color(0XFF002B36),
      black: Color(0XFF073642),
      red: Color(0XFFDC322F),
      green: Color(0XFF859900),
      yellow: Color(0XFFB58900),
      blue: Color(0XFF268BD2),
      magenta: Color(0XFFD33682),
      cyan: Color(0XFF2AA198),
      white: Color(0XFFEEE8D5),
      brightBlack: Color(0XFF002B36),
      brightRed: Color(0XFFCB4B16),
      brightGreen: Color(0XFF586E75),
      brightYellow: Color(0XFF657B83),
      brightBlue: Color(0XFF839496),
      brightMagenta: Color(0XFF6C71C4),
      brightCyan: Color(0XFF93A1A1),
      brightWhite: Color(0XFFFDF6E3),
      searchHitBackground: Color(0XFFB58900),
      searchHitBackgroundCurrent: Color(0XFFCB4B16),
      searchHitForeground: Color(0XFF002B36),
    ),

    // ── Dracula ──────────────────────────────────────────────────────
    TerminalThemePreset.dracula: TerminalTheme(
      cursor: Color(0XFFF8F8F2),
      selection: Color(0XFF44475A),
      foreground: Color(0XFFF8F8F2),
      background: Color(0XFF282A36),
      black: Color(0XFF21222C),
      red: Color(0XFFFF5555),
      green: Color(0XFF50FA7B),
      yellow: Color(0XFFFFF1A5),
      blue: Color(0XFFBD93F9),
      magenta: Color(0XFFFF79C6),
      cyan: Color(0XFF8BE9FD),
      white: Color(0XFFF8F8F2),
      brightBlack: Color(0XFF6272A4),
      brightRed: Color(0XFFFF6E6E),
      brightGreen: Color(0XFF69FF94),
      brightYellow: Color(0XFFFFFFB5),
      brightBlue: Color(0XFFD6ACFF),
      brightMagenta: Color(0XFFFF92DF),
      brightCyan: Color(0XFFA4FFFF),
      brightWhite: Color(0XFFFFFFFF),
      searchHitBackground: Color(0XFFFFF1A5),
      searchHitBackgroundCurrent: Color(0XFFFF5555),
      searchHitForeground: Color(0XFF282A36),
    ),

    // ── Neon（霓虹青紫风） ──────────────────────────────────────────
    //
    // 配色灵感来自 App 的 cyberpunk 设计语言：
    //   - 背景极黑 (#0A0A0F)  → 浮光效果
    //   - 青 (#00F0FF)       → 主色调（primary）
    //   - 品红 (#FF00FF)     → 强调色（secondary）
    //   - 亮绿 (#00FF41)     → 代码绿（Matrix 风格）
    //   - 橙 (#FF6600)       → 警告色
    TerminalThemePreset.neon: TerminalTheme(
      cursor: Color(0xFF00F0FF),
      selection: Color(0xFF3A3A6A),
      foreground: Color(0xFFE8E8F0),
      background: Color(0xFF0A0A0F),
      black: Color(0xFF1A1A2E),
      red: Color(0xFFFF003C),
      green: Color(0xFF00FF41),
      yellow: Color(0xFFFF6600),
      blue: Color(0xFF00F0FF),
      magenta: Color(0xFFFF00FF),
      cyan: Color(0xFF00F0FF),
      white: Color(0xFFE8E8F0),
      brightBlack: Color(0xFF2A2A4A),
      brightRed: Color(0xFFFF3355),
      brightGreen: Color(0xFF33FF66),
      brightYellow: Color(0xFFFF8833),
      brightBlue: Color(0xFF33F3FF),
      brightMagenta: Color(0xFFFF33FF),
      brightCyan: Color(0xFF33F3FF),
      brightWhite: Color(0xFFFFFFFF),
      searchHitBackground: Color(0xFF3A3A6A),
      searchHitBackgroundCurrent: Color(0xFF00F0FF),
      searchHitForeground: Color(0xFF0A0A0F),
    ),
  };
}
