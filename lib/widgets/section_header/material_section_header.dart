import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/section_header/contract.dart';

/// Material Design 3 风格节标题：textTheme 标题 + primary 色，无发光竖条。
class MaterialSectionHeader extends SectionHeaderContract {
  const MaterialSectionHeader();

  @override
  Widget build(BuildContext context, String label, {Color? color}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.two),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
          color: color ?? scheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
