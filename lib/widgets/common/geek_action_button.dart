import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// 极客风格的终端式文字按钮：1px 语义色描边 + 圆角框，点击 affordance 明确。
class GeekActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const GeekActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(90), width: 1),
          borderRadius: BorderRadius.circular(AppSpacing.one),
        ),
        child: ThemedText(
          label,
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
