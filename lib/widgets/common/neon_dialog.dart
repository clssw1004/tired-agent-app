import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/dialog/contract.dart';

/// 向后兼容别名：DialogAction（调用方继续用 `NeonDialogAction` 无需改 import）。
typedef NeonDialogAction<T> = DialogAction<T>;

/// 对话框 facade：静态方法委托当前风格的 [DialogContract] 实现。
///
/// 调用方保持 `NeonDialog.show(...)` / `NeonDialog.showConfirm(...)` 不变，
/// 内部按主题风格分发（neon / geek / material）。
class NeonDialog {
  NeonDialog._();

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required Widget content,
    IconData? icon,
    String? emoji,
    bool showRobot = true,
    String? cancelText,
    String? confirmText,
    bool confirmIsDanger = false,
    double? maxWidth,
  }) {
    return context.appComponents.dialogOrFallback.showConfirm(
      context,
      title: title,
      content: content,
      icon: icon,
      emoji: emoji,
      showRobot: showRobot,
      cancelText: cancelText,
      confirmText: confirmText,
      confirmIsDanger: confirmIsDanger,
      maxWidth: maxWidth,
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    IconData? icon,
    String? emoji,
    bool showRobot = true,
    double? maxWidth,
    EdgeInsets? insetPadding,
    required List<NeonDialogAction<T>> actions,
  }) {
    return context.appComponents.dialogOrFallback.show<T>(
      context,
      title: title,
      content: content,
      icon: icon,
      emoji: emoji,
      showRobot: showRobot,
      maxWidth: maxWidth,
      insetPadding: insetPadding,
      actions: actions,
    );
  }
}
