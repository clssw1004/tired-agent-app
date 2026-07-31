import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/dialog/contract.dart';

/// 极简极客风格对话框：纯 [AlertDialog] + 等宽标题，无描边/发光/机器人图标。
class GeekDialogImpl extends DialogContract {
  const GeekDialogImpl();

  @override
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
  }) {
    return show<bool>(
      context,
      title: title,
      content: content,
      icon: icon,
      emoji: emoji,
      showRobot: showRobot,
      maxWidth: maxWidth,
      actions: [
        DialogAction<bool>(
          label: cancelText ?? AppStrings.of.cancel,
          onPressed: (ctx) => Navigator.of(ctx).pop(false),
        ),
        DialogAction<bool>(
          label: confirmText ?? AppStrings.of.confirm,
          isDanger: confirmIsDanger,
          isPrimary: !confirmIsDanger,
          onPressed: (ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
    );
  }

  @override
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
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => shell<T>(
        dialogContext,
        title: title,
        content: content,
        icon: icon,
        emoji: emoji,
        showRobot: showRobot,
        maxWidth: maxWidth,
        insetPadding: insetPadding,
        actions: actions,
      ),
    );
  }

  @override
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
  }) {
    final c = context.appColors;
    return AlertDialog(
      backgroundColor: c.surface,
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: SingleChildScrollView(child: content),
      ),
      actions: actions.map((action) {
        final Color color;
        if (action.color != null) {
          color = action.color!;
        } else if (action.isDanger) {
          color = c.danger;
        } else if (action.isPrimary) {
          color = c.primary;
        } else {
          color = c.textSecondary;
        }
        return TextButton(
          onPressed: () => action.onPressed(context),
          style: TextButton.styleFrom(foregroundColor: color),
          child: Text(
            action.label,
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }
}
