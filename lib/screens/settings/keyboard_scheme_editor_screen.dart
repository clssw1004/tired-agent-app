import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/pty_keyboard_scheme.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/form_utils.dart';
import 'package:tired_agent_app/utils/keyboard_row_ops.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/shell/key_action_picker.dart';
import 'package:tired_agent_app/widgets/shell/key_icon_picker.dart';
import 'package:tired_agent_app/widgets/shell/pty_key_cap.dart';

/// Editor for a single keyboard scheme: name + rows of keys.
///
/// Rows are rendered as a **live preview** using the same [PtyKeyCap] widget
/// as the PTY keyboard panel, so the editor is WYSIWYG with the real panel.
/// Tapping a key selects it and reveals the inline edit bar, where you can
/// relabel the key, pick its action (via [KeyActionPicker]), move it with the
/// arrow buttons, or delete it. A reset action restores the rows from the
/// scheme's base preset.
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

class _KeyboardSchemeEditorScreenState
    extends State<KeyboardSchemeEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _labelController;
  late List<List<TerminalKeyDef>> _rows;
  String? _basePresetId;
  bool _isNew = false;

  /// Selected key position — `(row, col)`, both `null` when nothing selected.
  int? _selRow;
  int? _selKey;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    final provider = context.read<PtyKeyboardSchemeProvider>();
    final scheme = provider.byId(widget.schemeId);
    if (scheme != null) {
      _nameController = TextEditingController(text: scheme.name);
      _basePresetId = scheme.basePresetId;
      _rows = scheme.rows.map((row) => List<TerminalKeyDef>.of(row)).toList();
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
    _labelController.dispose();
    super.dispose();
  }

  // ── Selection ──────────────────────────────────────────────────────────

  /// The currently selected key def, or `null` when nothing is selected or the
  /// selection points at a position that no longer exists.
  TerminalKeyDef? get _selectedDef {
    final r = _selRow;
    final c = _selKey;
    if (r == null || c == null) return null;
    if (r < 0 || r >= _rows.length || c < 0 || c >= _rows[r].length) {
      return null;
    }
    return _rows[r][c];
  }

  void _selectKey(int rowIdx, int keyIdx) {
    setState(() {
      if (_selRow == rowIdx && _selKey == keyIdx) {
        _selRow = null;
        _selKey = null;
      } else {
        _selRow = rowIdx;
        _selKey = keyIdx;
        _labelController.text = _rows[rowIdx][keyIdx].label;
      }
    });
  }

  /// Drop the selection when the row it points at has been removed or shrank.
  void _clearSelectionIfStale() {
    final r = _selRow;
    final c = _selKey;
    if (r == null || c == null) return;
    if (r < 0 || r >= _rows.length || c < 0 || c >= _rows[r].length) {
      _selRow = null;
      _selKey = null;
      _labelController.text = '';
    }
  }

  // ── Edit-bar actions ───────────────────────────────────────────────────

  void _updateLabel(String text) {
    final r = _selRow;
    final c = _selKey;
    if (r == null || c == null) return;
    setState(() {
      _rows[r][c] = _rows[r][c].copyWith(label: text);
    });
  }

  void _moveSelected(KeyMoveDir dir) {
    final r = _selRow;
    final c = _selKey;
    if (r == null || c == null) return;
    setState(() {
      if (!moveKey(_rows, r, c, dir)) return;
      // Selection follows the moved key to its new position.
      final (nr, nc) = switch (dir) {
        KeyMoveDir.left => (r, c - 1),
        KeyMoveDir.right => (r, c + 1),
        KeyMoveDir.up => (r - 1, c.clamp(0, _rows[r - 1].length - 1)),
        KeyMoveDir.down => (r + 1, c.clamp(0, _rows[r + 1].length - 1)),
      };
      _selRow = nr;
      _selKey = nc;
      _labelController.text = _rows[nr][nc].label;
    });
  }

  void _deleteSelected() {
    final r = _selRow;
    final c = _selKey;
    if (r == null || c == null) return;
    setState(() {
      _rows[r].removeAt(c);
      _selRow = null;
      _selKey = null;
      _labelController.text = '';
    });
  }

  Future<void> _pickAction() async {
    final r = _selRow;
    final c = _selKey;
    if (r == null || c == null) return;
    final result = await KeyActionPicker.show(context, current: _rows[r][c]);
    if (result == null || !mounted) return;
    setState(() {
      if (result.cleared) {
        _rows[r].removeAt(c);
        _selRow = null;
        _selKey = null;
        _labelController.text = '';
      } else {
        _rows[r][c] = result.def!;
        _labelController.text = _rows[r][c].label;
      }
    });
  }

  Future<void> _pickIcon() async {
    final r = _selRow;
    final c = _selKey;
    if (r == null || c == null) return;
    final result = await KeyIconPicker.show(context, current: _rows[r][c].icon);
    if (result == null || !mounted) return;
    setState(() {
      if (result.cleared) {
        _rows[r][c] = _rows[r][c].copyWith(clearIcon: true);
      } else {
        _rows[r][c] = _rows[r][c].copyWith(icon: result.icon);
      }
    });
  }

  // ── Row mutations ──────────────────────────────────────────────────────

  void _addKey(int rowIdx) {
    setState(() {
      _rows[rowIdx].add(TerminalKeys.backspace);
    });
  }

  void _removeKey(int rowIdx) {
    if (_rows[rowIdx].isEmpty) return;
    setState(() {
      _rows[rowIdx].removeLast();
      _clearSelectionIfStale();
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
      _clearSelectionIfStale();
    });
  }

  // ── Persistence ────────────────────────────────────────────────────────

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
      _rows = preset.rows.map((row) => List<TerminalKeyDef>.of(row)).toList();
      _selRow = null;
      _selKey = null;
      _labelController.text = '';
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(
          _isNew ? AppStrings.of.kbdSchemeNew : AppStrings.of.kbdSchemeEdit,
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
            child: ThemedText.label(
              AppStrings.of.kbdSchemeSave,
              color: c.primary,
            ),
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
          if (_selectedDef == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.three,
                0,
                AppSpacing.three,
                AppSpacing.two,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ThemedText.small(
                  AppStrings.of.kbdEditorSelectHint,
                  color: c.textSecondary,
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
          if (_selectedDef != null) _buildEditBar(),
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
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 16,
                  color: c.textSecondary,
                ),
                tooltip: AppStrings.of.kbdSchemeRemoveKey,
                onPressed: () => _removeKey(rowIdx),
              ),
              ThemedText.label('${row.length}', color: c.textSecondary),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: c.primary,
                ),
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
          if (row.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.one),
              child: ThemedText.small(
                AppStrings.of.kbdEditorEmptyRow,
                color: c.textSecondary,
              ),
            )
          else
            // PTY 面板同款渲染：Row + Expanded 均分，按键即真实预览
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  for (var k = 0; k < row.length; k++)
                    Expanded(
                      child: PtyKeyCap(
                        keyDef: row[k],
                        lit: _selRow == rowIdx && _selKey == k,
                        litColor: c.primary,
                        onTap: () => _selectKey(rowIdx, k),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Gap between the left edit-control column and the right D-pad, and between
  /// the two rows inside each column. Shared so both columns keep the same
  /// horizontal / vertical rhythm.
  static const double _cellGap = AppSpacing.two;

  /// Bottom inline edit bar — shown while a key is selected, does not cover
  /// the keyboard preview above it.
  ///
  /// Two-zone layout (D-pad on the right so the right hand moves the selection
  /// while the left hand tweaks the label / icon / action):
  ///
  ///   left column            right D-pad block
  ///   [ label ] [icon] [action]   [ ][↑][ ]
  ///   [delete] [close]            [←][↓][→]
  ///
  /// The D-pad is a fixed-width block on the right: ↑ sits directly above ↓
  /// with ← and → flanking it, so the two rows form a physical cross. On very
  /// narrow widths (< 360) the picker buttons collapse to icon-only and the
  /// D-pad cells shrink to 40dp so nothing overflows.
  Widget _buildEditBar() {
    final c = context.appColors;
    final r = _selRow!;
    final k = _selKey!;
    final row = _rows[r];
    return Container(
      key: const ValueKey('kbd_edit_bar'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.three,
        AppSpacing.two,
        AppSpacing.three,
        AppSpacing.three,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.primary.withAlpha(60), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tight = constraints.maxWidth < 360;
            return Row(
              children: [
                // Left column — everything but the D-pad.
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _labelField(c, tight: tight),
                          ),
                          SizedBox(width: _cellGap),
                          _editBtn(
                            key: const ValueKey('kbd_edit_icon'),
                            onPressed: _pickIcon,
                            leading: row[k].icon ?? Icons.image_outlined,
                            label: AppStrings.of.kbdEditorIcon,
                            active: row[k].icon != null,
                            tight: tight,
                          ),
                          SizedBox(width: _cellGap),
                          _editBtn(
                            key: const ValueKey('kbd_edit_action'),
                            onPressed: _pickAction,
                            leading: Icons.tune,
                            label: AppStrings.of.kbdEditorAction,
                            tight: tight,
                          ),
                        ],
                      ),
                      SizedBox(height: _cellGap),
                      // Destructive / dismiss actions kept away from the
                      // D-pad so a stray tap while moving a key can't remove
                      // or close it.
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 20, color: c.danger),
                            tooltip: AppStrings.of.kbdEditorDeleteKey,
                            onPressed: _deleteSelected,
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                size: 20, color: c.textSecondary),
                            tooltip: AppStrings.of.kbdEditorDone,
                            onPressed: () => _selectKey(r, k),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _cellGap),
                _buildDpad(r: r, k: k, colCount: row.length, tight: tight),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Right-hand D-pad block — a fixed-width physical cross. The top row is
  /// [blank][↑][blank] so ↑ lands exactly above ↓, the middle of the bottom
  /// row [←][↓][→].
  Widget _buildDpad({
    required int r,
    required int k,
    required int colCount,
    required bool tight,
  }) {
    final cell = tight ? 40.0 : 44.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: cell, height: cell),
            _arrowBtn(
              KeyMoveDir.up,
              icon: Icons.arrow_upward,
              disabled: r == 0 || _rows[r - 1].isEmpty,
              cell: cell,
            ),
            SizedBox(width: cell, height: cell),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _arrowBtn(
              KeyMoveDir.left,
              icon: Icons.arrow_back,
              disabled: k == 0,
              cell: cell,
            ),
            _arrowBtn(
              KeyMoveDir.down,
              icon: Icons.arrow_downward,
              disabled: r >= _rows.length - 1 || _rows[r + 1].isEmpty,
              cell: cell,
            ),
            _arrowBtn(
              KeyMoveDir.right,
              icon: Icons.arrow_forward,
              disabled: k >= colCount - 1,
              cell: cell,
            ),
          ],
        ),
      ],
    );
  }

  Widget _labelField(AppColors c, {required bool tight}) {
    return ConstrainedBox(
      // A key cap is only ~1–3 chars wide — keep the field compact. It still
      // expands to fill leftover space via the parent Expanded.
      constraints: BoxConstraints(maxWidth: tight ? 80 : 140),
      child: TextField(
        controller: _labelController,
        style: TextStyle(color: c.text, fontSize: 13),
        decoration: neonInputDecoration(
          context,
          label: AppStrings.of.kbdEditorKeyLabel,
          hint: AppStrings.of.kbdEditorKeyLabelHint,
        ),
        onChanged: _updateLabel,
      ),
    );
  }

  Widget _arrowBtn(
    KeyMoveDir dir, {
    required IconData icon,
    required bool disabled,
    required double cell,
  }) {
    final c = context.appColors;
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: disabled ? c.textSecondary.withAlpha(80) : c.primary,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: cell, height: cell),
      visualDensity: VisualDensity.compact,
      tooltip: switch (dir) {
        KeyMoveDir.left => AppStrings.of.kbdEditorMoveLeft,
        KeyMoveDir.right => AppStrings.of.kbdEditorMoveRight,
        KeyMoveDir.up => AppStrings.of.kbdEditorMoveUp,
        KeyMoveDir.down => AppStrings.of.kbdEditorMoveDown,
      },
      onPressed: disabled ? null : () => _moveSelected(dir),
    );
  }

  /// A compact outlined action button for the edit bar.
  ///
  /// Both the icon and action pickers share this so they render at the same
  /// height / density and read as one control group. When [active] the button
  /// gets a primary tint to signal an option (e.g. an icon) is currently set.
  Widget _editBtn({
    Key? key,
    required VoidCallback onPressed,
    required IconData leading,
    required String label,
    bool active = false,
    bool tight = false,
  }) {
    final c = context.appColors;
    final icon = Icon(leading, size: 16, color: c.primary);
    return Tooltip(
      message: label,
      child: OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: EdgeInsets.symmetric(
            horizontal: tight ? AppSpacing.one : AppSpacing.two,
          ),
          visualDensity: VisualDensity.compact,
          side: BorderSide(
            color: active ? c.primary : c.border.withAlpha(80),
            width: active ? 1 : 0.5,
          ),
          backgroundColor: active ? c.primary.withAlpha(18) : null,
        ),
        // On narrow widths show only the glyph — the label is dropped and the
        // semantic meaning carried by the tooltip.
        child: tight
            ? icon
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.one),
                  ThemedText.label(label, color: c.primary),
                ],
              ),
      ),
    );
  }
}
