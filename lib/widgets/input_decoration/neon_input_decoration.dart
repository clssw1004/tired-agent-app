import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/input_decoration/contract.dart';

/// 赛博朋克风格输入框装饰：主色前缀 + 圆角描边 + 主色聚焦。
class NeonInputDecorationImpl extends InputDecorationContract {
  const NeonInputDecorationImpl();

  @override
  InputDecoration build(
    BuildContext context, {
    String? label,
    String? hint,
    String? prefixText,
  }) {
    final c = context.appColors;
    return InputDecoration(
      isDense: true,
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontFamily: 'monospace',
        color: c.primary.withAlpha(140),
        fontSize: 13,
      ),
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.border.withAlpha(60)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.border.withAlpha(60)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.primary.withAlpha(100), width: 1),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.border.withAlpha(30)),
      ),
    );
  }
}
