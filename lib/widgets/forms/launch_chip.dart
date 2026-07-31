import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// A launch button chip used in the create session screen's command preview.
///
/// Shows a play icon (or spinner when [busy]) and "Launch" text, styled with
/// the primary color. Disabled state is rendered with reduced opacity.
class LaunchChip extends StatelessWidget {
  /// Whether a submission is in progress (shows a spinner instead of play).
  final bool busy;

  /// Whether the chip should appear disabled (e.g. empty command).
  final bool disabled;

  /// Called when the chip is tapped and not [disabled].
  final VoidCallback? onTap;

  const LaunchChip({
    super.key,
    required this.busy,
    required this.disabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: c.primary.withAlpha(disabled ? 3 : 10),
          borderRadius: BorderRadius.circular(AppSpacing.three),
          border: Border.all(
            color: c.primary.withAlpha(disabled ? 15 : 60),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              Icon(
                Icons.play_arrow,
                size: 12,
                color: disabled ? c.textSecondary.withAlpha(60) : c.primary,
              ),
            const SizedBox(width: 3),
            ThemedText.mono(
              AppStrings.of.createLaunch,
              color: disabled ? c.textSecondary.withAlpha(60) : c.primary,
            ),
          ],
        ),
      ),
    );
  }
}
