import 'package:flutter/material.dart';
import 'package:tired_agent_app/widgets/input_decoration/contract.dart';

/// Material Design 3 风格输入框装饰：仅叠加等宽主色前缀与 hint，
/// 边框/填充等由 M3 `InputDecorationTheme` 默认提供。
class MaterialInputDecorationImpl extends InputDecorationContract {
  const MaterialInputDecorationImpl();

  @override
  InputDecoration build(
    BuildContext context, {
    String? label,
    String? hint,
    String? prefixText,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontFamily: 'monospace',
        color: scheme.primary,
        fontSize: 13,
      ),
    );
  }
}
