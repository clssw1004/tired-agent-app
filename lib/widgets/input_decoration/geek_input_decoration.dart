import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/input_decoration/contract.dart';

/// 极简极客风格输入框装饰：等宽主色前缀 + 小圆角描边，无霓虹发光。
class GeekInputDecorationImpl extends InputDecorationContract {
  const GeekInputDecorationImpl();

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
      labelStyle: TextStyle(
        fontFamily: 'monospace',
        color: c.textSecondary,
        fontSize: 12,
      ),
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontFamily: 'monospace',
        color: c.primary.withAlpha(140),
        fontSize: 12,
      ),
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.one),
        borderSide: BorderSide(color: c.border.withAlpha(80)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.one),
        borderSide: BorderSide(color: c.border.withAlpha(80)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.one),
        borderSide: BorderSide(color: c.primary, width: 1),
      ),
    );
  }
}
