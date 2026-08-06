import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/session_presets.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

class _DropdownItem {
  final BuiltinPreset? builtin;
  final UserPreset? user;
  final String? separatorLabel;
  _DropdownItem._({this.builtin, this.user, this.separatorLabel});
  factory _DropdownItem.builtin(BuiltinPreset p) => _DropdownItem._(builtin: p);
  factory _DropdownItem.user(UserPreset p) => _DropdownItem._(user: p);
  factory _DropdownItem.separator(String label) =>
      _DropdownItem._(separatorLabel: label);

  bool get isSeparator => separatorLabel != null;
  String get label => builtin?.label ?? user?.label ?? separatorLabel ?? '';
  String get emoji => builtin?.emoji ?? user?.emoji ?? '';
}

/// Callback when a builtin or custom preset is selected.
typedef PresetSelectedCallback = void Function(String label);

/// A dropdown-style preset selector with bottom sheet picker.
///
/// Shows the current preset (or cmd) as the trigger button and opens a
/// scrollable bottom sheet on tap.
class SessionPresetDropdown extends StatelessWidget {
  final String currentLabel;
  final bool hasSelection;
  final String emoji;
  final List<BuiltinPreset> builtinPresets;
  final List<UserPreset> recentPresets;
  final List<UserPreset> customPresets;
  final String? selectedBuiltinId;
  final String? selectedUserId;
  final void Function(BuiltinPreset)? onSelectBuiltin;
  final void Function(UserPreset)? onSelectUser;

  const SessionPresetDropdown({
    super.key,
    required this.currentLabel,
    required this.hasSelection,
    required this.emoji,
    required this.builtinPresets,
    required this.recentPresets,
    required this.customPresets,
    this.selectedBuiltinId,
    this.selectedUserId,
    this.onSelectBuiltin,
    this.onSelectUser,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.three,
          vertical: AppSpacing.two,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(
            color: hasSelection
                ? c.primary.withAlpha(80)
                : c.border.withAlpha(60),
            width: hasSelection ? 1 : 0.5,
          ),
          boxShadow: hasSelection
              ? [BoxShadow(color: c.primary.withAlpha(15), blurRadius: 6)]
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.one),
            Expanded(
              child: ThemedText.mono(
                currentLabel,
                color: hasSelection ? c.primary : c.text,
              ),
            ),
            Icon(Icons.unfold_more, color: c.primary.withAlpha(140), size: 18),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final c = context.appColors;
    final items = _buildItems();
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.four),
            child: Row(
              children: [
                Icon(Icons.terminal, color: c.primary.withAlpha(180), size: 20),
                const SizedBox(width: AppSpacing.two),
                ThemedText.mono(
                  AppStrings.of.createSelectPreset,
                  color: c.primary,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                if (item.isSeparator) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.four,
                      AppSpacing.two,
                      AppSpacing.four,
                      AppSpacing.one,
                    ),
                    child: ThemedText.mono(
                      item.separatorLabel ?? '',
                      color: c.primary.withAlpha(120),
                    ),
                  );
                }
                final isActive =
                    (item.builtin != null &&
                        item.builtin!.id == selectedBuiltinId) ||
                    (item.user != null && item.user!.id == selectedUserId);
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.two,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? c.primary.withAlpha(10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.two),
                    border: isActive
                        ? Border.all(color: c.primary.withAlpha(40), width: 0.5)
                        : null,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    borderRadius: BorderRadius.circular(AppSpacing.two),
                    child: ListTile(
                      dense: true,
                      leading: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: ThemedText.mono(
                        item.label,
                        color: isActive ? c.primary : c.text,
                      ),
                      subtitle: item.builtin != null
                          ? ThemedText.small(item.builtin!.hint)
                          : null,
                      trailing: isActive
                          ? Icon(Icons.check, color: c.primary, size: 18)
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        if (item.builtin != null) {
                          onSelectBuiltin?.call(item.builtin!);
                        } else if (item.user != null) {
                          onSelectUser?.call(item.user!);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_DropdownItem> _buildItems() {
    final items = <_DropdownItem>[];
    for (final p in builtinPresets) {
      items.add(_DropdownItem.builtin(p));
    }
    if (recentPresets.isNotEmpty) {
      items.add(_DropdownItem.separator(AppStrings.of.createSectionRecent));
      for (final p in recentPresets) {
        items.add(_DropdownItem.user(p));
      }
    }
    if (customPresets.isNotEmpty) {
      items.add(_DropdownItem.separator(AppStrings.of.createSectionCustom));
      for (final p in customPresets) {
        items.add(_DropdownItem.user(p));
      }
    }
    return items;
  }
}
