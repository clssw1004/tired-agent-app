import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// 霓虹风格分割线。可选 [label] 显示居中标段文字。
class NeonDivider extends StatelessWidget {
  final String? label;
  final Color color;

  const NeonDivider({super.key, this.label, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.two),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withAlpha(0),
              color.withAlpha(80),
              color.withAlpha(0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(0), color.withAlpha(60)],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two),
          child: ThemedText.label(label!, color: color.withAlpha(180)),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(60), color.withAlpha(0)],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
