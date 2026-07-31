import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// Directory picker form field with path display, clear, and open actions.
class DirectoryPickerField extends StatelessWidget {
  final String? path;
  final bool enabled;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  const DirectoryPickerField({
    super.key,
    this.path,
    this.enabled = true,
    this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final hasPath = path != null && path!.isNotEmpty;
    return GestureDetector(
      onTap: enabled ? onPick : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.three),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(
            color: hasPath ? c.primary.withAlpha(60) : c.border.withAlpha(60),
            width: hasPath ? 1 : 0.5,
          ),
          boxShadow: hasPath
              ? [BoxShadow(color: c.primary.withAlpha(10), blurRadius: 6)]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder_outlined,
              color: hasPath ? c.primary : c.textSecondary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.two),
            Expanded(
              child: ThemedText.mono(
                hasPath ? path! : '~ (home)',
                color: hasPath ? c.textCode : c.textSecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasPath)
              GestureDetector(
                onTap: enabled ? onClear : null,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: c.textSecondary.withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(Icons.close, size: 14, color: c.textSecondary),
                ),
              ),
            const SizedBox(width: AppSpacing.two),
            Icon(
              Icons.chevron_right,
              color: c.primary.withAlpha(120),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
