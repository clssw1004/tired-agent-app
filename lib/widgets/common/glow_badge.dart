import 'package:flutter/material.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

enum BadgeStatus { running, starting, exited, error, connected, disconnected }

class GlowBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? label;
  final bool glow;

  const GlowBadge({
    super.key,
    required this.status,
    this.label,
    this.glow = true,
  });

  String get _defaultLabel => switch (status) {
    BadgeStatus.running => AppStrings.of.statusRunning,
    BadgeStatus.connected => AppStrings.of.statusConnected,
    BadgeStatus.starting => AppStrings.of.statusStarting,
    BadgeStatus.error => AppStrings.of.statusError,
    BadgeStatus.exited => AppStrings.of.statusExited,
    BadgeStatus.disconnected => AppStrings.of.statusDisconnected,
  };

  Color _color(BuildContext context) {
    final c = context.appColors;
    return switch (status) {
      BadgeStatus.running => c.success,
      BadgeStatus.connected => c.success,
      BadgeStatus.starting => c.warning,
      BadgeStatus.error => c.danger,
      BadgeStatus.exited => c.textSecondary,
      BadgeStatus.disconnected => c.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.two,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSpacing.one),
        border: Border.all(color: color.withAlpha(60), width: 0.5),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withAlpha(30),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: glow
                  ? [
                      BoxShadow(
                        color: color.withAlpha(80),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.one + 2),
          ThemedText.label(label ?? _defaultLabel, color: color),
        ],
      ),
    );
  }
}
