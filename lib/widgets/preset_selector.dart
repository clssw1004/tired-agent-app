import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/session_presets.dart';
import 'package:tired_agent_app/widgets/save_preset_button.dart';
import 'package:tired_agent_app/widgets/session_preset_dropdown.dart';

/// Result reported when a preset is selected.
class PresetSelection {
  final BuiltinPreset? builtin;
  final UserPreset? user;

  const PresetSelection({this.builtin, this.user});
}

/// Self-contained row containing the preset dropdown + save button.
///
/// Owns preset state internally (custom/recent lists, selection, persistence)
/// and reports changes via [onChanged]. The parent can access current state
/// through [PresetSelectorState] via a [GlobalKey].
class PresetSelector extends StatefulWidget {
  /// Agent OS platform — used to filter builtin presets.
  final String? platform;

  /// Current command value (used as label fallback).
  final String cmd;

  /// Current args text (used when saving a preset).
  final String argsText;

  /// Called when the user selects a builtin or user preset.
  final ValueChanged<PresetSelection>? onChanged;

  /// Called when the user saves a new custom preset.
  final ValueChanged<UserPreset>? onSaved;

  const PresetSelector({
    super.key,
    this.platform,
    required this.cmd,
    required this.argsText,
    this.onChanged,
    this.onSaved,
  });

  @override
  PresetSelectorState createState() => PresetSelectorState();
}

class PresetSelectorState extends State<PresetSelector> {
  String? _selectedBuiltinId;
  List<UserPreset> _customPresets = [];
  List<UserPreset> _recentPresets = [];

  static const _kCustomPresets = 'create_session_custom_presets';
  static const _kRecentPresets = 'create_session_recent_presets';
  static const _maxRecent = 5;

  // ── Public accessors ──────────────────────────────────────────────

  String? get selectedBuiltinId => _selectedBuiltinId;

  BuiltinPreset? get selectedPreset =>
      widget.platform == null
          ? builtinPresets.where((p) => p.id == _selectedBuiltinId).firstOrNull
          : builtinPresets.where(
              (p) => (p.platforms == null || p.platforms!.contains(widget.platform)) && p.id == _selectedBuiltinId,
            ).firstOrNull;

  List<BuiltinPreset> get visibleBuiltinPresets {
    if (widget.platform == null) return builtinPresets;
    return builtinPresets.where(
      (p) => p.platforms == null || p.platforms!.contains(widget.platform),
    ).toList();
  }

  List<UserPreset> get customPresets => _customPresets;
  List<UserPreset> get recentPresets => _recentPresets;

  // ── Lifecycle ─────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getString(_kCustomPresets);
    if (customRaw != null) {
      _customPresets = (json.decode(customRaw) as List<dynamic>)
          .map((e) => UserPreset.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final recentRaw = prefs.getString(_kRecentPresets);
    if (recentRaw != null) {
      _recentPresets = (json.decode(recentRaw) as List<dynamic>)
          .map((e) => UserPreset.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCustomPresets,
      json.encode(_customPresets.map((p) => p.toJson()).toList()),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────

  void applyBuiltin(BuiltinPreset p) {
    setState(() => _selectedBuiltinId = p.id);
    widget.onChanged?.call(PresetSelection(builtin: p));
  }

  void applyUserPreset(UserPreset p) {
    setState(() {
      _selectedBuiltinId = null;
    });
    widget.onChanged?.call(PresetSelection(user: p));
  }

  void onSavedPreset(UserPreset p) {
    setState(() => _customPresets.insert(0, p));
    _saveCustomPresets();
    widget.onSaved?.call(p);
  }

  /// Track a recently submitted command.
  void trackRecent(String cmd, List<String> args) {
    _recentPresets.removeWhere((p) => p.cmd == cmd && _listEq(p.args, args));
    _recentPresets.insert(
      0,
      UserPreset(
        id: 'recent_${DateTime.now().millisecondsSinceEpoch}',
        label: cmd,
        cmd: cmd,
        args: args,
        emoji: '\u{1F550}',
      ),
    );
    while (_recentPresets.length > _maxRecent) {
      _recentPresets.removeLast();
    }
    _saveRecentPresets();
  }

  Future<void> _saveRecentPresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kRecentPresets,
      json.encode(_recentPresets.map((p) => p.toJson()).toList()),
    );
  }

  bool _listEq(List<String> a, List<String> b) =>
      a.length == b.length && a.asMap().entries.every((e) => e.value == b[e.key]);

  // ── UI ────────────────────────────────────────────────────────────

  /// Build the current preset label for the dropdown trigger.
  String get _currentLabel {
    final s = selectedPreset;
    if (_selectedBuiltinId != null && s != null) return s.label;
    return widget.cmd;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SessionPresetDropdown(
            currentLabel: _currentLabel,
            hasSelection: _selectedBuiltinId != null,
            emoji: selectedPreset?.emoji ?? '⚡',
            builtinPresets: visibleBuiltinPresets,
            recentPresets: _recentPresets,
            customPresets: _customPresets,
            selectedBuiltinId: _selectedBuiltinId,
            onSelectBuiltin: applyBuiltin,
            onSelectUser: applyUserPreset,
          ),
        ),
        const SizedBox(width: AppSpacing.two),
        SavePresetButton(
          cmd: widget.cmd,
          argsText: widget.argsText,
          onSaved: onSavedPreset,
        ),
      ],
    );
  }
}
