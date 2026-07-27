import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// 节标题：左侧 3px 霓虹竖条 + 等宽大写文字。
class SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  SectionHeader({
    super.key,
    required this.label,
    Color? color,
  }) : color = color ?? AppColors.dark.primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(60),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.two),
        ThemedText.label(label.toUpperCase(), color: color),
      ],
    );
  }
}
