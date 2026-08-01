import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/dialog/contract.dart';
import 'package:tired_agent_app/widgets/dialog/styled_dialog_body.dart';

/// 赛博朋克风格对话框：透明底 + 主色描边 + glow + 机器人图标 + 描边按钮。
class NeonDialogImpl extends DialogContract {
  const NeonDialogImpl();

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
      builder: (_) => shell<T>(
        context,
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
    return _NeonDialogContent<T>(
      title: title,
      content: content,
      icon: icon,
      emoji: emoji,
      showRobot: showRobot,
      maxWidth: maxWidth ?? defaultMaxWidth,
      insetPadding: insetPadding,
      actions: actions,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Dialog content — separate widget so build() can access context.appColors
// ═══════════════════════════════════════════════════════════════════════════

class _NeonDialogContent<T> extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData? icon;
  final String? emoji;
  final bool showRobot;
  final double? maxWidth;
  final EdgeInsets? insetPadding;
  final List<DialogAction<T>> actions;

  const _NeonDialogContent({
    required this.title,
    required this.content,
    this.icon,
    this.emoji,
    this.showRobot = true,
    this.maxWidth,
    this.insetPadding,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return StyledDialogBody(
      maxWidth: maxWidth ?? 640,
      insetPadding: insetPadding,
      backgroundColor: c.surface,
      borderColor: c.primary.withAlpha(50),
      borderRadius: 12,
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      title: _TitleBar(
        title: title,
        icon: icon,
        emoji: emoji,
        showRobot: showRobot,
      ),
      content: content,
      actions: [for (final a in actions) _NeonActionButton<T>(action: a)],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Internal widgets
// ═══════════════════════════════════════════════════════════════════════════

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.title,
    this.icon,
    this.emoji,
    this.showRobot = true,
  });

  final String title;
  final IconData? icon;
  final String? emoji;
  final bool showRobot;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border.withAlpha(120), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (showRobot)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.smart_toy, color: c.primary, size: 22),
            ),
          if (emoji != null && !showRobot)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(emoji!, style: const TextStyle(fontSize: 20)),
            ),
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, color: c.primary, size: 20),
            ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: c.text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonActionButton<T> extends StatelessWidget {
  const _NeonActionButton({required this.action});

  final DialogAction<T> action;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final Color? resolvedColor;
    if (action.color != null) {
      resolvedColor = action.color;
    } else if (action.isDanger) {
      resolvedColor = c.danger;
    } else if (action.isPrimary) {
      resolvedColor = c.primary;
    } else {
      resolvedColor = null;
    }

    if (action.isDanger || action.isPrimary || action.color != null) {
      return TextButton(
        onPressed: () => action.onPressed(context),
        style: TextButton.styleFrom(
          foregroundColor: resolvedColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: (resolvedColor ?? c.primary).withAlpha(
                action.isDanger ? 80 : 50,
              ),
              width: 0.5,
            ),
          ),
          backgroundColor: (resolvedColor ?? c.primary).withAlpha(8),
        ),
        child: Text(
          action.label,
          style: TextStyle(
            color: resolvedColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );
    }

    return TextButton(
      onPressed: () => action.onPressed(context),
      style: TextButton.styleFrom(
        foregroundColor: c.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(
        action.label,
        style: TextStyle(
          color: c.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
