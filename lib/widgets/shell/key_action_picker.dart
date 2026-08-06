import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// Result of the key action picker.
///
/// `def` is `null` when the user chose to clear/disable the key slot.
class KeyActionPickerResult {
  final TerminalKeyDef? def;
  final bool cleared;
  const KeyActionPickerResult._(this.def) : cleared = def == null;

  const KeyActionPickerResult.picked(TerminalKeyDef def) : this._(def);
  const KeyActionPickerResult.cleared() : this._(null);
}

/// Bottom-sheet picker that lets the user choose what a single keyboard key
/// does: a builtin key from the catalog, or a custom text command.
///
/// Returns a [KeyActionPickerResult] via `Navigator.pop`. The caller passes the
/// current definition so the sheet can pre-fill the custom-command form.
class KeyActionPicker {
  KeyActionPicker._();

  static Future<KeyActionPickerResult?> show(
    BuildContext context, {
    TerminalKeyDef? current,
  }) {
    return showModalBottomSheet<KeyActionPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KeyActionSheet(current: current),
    );
  }
}

class _KeyActionSheet extends StatefulWidget {
  final TerminalKeyDef? current;
  const _KeyActionSheet({this.current});

  @override
  State<_KeyActionSheet> createState() => _KeyActionSheetState();
}

class _KeyActionSheetState extends State<_KeyActionSheet> {
  final _labelController = TextEditingController();
  final _commandController = TextEditingController();
  bool _withEnter = false;
  bool _confirm = false;

  static const _modifiers = [TerminalKeys.ctrl, TerminalKeys.alt, TerminalKeys.shift];
  static const _nav = [
    TerminalKeys.up,
    TerminalKeys.down,
    TerminalKeys.left,
    TerminalKeys.right,
    TerminalKeys.home,
    TerminalKeys.end,
    TerminalKeys.pageUp,
    TerminalKeys.pageDown,
  ];
  static const _special = [
    TerminalKeys.tab,
    TerminalKeys.escape,
    TerminalKeys.enter,
    TerminalKeys.backspace,
    TerminalKeys.delete,
    TerminalKeys.space,
  ];
  static const _function = [
    TerminalKeys.f1,
    TerminalKeys.f2,
    TerminalKeys.f3,
    TerminalKeys.f4,
    TerminalKeys.f5,
    TerminalKeys.f6,
    TerminalKeys.f7,
    TerminalKeys.f8,
    TerminalKeys.f9,
    TerminalKeys.f10,
    TerminalKeys.f11,
    TerminalKeys.f12,
  ];
  static const _symbols = [
    TerminalKeys.space,
    TerminalKeys.dot,
    TerminalKeys.comma,
    TerminalKeys.semicolon,
    TerminalKeys.colon,
    TerminalKeys.slash,
    TerminalKeys.backslash,
    TerminalKeys.minus,
    TerminalKeys.equal,
    TerminalKeys.backquote,
    TerminalKeys.bracketLeft,
    TerminalKeys.bracketRight,
    TerminalKeys.quote,
  ];

  /// Common combo shortcuts worth one-tap access.
  static final _combos = <TerminalKeyDef>[
    TerminalKeys.combo([TerminalKeyCode.ctrl, TerminalKeyCode.c]),
    TerminalKeys.combo([TerminalKeyCode.ctrl, TerminalKeyCode.d]),
    TerminalKeys.combo([TerminalKeyCode.ctrl, TerminalKeyCode.l]),
    TerminalKeys.combo([TerminalKeyCode.ctrl, TerminalKeyCode.a]),
    TerminalKeys.combo([TerminalKeyCode.ctrl, TerminalKeyCode.z]),
    TerminalKeys.combo([TerminalKeyCode.ctrl, TerminalKeyCode.w]),
    TerminalKeys.combo([TerminalKeyCode.ctrl, TerminalKeyCode.u]),
    TerminalKeys.combo([TerminalKeyCode.shift, TerminalKeyCode.tab]),
  ];

  @override
  void initState() {
    super.initState();
    final cur = widget.current;
    if (cur != null && cur.bytes.isNotEmpty && !cur.isMod) {
      // Pre-fill custom command form from an existing text/command key.
      final bytes = cur.bytes;
      final trailingEnter = bytes.length > 1 && bytes.last == 0x0D;
      final command = String.fromCharCodes(
        trailingEnter ? bytes.sublist(0, bytes.length - 1) : bytes,
      );
      _commandController.text = command;
      _labelController.text = cur.label;
      _withEnter = trailingEnter;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _pick(TerminalKeyDef def) {
    Navigator.of(context).pop(KeyActionPickerResult.picked(def));
  }

  void _clear() {
    Navigator.of(context).pop(const KeyActionPickerResult.cleared());
  }

  void _applyCustom() {
    final command = _commandController.text;
    if (command.isEmpty) return;
    final label = _labelController.text.trim();
    _pick(
      TerminalKeys.commandShowText(
        label: label.isEmpty ? command : label,
        command: command,
        withEnter: _withEnter,
        confirm: _confirm,
        confirmMessage: _confirm
            ? 'Execute [$command]?'
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
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
                Icon(Icons.keyboard, color: c.primary, size: 20),
                const SizedBox(width: AppSpacing.two),
                Expanded(
                  child: ThemedText.title(
                    AppStrings.of.kbdPickerTitle,
                    color: c.text,
                  ),
                ),
                if (widget.current != null)
                  TextButton(
                    onPressed: _clear,
                    child: ThemedText.small(
                      AppStrings.of.kbdPickerClear,
                      color: c.danger,
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.three),
              children: [
                _catalogSection(
                  AppStrings.of.kbdPickerModifiers,
                  _modifiers,
                ),
                _catalogSection(AppStrings.of.kbdPickerNav, _nav),
                _catalogSection(AppStrings.of.kbdPickerSpecial, _special),
                _catalogSection(AppStrings.of.kbdPickerFunction, _function),
                _catalogSection(AppStrings.of.kbdPickerCombos, _combos),
                _catalogSection(AppStrings.of.kbdPickerSymbols, _symbols),
                const SizedBox(height: AppSpacing.two),
                _buildCustomSection(c),
                SizedBox(height: bottomInset),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catalogSection(String title, List<TerminalKeyDef> keys) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.three),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedText.label(title, color: c.primary),
          const SizedBox(height: AppSpacing.one),
          Wrap(
            spacing: AppSpacing.two,
            runSpacing: AppSpacing.one,
            children: keys.map(_catalogChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _catalogChip(TerminalKeyDef def) {
    final c = context.appColors;
    final active = widget.current?.id == def.id;
    return GestureDetector(
      onTap: () => _pick(def),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.one,
        ),
        decoration: BoxDecoration(
          color: active ? c.primary.withAlpha(20) : c.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? c.primary : c.border.withAlpha(80),
            width: active ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (def.icon != null) ...[
              Icon(def.icon, size: 14, color: c.textCode),
              const SizedBox(width: 4),
            ],
            ThemedText.label(
              def.label,
              color: active ? c.primary : c.textCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSection(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.three),
      decoration: BoxDecoration(
        color: c.surfaceAlt.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border.withAlpha(60), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedText.label(AppStrings.of.kbdPickerCustom, color: c.primary),
          const SizedBox(height: AppSpacing.two),
          TextField(
            controller: _commandController,
            style: TextStyle(fontFamily: 'monospace', color: c.textCode, fontSize: 13),
            decoration: InputDecoration(
              hintText: AppStrings.of.kbdPickerCommandHint,
              hintStyle: TextStyle(color: c.textSecondary.withAlpha(140), fontSize: 13),
              isDense: true,
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: c.border, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.two),
          TextField(
            controller: _labelController,
            style: TextStyle(color: c.text, fontSize: 13),
            decoration: InputDecoration(
              hintText: AppStrings.of.kbdPickerLabelHint,
              hintStyle: TextStyle(color: c.textSecondary.withAlpha(140), fontSize: 13),
              isDense: true,
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: c.border, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.one),
          Row(
            children: [
              _CheckboxChip(
                label: AppStrings.of.kbdPickerWithEnter,
                value: _withEnter,
                onChanged: (v) => setState(() => _withEnter = v),
              ),
              const SizedBox(width: AppSpacing.two),
              _CheckboxChip(
                label: AppStrings.of.kbdPickerConfirm,
                value: _confirm,
                onChanged: (v) => setState(() => _confirm = v),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.four,
                  ),
                ),
                onPressed: _applyCustom,
                child: ThemedText.label(AppStrings.of.kbdPickerApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckboxChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckboxChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: value ? c.primary.withAlpha(20) : c.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? c.primary : c.border.withAlpha(80),
            width: value ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 14,
              color: value ? c.primary : c.textSecondary,
            ),
            const SizedBox(width: 4),
            ThemedText.label(label, color: c.text),
          ],
        ),
      ),
    );
  }
}
