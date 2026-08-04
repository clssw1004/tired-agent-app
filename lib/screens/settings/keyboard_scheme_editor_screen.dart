import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/pty_keyboard_scheme.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/form_utils.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/shell/key_action_picker.dart';

/// Editor for a single keyboard scheme: name + rows of keys.
///
/// Rows are laid out in a single-column list; each row shows its keys as a
/// horizontal strip with controls to add/remove keys in that row, delete the
/// row, and open the key action picker on tap. A reset action restores the
/// rows from the scheme's base preset.
class KeyboardSchemeEditorScreen extends StatefulWidget {
  final String? schemeId;

  /// When creating a new scheme, the base preset id (`"shell"`, `"windows"`,
  /// …) or `"none"` for a blank scheme.
  final String? basePreset;

  const KeyboardSchemeEditorScreen({super.key, this.schemeId, this.basePreset});

  @override
  State<KeyboardSchemeEditorScreen> createState() =>
      _KeyboardSchemeEditorScreenState();
}

class _KeyboardSchemeEditorScreenState extends State<KeyboardSchemeEditorScreen> {
  late final TextEditingController _nameController;
  late List<List<TerminalKeyDef>> _rows;
  String? _basePresetId;
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<PtyKeyboardSchemeProvider>();
    final scheme = provider.byId(widget.schemeId);
    if (scheme != null) {
      _nameController = TextEditingController(text: scheme.name);
      _basePresetId = scheme.basePresetId;
      _rows = scheme.rows
          .map((row) => List<TerminalKeyDef>.of(row))
          .toList();
      _isNew = false;
    } else {
      // New scheme: start from a base preset (or blank when `base=none`).
      _nameController = TextEditingController();
      final base = widget.basePreset;
      final preset = (base == null || base == 'none')
          ? null
          : PtyKeyboardConfig.byId(base);
      _basePresetId = preset?.id;
      _rows = (preset?.rows ?? const <List<TerminalKeyDef>>[])
          .map((row) => List<TerminalKeyDef>.of(row))
          .toList();
      if (_rows.isEmpty) _rows = [[]];
      _isNew = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _rows.every((r) => r.isEmpty)) return;
    final provider = context.read<PtyKeyboardSchemeProvider>();
    if (_isNew) {
      await provider.create(
        name: name,
        rows: _rows,
        basePresetId: _basePresetId,
      );
    } else {
      await provider.update(
        PtyKeyboardScheme.fromConfig(
          id: widget.schemeId!,
          name: name,
          rows: _rows,
          basePresetId: _basePresetId,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _resetToPreset() async {
    final presetId = _basePresetId;
    final preset = presetId == null ? null : PtyKeyboardConfig.byId(presetId);
    if (preset == null) return;
    setState(() {
      _rows = preset.rows
          .map((row) => List<TerminalKeyDef>.of(row))
          .toList();
    });
  }

  Future<void> _editKey(int rowIdx, int keyIdx) async {
    final result = await KeyActionPicker.show(
      context,
      current: _rows[rowIdx][keyIdx],
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.cleared) {
        _rows[rowIdx].removeAt(keyIdx);
      } else {
        _rows[rowIdx][keyIdx] = result.def!;
      }
    });
  }

  void _addKey(int rowIdx) {
    setState(() {
      _rows[rowIdx].add(TerminalKeys.backspace);
    });
  }

  void _removeKey(int rowIdx) {
    if (_rows[rowIdx].isEmpty) return;
    setState(() {
      _rows[rowIdx].removeLast();
    });
  }

  void _addRow() {
    setState(() {
      _rows.add([TerminalKeys.backspace]);
    });
  }

  void _removeRow(int rowIdx) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows.removeAt(rowIdx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(
          _isNew
              ? AppStrings.of.kbdSchemeNew
              : AppStrings.of.kbdSchemeEdit,
        ),
        actions: [
          if (!_isNew && _basePresetId != null)
            IconButton(
              icon: Icon(Icons.restart_alt, color: c.warning),
              tooltip: AppStrings.of.kbdSchemeReset,
              onPressed: _resetToPreset,
            ),
          TextButton(
            onPressed: _save,
            child: ThemedText.label(AppStrings.of.kbdSchemeSave, color: c.primary),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.three),
            child: TextField(
              controller: _nameController,
              style: TextStyle(color: c.text, fontSize: 14),
              decoration: neonInputDecoration(
                context,
                label: AppStrings.of.kbdSchemeName,
                hint: AppStrings.of.kbdSchemeNameHint,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.three,
                0,
                AppSpacing.three,
                AppSpacing.three,
              ),
              itemCount: _rows.length + 1,
              itemBuilder: (_, i) {
                if (i == _rows.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.two),
                    child: OutlinedButton.icon(
                      onPressed: _addRow,
                      icon: Icon(Icons.add, size: 16, color: c.primary),
                      label: ThemedText.label(
                        AppStrings.of.kbdSchemeAddRow,
                        color: c.primary,
                      ),
                    ),
                  );
                }
                return _buildRowEditor(i);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowEditor(int rowIdx) {
    final c = context.appColors;
    final row = _rows[rowIdx];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.two),
      padding: const EdgeInsets.all(AppSpacing.two),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border.withAlpha(50), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ThemedText.label(
                '${AppStrings.of.kbdSchemeRow} ${rowIdx + 1}',
                color: c.textSecondary,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, size: 16, color: c.textSecondary),
                tooltip: AppStrings.of.kbdSchemeRemoveKey,
                onPressed: () => _removeKey(rowIdx),
              ),
              ThemedText.label('${row.length}', color: c.textSecondary),
              IconButton(
                icon: Icon(Icons.add_circle_outline, size: 16, color: c.primary),
                tooltip: AppStrings.of.kbdSchemeAddKey,
                onPressed: () => _addKey(rowIdx),
              ),
              const SizedBox(width: AppSpacing.one),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 16, color: c.danger),
                tooltip: AppStrings.of.kbdSchemeDeleteRow,
                onPressed: _rows.length > 1 ? () => _removeRow(rowIdx) : null,
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.one,
            runSpacing: AppSpacing.one,
            children: [
              for (var k = 0; k < row.length; k++)
                _buildKeySlot(rowIdx, k),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeySlot(int rowIdx, int keyIdx) {
    final c = context.appColors;
    final def = _rows[rowIdx][keyIdx];
    return GestureDetector(
      onTap: () => _editKey(rowIdx, keyIdx),
      child: Container(
        width: 56,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.border.withAlpha(80), width: 0.5),
        ),
        child: def.icon != null
            ? Icon(def.icon, size: 16, color: c.textCode)
            : ThemedText.label(def.label, color: c.textCode),
      ),
    );
  }
}
