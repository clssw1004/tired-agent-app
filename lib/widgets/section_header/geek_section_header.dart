import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/section_header/contract.dart';

/// 极简极客风格节标题：`>> LABEL` 等宽文本，无发光竖条。
class GeekSectionHeader extends SectionHeaderContract {
  const GeekSectionHeader();

  @override
  Widget build(BuildContext context, String label, {Color? color}) {
    final c = context.appColors;
    final barColor = color ?? c.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.two),
      child: ThemedText(
        '>> ${label.toUpperCase()}',
        fontSize: 12,
        fontFamily: 'monospace',
        color: barColor,
      ),
    );
  }
}
