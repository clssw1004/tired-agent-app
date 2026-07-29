import 'package:flutter/material.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

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
      builder: (_) => BufferSizeCustomDialog(
        initialValue: currentSize,
        onSave: onChanged,
      ),
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
                ...kTerminalBufferPresets.map((size) => DropdownMenuItem(
                      value: size,
                      child: ThemedText.body(
                        AppStrings.of.settingsBufferSizeLines(size),
                      ),
                    )),
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
/// Renders its own dialog UI (styled to match [NeonDialog]).
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

  void _confirm() {
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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.primary.withAlpha(50), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: c.primary.withAlpha(15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: c.border.withAlpha(120),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child:
                        Icon(Icons.smart_toy, color: c.primary, size: 22),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.of.settingsBufferSize,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content body ──────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
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
              ),
            ),

            // ── Action buttons ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      AppStrings.of.cancel,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _confirm,
                    style: TextButton.styleFrom(
                      foregroundColor: c.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: c.primary.withAlpha(50),
                          width: 0.5,
                        ),
                      ),
                      backgroundColor: c.primary.withAlpha(8),
                    ),
                    child: Text(
                      AppStrings.of.confirm,
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
