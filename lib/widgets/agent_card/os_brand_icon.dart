import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// agent 平台 OS → FontAwesome 品牌图标；未知 OS 返回 null。
///
/// 三风格 agent 卡（neon/geek/material）共用同一映射，保证图标一致。
FaIconData? osBrandIcon(String os) => switch (os) {
  'win32' => FontAwesomeIcons.windows,
  'darwin' => FontAwesomeIcons.apple,
  'linux' => FontAwesomeIcons.linux,
  _ => null,
};
