import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/session_presets.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

const inlineOptionLimit = 3;

/// Displays option chips for a builtin preset with inline toggles and
/// a "More" bottom-sheet for full option editing.
///
/// Owns all option-related UI (chip layout, picker dialogs, value selector)
/// and reports changes via the single [onChanged] callback with the full
/// updated selections map.
class PresetOptionChips extends StatelessWidget {
  final BuiltinPreset preset;
  final Map<String, String?> selections;
  final ValueChanged<Map<String, String?>> onChanged;

  /// Optional extra chips to append inline after the preset option chips.
  /// Each widget should be a small chip-like widget styled consistently.
  final List<Widget>? extra;

  const PresetOptionChips({
    super.key,
    required this.preset,
    required this.selections,
    required this.onChanged,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final options = preset.options;
    final inline = options.take(inlineOptionLimit).toList();
    final overflow = options.length > inlineOptionLimit
        ? options.skip(inlineOptionLimit).toList()
        : <PresetOption>[];

    return Wrap(
      spacing: AppSpacing.two,
      runSpacing: AppSpacing.one,
      children: [
        ...inline.map(
          (opt) => _OptionChip(
            label: _chipLabel(opt),
            isActive: selections[opt.id] != null,
            isToggle: opt.isToggle,
            onTap: () => _chipTapped(context, opt),
          ),
        ),
        if (overflow.isNotEmpty)
          _MoreChip(count: overflow.length, onTap: () => _showAll(context)),
        if (extra != null) ...extra!,
      ],
    );
  }

  // ── Chip actions ───────────────────────────────────────────────────────

  String _chipLabel(PresetOption opt) {
    final sel = selections[opt.id];
    return sel != null ? '${opt.label}: $sel' : opt.label;
  }

  void _chipTapped(BuildContext context, PresetOption opt) {
    if (opt.isToggle) {
      // Toggle on/off.
      final updated = Map<String, String?>.from(selections);
      if (updated.containsKey(opt.id)) {
        updated.remove(opt.id);
      } else {
        updated[opt.id] = opt.values.first.label;
      }
      onChanged(updated);
    } else {
      // Multi-value picker.
      _showValuePicker(context, opt, (label) {
        final updated = Map<String, String?>.from(selections);
        if (label == null) {
          updated.remove(opt.id);
        } else {
          updated[opt.id] = label;
        }
        onChanged(updated);
      });
    }
  }

  void _showValuePicker(
    BuildContext context,
    PresetOption opt,
    void Function(String? label) onSelected,
  ) {
    final c = context.appColors;
    final current = selections[opt.id];
    NeonDialog.show<String>(
      context: context,
      title: opt.label,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: opt.values.map((v) {
          final sel = v.label == current;
          return ListTile(
            selected: sel,
            selectedTileColor: c.accent.withAlpha(20),
            title: ThemedText.body(v.label),
            subtitle: v.hint.isNotEmpty ? ThemedText.small(v.hint) : null,
            trailing: sel
                ? Icon(Icons.check, color: c.primary, size: 18)
                : null,
            onTap: () => Navigator.of(context).pop(sel ? null : v.label),
            dense: true,
          );
        }).toList(),
      ),
      actions: [
        NeonDialogAction<String>(
          label: AppStrings.of.cancel,
          onPressed: (c) => Navigator.of(c).pop(),
        ),
      ],
    ).then((result) => onSelected(result));
  }

  // ── "More" bottom sheet ────────────────────────────────────────────────

  void _showAll(BuildContext context) {
    final c = context.appColors;
    final temp = Map<String, String?>.from(selections);

    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ThemedText.body(
                    '${preset.emoji} ${preset.label} options',
                    color: c.textSecondary,
                  ),
                ),
                Divider(height: 1, color: c.border),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: preset.options.map((opt) {
                        final sel = temp[opt.id];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: ThemedText.body(opt.label)),
                              const SizedBox(width: 8),
                              if (opt.isToggle)
                                Switch(
                                  value: sel != null,
                                  activeThumbColor: c.primary,
                                  onChanged: (v) {
                                    setSheetState(() {
                                      if (v) {
                                        temp[opt.id] = opt.values.first.label;
                                      } else {
                                        temp.remove(opt.id);
                                      }
                                    });
                                  },
                                )
                              else
                                GestureDetector(
                                  onTap: () =>
                                      _showValuePicker(ctx, opt, (label) {
                                        setSheetState(() {
                                          if (label == null) {
                                            temp.remove(opt.id);
                                          } else {
                                            temp[opt.id] = label;
                                          }
                                        });
                                      }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.backgroundElement,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ThemedText.small(
                                          sel ?? 'Select…',
                                          color: sel != null
                                              ? c.text
                                              : c.textSecondary,
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 16,
                                          color: c.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Divider(height: 1, color: c.border),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: ThemedText.body(AppStrings.of.cancel),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(temp),
                        child: ThemedText.body(
                          AppStrings.of.createOptionsApply,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null) {
        onChanged(result as Map<String, String?>);
      }
    });
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isToggle;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isActive,
    required this.isToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.one,
        ),
        decoration: BoxDecoration(
          color: isActive ? c.primary.withAlpha(8) : c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.three),
          border: Border.all(
            color: isActive ? c.primary.withAlpha(100) : c.border.withAlpha(40),
            width: isActive ? 1 : 0.5,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: c.primary.withAlpha(15), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedText.mono(
              label,
              color: isActive ? c.primary : c.textSecondary,
            ),
            if (!isToggle) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down,
                size: 14,
                color: isActive ? c.primary.withAlpha(180) : c.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MoreChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.one,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.three),
          border: Border.all(color: c.primary.withAlpha(50), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedText.mono('+$count', color: c.primary.withAlpha(180)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 14, color: c.primary.withAlpha(180)),
          ],
        ),
      ),
    );
  }
}
