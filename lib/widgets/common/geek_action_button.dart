import 'package:flutter/material.dart';

import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// 极客风格的终端式文字按钮：`[label]` 方括号表示可点击，无边框、无底色。
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
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ThemedText.mono(
          '[$label]',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
