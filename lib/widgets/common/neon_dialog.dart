import 'package:flutter/material.dart';

import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/theme.dart';

/// A single action button for [NeonDialog].
class NeonDialogAction<T> {
  final String label;
  final void Function(BuildContext context) onPressed;
  final bool isPrimary;
  final bool isDanger;
  final Color? color;

  const NeonDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
    this.color,
  });
}

/// A reusable neon-styled dialog with neon borders, optional robot icon,
/// and consistent title styling.
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
    return show<bool>(
      context: context,
      title: title,
      content: content,
      icon: icon,
      emoji: emoji,
      showRobot: showRobot,
      maxWidth: maxWidth,
      actions: [
        NeonDialogAction<bool>(
          label: cancelText ?? AppStrings.of.cancel,
          onPressed: (ctx) => Navigator.of(ctx).pop(false),
        ),
        NeonDialogAction<bool>(
          label: confirmText ?? AppStrings.of.confirm,
          isDanger: confirmIsDanger,
          isPrimary: !confirmIsDanger,
          onPressed: (ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
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
    return showDialog<T>(
      context: context,
      builder: (ctx) => _NeonDialogContent(
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
  final List<NeonDialogAction<T>> actions;

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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding:
          insetPadding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? 400),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.primary.withAlpha(50), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: c.primary.withAlpha(15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title bar ────────────────────────────────────────────
            _TitleBar(
              title: title,
              icon: icon,
              emoji: emoji,
              showRobot: showRobot,
            ),

            // ── Content body (scrollable) ────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: content,
              ),
            ),

            // ── Action buttons ───────────────────────────────────────
            if (actions.isNotEmpty) _ActionBar<T>(actions: actions),
          ],
        ),
      ),
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

class _ActionBar<T> extends StatelessWidget {
  const _ActionBar({required this.actions});

  final List<NeonDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions.map((action) {
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
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: () => action.onPressed(context),
                style: TextButton.styleFrom(
                  foregroundColor: resolvedColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: () => action.onPressed(context),
              style: TextButton.styleFrom(
                foregroundColor: c.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              child: Text(
                action.label,
                style: TextStyle(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
