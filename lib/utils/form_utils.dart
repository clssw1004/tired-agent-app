import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// Neon section header: monospace uppercase label + primary accent line.
Widget sectionHeader(BuildContext context, String label) {
  final c = context.appColors;
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.two),
    child: Row(
      children: [
        ThemedText.mono(label.toUpperCase(), color: c.primary),
        const SizedBox(width: AppSpacing.two),
        Expanded(child: Container(height: 1, color: c.primary.withAlpha(40))),
      ],
    ),
  );
}

/// Shared neon-styled [InputDecoration] for form text fields.
InputDecoration neonInputDecoration(
  BuildContext context, {
  String? hint,
  String? prefixText,
}) {
  final c = context.appColors;
  return InputDecoration(
    isDense: true,
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
