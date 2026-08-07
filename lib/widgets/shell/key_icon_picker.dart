import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/key_icon_catalog.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// Result of the key icon picker.
///
/// `icon` is `null` when the user chose to clear the icon; dismiss (tap
/// outside / swipe down) returns `null` from [KeyIconPicker.show] itself.
class KeyIconPickerResult {
  final IconData? icon;
  final bool cleared;
  const KeyIconPickerResult.picked(IconData this.icon) : cleared = false;
  const KeyIconPickerResult.cleared() : icon = null, cleared = true;
}

/// Bottom-sheet picker for the icon shown on a keyboard key.
///
/// Two tabs — Material Icons and Font Awesome — each with a name search field
/// over a grid of icons. Tapping an icon returns [KeyIconPickerResult.picked];
/// the header's clear action returns [KeyIconPickerResult.cleared].
class KeyIconPicker {
  KeyIconPicker._();

  static Future<KeyIconPickerResult?> show(
    BuildContext context, {
    IconData? current,
  }) {
    return showModalBottomSheet<KeyIconPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KeyIconSheet(current: current),
    );
  }
}

class _KeyIconSheet extends StatefulWidget {
  final IconData? current;
  const _KeyIconSheet({this.current});

  @override
  State<_KeyIconSheet> createState() => _KeyIconSheetState();
}

class _KeyIconSheetState extends State<_KeyIconSheet> {
  String _query = '';

  List<KeyIconEntry> _filtered(List<KeyIconEntry> catalog) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return catalog;
    return catalog.where((e) => e.name.contains(q)).toList();
  }

  void _pick(KeyIconEntry entry) {
    Navigator.of(context).pop(KeyIconPickerResult.picked(entry.icon));
  }

  void _clear() {
    Navigator.of(context).pop(const KeyIconPickerResult.cleared());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.three),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: c.primary, size: 20),
                  const SizedBox(width: AppSpacing.two),
                  Expanded(
                    child: ThemedText.title(
                      AppStrings.of.kbdIconPickerTitle,
                      color: c.text,
                    ),
                  ),
                  TextButton(
                    onPressed: _clear,
                    child: ThemedText.small(
                      AppStrings.of.kbdIconPickerClear,
                      color: c.danger,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.three,
                AppSpacing.two,
                AppSpacing.three,
                0,
              ),
              child: TextField(
                key: const ValueKey('kbd_icon_search'),
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: c.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppStrings.of.kbdIconPickerSearch,
                  hintStyle: TextStyle(
                    color: c.textSecondary.withAlpha(140),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: c.textSecondary,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: c.surfaceAlt.withAlpha(80),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: c.border, width: 0.5),
                  ),
                ),
              ),
            ),
            // Tabs
            TabBar(
              labelColor: c.primary,
              unselectedLabelColor: c.textSecondary,
              indicatorColor: c.primary,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              tabs: [
                Tab(text: AppStrings.of.kbdIconPickerMaterial),
                Tab(text: AppStrings.of.kbdIconPickerFontAwesome),
              ],
            ),
            Divider(height: 1, color: c.border),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGrid(KeyIconCatalog.material),
                  _buildGrid(KeyIconCatalog.fontAwesome),
                ],
              ),
            ),
            SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<KeyIconEntry> catalog) {
    final c = context.appColors;
    final entries = _filtered(catalog);
    if (entries.isEmpty) {
      return Center(
        child: ThemedText.small(
          AppStrings.of.kbdIconPickerEmpty,
          color: c.textSecondary,
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.two),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 64,
        mainAxisSpacing: AppSpacing.one,
        crossAxisSpacing: AppSpacing.one,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _iconTile(entries[i]),
    );
  }

  Widget _iconTile(KeyIconEntry entry) {
    final c = context.appColors;
    final selected = entry.icon == widget.current;
    return GestureDetector(
      onTap: () => _pick(entry),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? c.primary.withAlpha(25) : c.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? c.primary : c.border.withAlpha(60),
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Icon(
          entry.icon,
          size: 20,
          color: selected ? c.primary : c.textCode,
        ),
      ),
    );
  }
}
