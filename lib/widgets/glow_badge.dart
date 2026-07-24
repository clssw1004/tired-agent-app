import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// 状态发光指示器：圆点 + 文字。
/// 自动匹配 running→绿色, starting→橙色, exited→灰色, connected→绿色, disconnected→灰色。
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

  Color get _color => switch (status) {
    BadgeStatus.running => AppColors.success,
    BadgeStatus.connected => AppColors.success,
    BadgeStatus.starting => AppColors.warning,
    BadgeStatus.error => AppColors.danger,
    BadgeStatus.exited => AppColors.textSecondary,
    BadgeStatus.disconnected => AppColors.textSecondary,
  };

  String get _defaultLabel => switch (status) {
    BadgeStatus.running => 'Running',
    BadgeStatus.connected => 'Connected',
    BadgeStatus.starting => 'Starting',
    BadgeStatus.error => 'Error',
    BadgeStatus.exited => 'Exited',
    BadgeStatus.disconnected => 'Disconnected',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.two,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSpacing.one),
        border: Border.all(color: _color.withAlpha(60), width: 0.5),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: _color.withAlpha(30),
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
              color: _color,
              shape: BoxShape.circle,
              boxShadow: glow
                  ? [
                      BoxShadow(
                        color: _color.withAlpha(80),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.one + 2),
          ThemedText.label(label ?? _defaultLabel, color: _color),
        ],
      ),
    );
  }
}
