import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 内置预设 → FontAwesome 品牌图标。
///
/// bash/zsh 无专属品牌，分别用 linux / terminal 区分；cmd / powershell
/// 分别用 windows / microsoft。自定义/最近使用预设无品牌图标，
/// 渲染方应回退到 [BuiltinPreset.emoji]。
FaIconData? presetBrandIcon(String presetId) => switch (presetId) {
  'claude' => FontAwesomeIcons.claude,
  'bash' => FontAwesomeIcons.linux,
  'zsh' => FontAwesomeIcons.terminal,
  'cmd' => FontAwesomeIcons.windows,
  'powershell' => FontAwesomeIcons.microsoft,
  _ => null,
};
