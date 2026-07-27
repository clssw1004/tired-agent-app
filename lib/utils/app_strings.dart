/// 全局国际化字符串工具 — 无需 BuildContext 即可访问本地化文案。
///
/// 在 [MaterialApp.router] 首次构建后调用 [AppStrings.init(context)] 初始化，
/// 切换语言后在 [MaterialApp.router] 的 [builder] 回调中再次调用 [AppStrings.init]。
/// 初始化后各处直接使用 `AppStrings.of.someKey` 访问。
///
/// 用法：
/// ```dart
/// // 初始化（在 MaterialApp.router 的 builder 中）
/// AppStrings.init(context);
///
/// // 任意位置使用
/// Text(AppStrings.of.managersAdd)
/// ```
library;

import 'package:tired_agent_app/generated/l10n/app_localizations.dart';

class AppStrings {
  AppStrings._();

  static AppLocalizations? _loc;

  /// 当前本地化实例。
  static AppLocalizations get of {
    assert(_loc != null,
        'AppStrings not initialized — call AppStrings.init(context) in MaterialApp.router builder');
    return _loc!;
  }

  /// 初始化/刷新本地化实例。
  ///
  /// [context] 必须位于 [MaterialApp] 的 [Localizations] widget 之下，
  /// 例如在 `MaterialApp.router(builder: (context, child) { ... })` 中调用。
  static void init(AppLocalizations loc) {
    _loc = loc;
  }
}
