import 'package:flutter/material.dart';

/// 对话框样式规格（业务数据 + 布局参数）。
class DialogSpec {
  final String title;
  final Widget content;
  final IconData? icon;
  final String? emoji;
  final bool showRobot;
  final double? maxWidth;
  final EdgeInsets? insetPadding;

  const DialogSpec({
    required this.title,
    required this.content,
    this.icon,
    this.emoji,
    this.showRobot = true,
    this.maxWidth,
    this.insetPadding,
  });
}

/// 对话框动作按钮（各风格实现按 [isPrimary]/[isDanger] 渲染）。
class DialogAction<T> {
  final String label;
  final void Function(BuildContext context) onPressed;
  final bool isPrimary;
  final bool isDanger;
  final Color? color;

  const DialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
    this.color,
  });
}

/// 对话框风格契约：各风格实现定义对话框的视觉壳（标题栏 + 内容 + 操作栏）。
///
/// [show] / [showConfirm] 直接弹出；[shell] 返回壳 widget，供带自定义状态内容的
/// 对话框（如 BufferSizeCustomDialog）复用壳、自行管理内容与返回。
abstract class DialogContract {
  const DialogContract();

  /// 主题默认弹窗宽度：调用方不传 [maxWidth] 时生效，避免宽度散落各页面硬编码。
  double get defaultMaxWidth;

  Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required Widget content,
    IconData? icon,
    String? emoji,
    bool showRobot = true,
    String? cancelText,
    String? confirmText,
    bool confirmIsDanger = false,
    double? maxWidth,
  });

  Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    IconData? icon,
    String? emoji,
    bool showRobot = true,
    double? maxWidth,
    EdgeInsets? insetPadding,
    required List<DialogAction<T>> actions,
  });

  Widget shell<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    IconData? icon,
    String? emoji,
    bool showRobot = true,
    double? maxWidth,
    EdgeInsets? insetPadding,
    required List<DialogAction<T>> actions,
  });
}
