import 'package:flutter/material.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/dialog/contract.dart';

/// Sentinel value used by the buffer-size dropdown's "Custom…" item.
const _customSentinel = -1;

/// A tile for choosing the terminal buffer size.
///
/// Shows a dropdown with preset values and a "Custom…" option that opens
/// [_BufferSizeCustomDialog].
class BufferSizeTile extends StatelessWidget {
  final int currentSize;
  final ValueChanged<int> onChanged;

  const BufferSizeTile({
    super.key,
    required this.currentSize,
    required this.onChanged,
  });

  /// Show a dialog for entering a custom buffer size.
  void _showCustomDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          BufferSizeCustomDialog(initialValue: currentSize, onSave: onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final inPreset = kTerminalBufferPresets.contains(currentSize);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.one,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.two),
        border: Border.all(color: c.border.withAlpha(40), width: 0.5),
      ),
      child: Row(
        children: [
          ThemedText.body(AppStrings.of.settingsBufferSize),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: inPreset ? currentSize : _customSentinel,
              dropdownColor: c.surface,
              style: TextStyle(
                color: c.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(Icons.arrow_drop_down, color: c.textSecondary),
              items: [
                ...kTerminalBufferPresets.map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: ThemedText.body(
                      AppStrings.of.settingsBufferSizeLines(size),
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: _customSentinel,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ThemedText(
                          AppStrings.of.settingsBufferSizeCustom,
                          color: c.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == _customSentinel) {
                  _showCustomDialog(context);
                } else if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for entering a custom buffer size.
///
/// Uses its own [StatefulWidget] for safe [TextEditingController] lifecycle
/// management (per CLAUDE.md guideline: controller in initState/dispose).
///
/// Reuses the dialog factory's shell (styled per current theme flavor) —
/// the neon look was a hand-copied clone of [NeonDialog], now merged here.
class BufferSizeCustomDialog extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onSave;

  const BufferSizeCustomDialog({
    super.key,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<BufferSizeCustomDialog> createState() => _BufferSizeCustomDialogState();
}

class _BufferSizeCustomDialogState extends State<BufferSizeCustomDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm(BuildContext context) {
    final text = _ctrl.text.trim();
    final size = int.tryParse(text);
    if (size == null || size < 200 || size > 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ThemedText(AppStrings.of.settingsBufferSizeInvalid),
          backgroundColor: context.appColors.danger.withAlpha(200),
        ),
      );
      return;
    }
    widget.onSave(size);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return context.appComponents.dialogOrFallback.shell<int>(
      context,
      title: AppStrings.of.settingsBufferSize,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemedText(
            AppStrings.of.settingsBufferSizeHint,
            color: c.textSecondary,
            fontSize: 13,
          ),
          const SizedBox(height: AppSpacing.two),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(color: c.text, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        DialogAction<int>(
          label: AppStrings.of.cancel,
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        DialogAction<int>(
          label: AppStrings.of.confirm,
          isPrimary: true,
          onPressed: _confirm,
        ),
      ],
    );
  }
}
