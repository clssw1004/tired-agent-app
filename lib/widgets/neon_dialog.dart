import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';

/// A single action button for [NeonDialog].
///
/// Each action renders as either a primary-style (`isPrimary`) or danger-style
/// (`isDanger`) button, or a plain text button (default).
class NeonDialogAction<T> {
  /// Button label text.
  final String label;

  /// Called when the button is pressed. Receives the dialog context so the
  /// callback can call `Navigator.of(ctx).pop(...)`.
  final void Function(BuildContext context) onPressed;

  /// Whether this is the primary (accent-colored) action.
  final bool isPrimary;

  /// Whether this is a danger action (red accent).
  final bool isDanger;

  /// Optional explicit color override (takes precedence over [isPrimary] /
  /// [isDanger]).
  final Color? color;

  const NeonDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
    this.color,
  });
}

/// A reusable cyberpunk-styled dialog with neon borders, optional robot icon,
/// and consistent title styling.
///
/// Provides two entry points:
/// - [showConfirm] — quick yes/no/danger dialog that returns `true`/`false`.
/// - [show] — fully custom dialog with arbitrary actions.
///
/// Both share the same neon container (dark surface, thin glow border, robot
/// header icon) so all dialogs in the app look consistent.
class NeonDialog {
  NeonDialog._();

  /// Show a confirmation dialog (cancel + confirm action).
  ///
  /// Returns `true` if the user pressed the confirm button, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final ok = await NeonDialog.showConfirm(
  ///   context: context,
  ///   title: 'Delete session?',
  ///   content: ThemedText.small('This cannot be undone.'),
  ///   confirmIsDanger: true,
  /// );
  /// if (ok == true) { /* proceed */ }
  /// ```
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required Widget content,
    IconData? icon,
    String? emoji,
    bool showRobot = true,
    String cancelText = 'Cancel',
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
          label: cancelText,
          onPressed: (ctx) => Navigator.of(ctx).pop(false),
        ),
        NeonDialogAction<bool>(
          label: confirmText ?? (confirmIsDanger ? 'Confirm' : 'Confirm'),
          isDanger: confirmIsDanger,
          isPrimary: !confirmIsDanger,
          onPressed: (ctx) => Navigator.of(ctx).pop(true),
        ),
      ],
    );
  }

  /// Show a fully custom dialog with arbitrary [actions].
  ///
  /// The [title] is rendered in a neon-styled header with an optional robot
  /// icon. [content] is the dialog body — use a [Column] / [SingleChildScrollView]
  /// for complex layouts.
  ///
  /// Example with form:
  /// ```dart
  /// final result = await NeonDialog.show<bool>(
  ///   context: context,
  ///   title: 'Add Manager',
  ///   maxWidth: 480,
  ///   content: Column(
  ///     mainAxisSize: MainAxisSize.min,
  ///     children: [ TextField(...), TextField(...) ],
  ///   ),
  ///   actions: [
  ///     NeonDialogAction(label: 'Cancel', onPressed: (ctx) => Navigator.of(ctx).pop(false)),
  ///     NeonDialogAction(label: 'Connect', isPrimary: true, onPressed: (ctx) => Navigator.of(ctx).pop(true)),
  ///   ],
  /// );
  /// ```
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            insetPadding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 400),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withAlpha(50),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(15),
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

              // ── Content body ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: content,
              ),

              // ── Action buttons ───────────────────────────────────────
              if (actions.isNotEmpty)
                _ActionBar(actions: actions),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withAlpha(120),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Robot icon (left side, neon cyan)
          if (showRobot)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.smart_toy,
                color: AppColors.primary,
                size: 22,
              ),
            ),

          // Explicit emoji icon override
          if (emoji != null && !showRobot)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                emoji!,
                style: const TextStyle(fontSize: 20),
              ),
            ),

          // Custom material icon
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions.map((action) {
          final Color? resolvedColor;
          if (action.color != null) {
            resolvedColor = action.color;
          } else if (action.isDanger) {
            resolvedColor = AppColors.danger;
          } else if (action.isPrimary) {
            resolvedColor = AppColors.primary;
          } else {
            resolvedColor = null;
          }

          // Danger / primary styled button
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
                      color: (resolvedColor ?? AppColors.primary).withAlpha(
                        action.isDanger ? 80 : 50,
                      ),
                      width: 0.5,
                    ),
                  ),
                  backgroundColor: (resolvedColor ?? AppColors.primary)
                      .withAlpha(8),
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

          // Plain text button
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: () => action.onPressed(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              child: Text(
                action.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
