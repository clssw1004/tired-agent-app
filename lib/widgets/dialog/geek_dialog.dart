import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/dialog/contract.dart';
import 'package:tired_agent_app/widgets/dialog/styled_dialog_body.dart';

/// 极简极客风格对话框：纯 [AlertDialog] + 等宽标题，无描边/发光/机器人图标。
class GeekDialogImpl extends DialogContract {
  const GeekDialogImpl();

  @override
  double get defaultMaxWidth => 640;

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
    return StyledDialogBody(
      maxWidth: maxWidth ?? defaultMaxWidth,
      insetPadding: insetPadding,
      backgroundColor: c.surface,
      borderColor: c.border,
      borderRadius: AppSpacing.one,
      // padding 值非 AppSpacing 刻度（16/14/10），保留紧凑终端节奏。
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          ThemedText.mono('> ', color: c.primary),
          Expanded(
            child: ThemedText.mono(
              title,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ],
      ),
      content: content,
      actions: [
        for (final action in actions)
          () {
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
            return GestureDetector(
              onTap: () => action.onPressed(context),
              behavior: HitTestBehavior.opaque,
              child: ThemedText.mono(
                '[${action.label}]',
                fontWeight: FontWeight.w600,
                color: color,
              ),
            );
          }(),
      ],
    );
  }
}
