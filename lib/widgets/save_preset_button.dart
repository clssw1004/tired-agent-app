import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/session_presets.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// A compact save button that opens a dialog to save the current command
/// as a custom preset. The resulting [UserPreset] is reported via
/// [onSaved], and the caller is responsible for persisting the list.
class SavePresetButton extends StatelessWidget {
  final String cmd;
  final String argsText;

  /// Called when the user confirms a new preset. Insert into your list
  /// and persist as needed.
  final ValueChanged<UserPreset> onSaved;

  const SavePresetButton({
    super.key,
    required this.cmd,
    required this.argsText,
    required this.onSaved,
  });

  Future<void> _onTap(BuildContext context) async {
    final labelCtrl = TextEditingController(text: cmd);
    final result = await NeonDialog.show<UserPreset>(
      context: context,
      title: AppStrings.of.createSaveAsPreset,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedText.small(AppStrings.of.createPresetName),
          TextField(
            controller: labelCtrl,
            autofocus: true,
            decoration: const InputDecoration(isDense: true),
          ),
        ],
      ),
      actions: [
        NeonDialogAction<UserPreset>(
          label: AppStrings.of.cancel,
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        NeonDialogAction<UserPreset>(
          label: AppStrings.of.createSave,
          isPrimary: true,
          onPressed: (ctx) {
            final label = labelCtrl.text.trim();
            if (label.isEmpty) return;
            final manualArgs = argsText
                .trim()
                .split(RegExp(r'\s+'))
                .where((s) => s.isNotEmpty)
                .toList();
            Navigator.of(ctx).pop(
              UserPreset(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                label: label,
                cmd: cmd.trim(),
                args: manualArgs,
                emoji: '⚡',
              ),
            );
          },
        ),
      ],
    );
    if (result != null && context.mounted) {
      onSaved(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.two,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(color: c.primary.withAlpha(50), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.save_outlined,
              size: 14,
              color: c.primary.withAlpha(180),
            ),
            const SizedBox(width: 4),
            ThemedText.mono(
              AppStrings.of.createSave,
              color: c.primary.withAlpha(180),
            ),
          ],
        ),
      ),
    );
  }
}
