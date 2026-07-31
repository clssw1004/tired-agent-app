import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/section_header/contract.dart';

/// 赛博朋克风格节标题：3px 发光竖条 + 等宽大写文字。
class NeonSectionHeader extends SectionHeaderContract {
  const NeonSectionHeader();

  @override
  Widget build(BuildContext context, String label, {Color? color}) {
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
