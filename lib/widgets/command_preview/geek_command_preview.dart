import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/command_preview/contract.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// 极简极客风格命令预览：简化终端窗（等宽排版，无霓虹 glow / 红绿灯）。
class GeekCommandPreview extends CommandPreviewContract {
  const GeekCommandPreview();

  @override
  Widget build(
    BuildContext context, {
    required String cmd,
    required String commandLine,
    Widget? actions,
  }) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar — `$ cmd` + optional actions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.three,
              vertical: AppSpacing.one,
            ),
            decoration: BoxDecoration(
              color: c.surfaceAlt.withAlpha(120),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
              border: Border(bottom: BorderSide(color: c.border.withAlpha(60))),
            ),
            child: Row(
              children: [
                ThemedText.mono('\$ $cmd', color: c.primary.withAlpha(140)),
                const Spacer(),
                actions ?? ThemedText.mono('---', color: c.textSecondary.withAlpha(60)),
              ],
            ),
          ),
          // Command content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.three),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText.mono(r'$ ', color: c.success.withAlpha(180)),
                Expanded(child: ThemedText.code(commandLine)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
