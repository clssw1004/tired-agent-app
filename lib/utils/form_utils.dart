import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';

/// Section header — 按当前主题风格分发（neon / geek / material）。
Widget sectionHeader(BuildContext context, String label) =>
    context.appComponents.buildSectionHeader(context, label);

/// Shared [InputDecoration] for form text fields — 按当前主题风格分发。
InputDecoration neonInputDecoration(
  BuildContext context, {
  String? hint,
  String? prefixText,
}) =>
    context.appComponents.buildInputDecoration(
      context,
      hint: hint,
      prefixText: prefixText,
    );
