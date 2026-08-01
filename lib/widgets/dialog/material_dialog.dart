import 'package:flutter/material.dart';

import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/dialog/contract.dart';
import 'package:tired_agent_app/widgets/dialog/styled_dialog_body.dart';

/// Material Design 3 风格对话框：原生 [AlertDialog]，primary → FilledButton，其余 TextButton。
class MaterialDialogImpl extends DialogContract {
  const MaterialDialogImpl();

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
    final scheme = Theme.of(context).colorScheme;
    return StyledDialogBody(
      maxWidth: maxWidth ?? defaultMaxWidth,
      insetPadding: insetPadding,
      backgroundColor: scheme.surface,
      borderColor: scheme.outline,
      borderRadius: 12,
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      title: icon != null
          ? Column(
              children: [
                Icon(icon, color: scheme.primary, size: 24),
                const SizedBox(height: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            )
          : Text(title, style: Theme.of(context).textTheme.titleLarge),
      content: content,
      actions: [
        for (final action in actions)
          () {
            if (action.isDanger) {
              return FilledButton(
                onPressed: () => action.onPressed(context),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                child: Text(action.label),
              );
            }
            if (action.isPrimary || action.color != null) {
              return FilledButton(
                onPressed: () => action.onPressed(context),
                child: Text(action.label),
              );
            }
            return TextButton(
              onPressed: () => action.onPressed(context),
              child: Text(action.label),
            );
          }(),
      ],
    );
  }
}
