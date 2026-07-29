import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// 节标题：左侧 3px 霓虹竖条 + 等宽大写文字。
class SectionHeader extends StatelessWidget {
  final String label;
  final Color? color;

  const SectionHeader({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final barColor = color ?? c.primary;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(1.5),
            boxShadow: [
              BoxShadow(
                color: barColor.withAlpha(60),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.two),
        ThemedText.label(label.toUpperCase(), color: barColor),
      ],
    );
  }
}
