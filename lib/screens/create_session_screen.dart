import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/session_presets.dart';
import 'package:tired_agent_app/widgets/directory_picker_modal.dart';
import 'package:tired_agent_app/widgets/neon_dialog.dart';
import 'package:tired_agent_app/widgets/neon_loading.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

const _labelChars = 'abcdefghijkmnpqrstuvwxyz23456789';

String _generateDefaultLabel() {
  final rnd = List.generate(
    8,
    (_) => _labelChars[Random().nextInt(_labelChars.length)],
  ).join();
  final now = DateTime.now();
  String pad(int n) => n.toString().padLeft(2, '0');
  final stamp =
      '${now.year}${pad(now.month)}${pad(now.day)}T${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';
  return '${rnd}_$stamp';
}

/// A user-defined or recently-used command preset, persisted locally.
class _UserPreset {
  final String id;
  final String label;
  final String cmd;
  final List<String> args;
  final String emoji;
  const _UserPreset({
    required this.id,
    required this.label,
    required this.cmd,
    this.args = const [],
    this.emoji = '⚡',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'cmd': cmd,
    'args': args,
    'emoji': emoji,
  };

  factory _UserPreset.fromJson(Map<String, dynamic> json) => _UserPreset(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    cmd: json['cmd'] as String? ?? '',
    args: (json['args'] as List<dynamic>?)?.cast<String>() ?? [],
    emoji: json['emoji'] as String? ?? '⚡',
  );
}

class CreateSessionScreen extends StatefulWidget {
  final String profileId;
  final String agentId;

  const CreateSessionScreen({
    super.key,
    required this.profileId,
    required this.agentId,
  });

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _argsController = TextEditingController();
  final _cwdController = TextEditingController();
  final _labelController = TextEditingController();

  String _cmd = 'bash';
  /// Which builtin preset is currently active (by id), null = custom/manual.
  String? _selectedBuiltinId;
  /// optionId → selected value label. A missing key or null = unselected.
  final Map<String, String?> _optionSelections = {};
  bool _busy = false;

  /// Agent OS platform — used to filter builtin presets.
  /// `null` = platform unknown (show all presets).
  String? _platform;

  /// Builtin presets filtered by [PlatformInfo.os].
  List<BuiltinPreset> get _visibleBuiltinPresets {
    if (_platform == null) return builtinPresets;
    return builtinPresets.where(
      (p) => p.platforms == null || p.platforms!.contains(_platform),
    ).toList();
  }

  /// The currently selected builtin preset (from filtered list).
  BuiltinPreset? get _selectedPreset =>
      _visibleBuiltinPresets.where((p) => p.id == _selectedBuiltinId).firstOrNull;

  // ── Custom & recent presets ─────────────────────────────────────
  List<_UserPreset> _customPresets = [];
  List<_UserPreset> _recentPresets = [];

  static const _kCustomPresets = 'create_session_custom_presets';
  static const _kRecentPresets = 'create_session_recent_presets';
  static const _maxRecent = 5;

  /// Assemble effective args from option selections + manual args.
  List<String> get _effectiveArgs {
    final preset = _selectedPreset;
    if (preset == null) return [];
    final args = <String>[];
    for (final opt in preset.options) {
      final label = _optionSelections[opt.id];
      if (label == null) continue;
      final value = opt.values.firstWhere(
        (v) => v.label == label,
        orElse: () => opt.values.first,
      );
      args.addAll(value.args);
    }
    return args;
  }

  /// Full command string for display.
  String get _previewCommand {
    final c = _cmd.trim();
    if (c.isEmpty) return '';
    final parts = [c];
    parts.addAll(_effectiveArgs);
    final manualArgs = _argsController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty);
    parts.addAll(manualArgs);
    return parts.join(' ');
  }

  /// All presets for the dropdown: builtin → Recent → Custom.
  List<_DropdownItem> get _dropdownItems {
    final items = <_DropdownItem>[];
    for (final p in _visibleBuiltinPresets) {
      items.add(_DropdownItem.builtin(p));
    }
    if (_recentPresets.isNotEmpty) {
      items.add(_DropdownItem.separator('Recent'));
      for (final p in _recentPresets) {
        items.add(_DropdownItem.user(p));
      }
    }
    if (_customPresets.isNotEmpty) {
      items.add(_DropdownItem.separator('Custom'));
      for (final p in _customPresets) {
        items.add(_DropdownItem.user(p));
      }
    }
    return items;
  }

  void _applyBuiltin(BuiltinPreset p) {
    setState(() {
      _selectedBuiltinId = p.id;
      _cmd = p.cmd;
      _optionSelections.clear();
      _argsController.clear();
      _labelController.clear();
    });
  }

  void _applyUserPreset(_UserPreset p) {
    setState(() {
      _selectedBuiltinId = null;
      _cmd = p.cmd;
      _optionSelections.clear();
      _argsController.text = p.args.join(' ');
      _labelController.clear();
    });
  }

  void _toggleOption(PresetOption opt) {
    if (opt.isToggle) {
      // Single-value toggle: on ↔ off
      setState(() {
        if (_optionSelections[opt.id] != null) {
          _optionSelections.remove(opt.id);
        } else {
          _optionSelections[opt.id] = opt.values.first.label;
        }
      });
    } else {
      // Multi-value picker: show dialog
      _showOptionPicker(opt);
    }
  }

  void _showOptionPicker(PresetOption opt) {
    final c = context.appColors;
    final current = _optionSelections[opt.id];
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
            trailing: sel ? Icon(Icons.check, color: c.primary, size: 18) : null,
            onTap: () => Navigator.of(context).pop(sel ? null : v.label),
            dense: true,
          );
        }).toList(),
      ),
      actions: [
        NeonDialogAction<String>(
          label: 'Cancel',
          onPressed: (c) => Navigator.of(c).pop(),
        ),
      ],
    ).then((result) {
      setState(() {
        if (result == null) {
          _optionSelections.remove(opt.id);
        } else {
          _optionSelections[opt.id] = result;
        }
      });
    });
  }

  /// Show the full options dialog ("More" button).
  void _showAllOptions() {
    final c = context.appColors;
    final preset = _selectedPreset;
    if (preset == null || preset.options.isEmpty) return;
    final temp = Map<String, String?>.from(_optionSelections);

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
                  child: ThemedText.body('${preset.emoji} ${preset.label} options', color: c.textSecondary),
                ),
                Divider(height: 1, color: c.border),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  onTap: () {
                                    _showValuePicker(opt, temp, setSheetState);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: c.backgroundElement,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ThemedText.small(
                                          sel ?? 'Select…',
                                          color: sel != null ? c.text : c.textSecondary,
                                        ),
                                        Icon(Icons.arrow_drop_down, size: 16, color: c.textSecondary),
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
                        child: ThemedText.body('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(temp),
                        child: ThemedText.body('Apply'),
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
        setState(() {
          _optionSelections
            ..clear()
            ..addAll(result as Map<String, String?>);
        });
      }
    });
  }

  void _showValuePicker(PresetOption opt, Map<String, String?> target, void Function(void Function()) setSheetState) {
    final c = context.appColors;
    showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: c.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ThemedText.body(opt.label, color: c.textSecondary),
            ),
            ...opt.values.map((v) {
              final sel = v.label == target[opt.id];
              return ListTile(
                selected: sel,
                selectedTileColor: c.accent.withAlpha(20),
                title: ThemedText.body(v.label),
                subtitle: v.hint.isNotEmpty ? ThemedText.small(v.hint) : null,
                trailing: sel ? Icon(Icons.check, color: c.primary, size: 18) : null,
                onTap: () => Navigator.of(ctx).pop(v.label),
                dense: true,
              );
            }),
          ],
        ),
      ),
    ).then((result) {
      if (result != null) {
        setSheetState(() {
          target[opt.id] = result;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Read agent platform from cache (agents already loaded by this point).
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn != null) {
      final agent = conn.agents.where(
        (a) => a.id == widget.agentId,
      ).firstOrNull;
      _platform = agent?.platform?.os;
    }
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getString(_kCustomPresets);
    if (customRaw != null) {
      final list = json.decode(customRaw) as List<dynamic>;
      _customPresets = list
          .map((e) => _UserPreset.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final recentRaw = prefs.getString(_kRecentPresets);
    if (recentRaw != null) {
      final list = json.decode(recentRaw) as List<dynamic>;
      _recentPresets = list
          .map((e) => _UserPreset.fromJson(e as Map<String, dynamic>))
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

  Future<void> _saveRecentPresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kRecentPresets,
      json.encode(_recentPresets.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> _submit() async {
    final c = context.appColors;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Not connected'), backgroundColor: c.danger),
          );
        }
        return;
      }
      await conn.ensureFreshSession();
      final mgrRef = ServerRef(
        id: '__manager__',
        name: conn.profile.name,
        baseUrl: conn.profile.baseUrl,
        token: conn.profile.sessionToken!,
      );

      final manualArgs = _argsController.text
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
      final finalArgs = [..._effectiveArgs, ...manualArgs];

      final spec = SessionSpec(
        cmd: _cmd.trim(),
        args: finalArgs.isNotEmpty ? finalArgs : null,
        cwd: _cwdController.text.trim().isNotEmpty ? _cwdController.text.trim() : null,
        label: _labelController.text.trim().isNotEmpty ? _labelController.text.trim() : _generateDefaultLabel(),
        cols: 80,
        rows: 24,
        mode: SessionMode.process,
      );

      final session = await conn.transport.createSession(mgrRef, spec, agentId: widget.agentId);

      if (mounted) {
        _trackRecent(_cmd.trim(), manualArgs);
        context.replace('/session/${widget.profileId}/${widget.agentId}/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: c.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _trackRecent(String cmd, List<String> args) {
    _recentPresets.removeWhere((p) => p.cmd == cmd && _listEq(p.args, args));
    _recentPresets.insert(
      0,
      _UserPreset(
        id: 'recent_${DateTime.now().millisecondsSinceEpoch}',
        label: cmd,
        cmd: cmd,
        args: args,
        emoji: '🕐',
      ),
    );
    while (_recentPresets.length > _maxRecent) {
      _recentPresets.removeLast();
    }
    _saveRecentPresets();
  }

  bool _listEq(List<String> a, List<String> b) =>
      a.length == b.length && a.asMap().entries.every((e) => e.value == b[e.key]);

  Future<void> _showAddCustomPresetDialog() async {
    final labelCtrl = TextEditingController(text: _cmd);
    final result = await NeonDialog.show<_UserPreset>(
      context: context,
      title: 'Save as preset',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedText.small('Preset name'),
          TextField(controller: labelCtrl, autofocus: true, decoration: const InputDecoration(isDense: true)),
        ],
      ),
      actions: [
        NeonDialogAction<_UserPreset>(
          label: 'Cancel',
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        NeonDialogAction<_UserPreset>(
          label: 'Save',
          isPrimary: true,
          onPressed: (ctx) {
            final label = labelCtrl.text.trim();
            if (label.isEmpty) return;
            final manualArgs = _argsController.text
                .trim()
                .split(RegExp(r'\s+'))
                .where((s) => s.isNotEmpty)
                .toList();
            Navigator.of(ctx).pop(_UserPreset(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              label: label,
              cmd: _cmd.trim(),
              args: manualArgs,
              emoji: '⚡',
            ));
          },
        ),
      ],
    );
    if (result != null) {
      setState(() => _customPresets.insert(0, result));
      await _saveCustomPresets();
    }
  }


  Future<void> _pickDirectory() async {
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn == null || conn.profile.sessionToken == null) return;
    await conn.ensureFreshSession();
    final mgrRef = ServerRef(
      id: '__manager__',
      name: conn.profile.name,
      baseUrl: conn.profile.baseUrl,
      token: conn.profile.sessionToken!,
    );
    final path = await DirectoryPickerModal.show(
      context,
      serverRef: mgrRef,
      agentId: widget.agentId,
      initialPath: _cwdController.text.isNotEmpty ? _cwdController.text : null,
    );
    if (path != null && mounted) {
      _cwdController.text = path;
    }
  }

  @override
  void dispose() {
    _argsController.dispose();
    _cwdController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  /// Neon section header: monospace uppercase label + cyan accent line.
  Widget _sectionHeader(String label) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.two),
      child: Row(
        children: [
          ThemedText.mono(label.toUpperCase(), color: c.primary),
          const SizedBox(width: AppSpacing.two),
          Expanded(
            child: Container(height: 1, color: c.primary.withAlpha(40)),
          ),
        ],
      ),
    );
  }

  /// Shared [InputDecoration] for neon-styled text fields.
  InputDecoration _neonInput({String? hint, String? prefixText}) {
    final c = context.appColors;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontFamily: 'monospace',
        color: c.primary.withAlpha(140),
        fontSize: 13,
      ),
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.border.withAlpha(60)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.border.withAlpha(60)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.primary.withAlpha(100), width: 1),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.border.withAlpha(30)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.mono('NEW SESSION', color: c.primary),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: c.primary.withAlpha(80)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.four),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PRESET ─────────────────────────────────────────
            _sectionHeader('Preset'),
            Row(
              children: [
                Expanded(child: _buildPresetDropdown()),
                const SizedBox(width: AppSpacing.two),
                _buildSavePresetButton(),
              ],
            ),
            const SizedBox(height: AppSpacing.four),

            // ── TERMINAL PREVIEW ──────────────────────────────
            if (_previewCommand.isNotEmpty) ...[
              _sectionHeader('Preview'),
              _buildTerminalPreview(),
              const SizedBox(height: AppSpacing.four),
            ],

            // ── COMMAND ───────────────────────────────────────
            _sectionHeader('Command'),
            TextField(
              controller: TextEditingController.fromValue(
                TextEditingValue(text: _cmd),
              ),
              onChanged: (v) => setState(() => _cmd = v),
              style: TextStyle(
                fontFamily: 'monospace',
                color: c.textCode,
                fontSize: 14,
              ),
              decoration: _neonInput(prefixText: r'$ '),
            ),
            const SizedBox(height: AppSpacing.four),

            // ── ARGUMENTS ─────────────────────────────────────
            _sectionHeader('Arguments'),
            TextField(
              controller: _argsController,
              style: TextStyle(
                fontFamily: 'monospace',
                color: c.textCode,
                fontSize: 14,
              ),
              decoration: _neonInput(hint: '--no-input  --verbose'),
              onChanged: (_) => setState(() {}),
              enabled: !_busy,
            ),

            // ── OPTIONS ───────────────────────────────────────
            if (_selectedPreset != null &&
                _selectedPreset!.options.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.four),
              _sectionHeader('Options'),
              _buildOptionChips(),
            ],

            const SizedBox(height: AppSpacing.four),

            // ── LABEL ─────────────────────────────────────────
            _sectionHeader('Session label'),
            TextField(
              controller: _labelController,
              style: TextStyle(color: c.text, fontSize: 14),
              decoration: _neonInput(hint: 'Auto-generated if empty'),
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.four),

            // ── WORKING DIRECTORY ────────────────────────────
            _sectionHeader('Working directory'),
            _buildDirectoryPicker(),
            const SizedBox(height: AppSpacing.two),
            ThemedText.mono(
              'Terminal size auto-matches after session starts',
              color: c.textSecondary.withAlpha(120),
            ),
            const SizedBox(height: AppSpacing.six),

            // ── SUBMIT ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      side: BorderSide(color: c.border.withAlpha(60)),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.four,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.two),
                      ),
                    ),
                    child: ThemedText.mono('CANCEL'),
                  ),
                ),
                const SizedBox(width: AppSpacing.three),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _busy || _cmd.trim().isEmpty ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.surfaceAlt,
                      foregroundColor: c.primary,
                      disabledBackgroundColor: c.border.withAlpha(60),
                      disabledForegroundColor: c.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.four,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.two),
                        side: BorderSide(
                          color: c.primary.withAlpha(
                            _busy || _cmd.trim().isEmpty ? 20 : 100,
                          ),
                          width: 1,
                        ),
                      ),
                      elevation: 4,
                      shadowColor: c.primary.withAlpha(30),
                    ),
                    child: _busy
                        ? NeonLoading(size: 20)
                        : ThemedText.mono('LAUNCH', color: c.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build sub-widgets ──────────────────────────────────────────────────

  Widget _buildSavePresetButton() {
    final c = context.appColors;
    return GestureDetector(
      onTap: _showAddCustomPresetDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.two,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(
            color: c.primary.withAlpha(50),
            width: 0.5,
          ),
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
            ThemedText.mono('SAVE', color: c.primary.withAlpha(180)),
          ],
        ),
      ),
    );
  }

  /// Terminal-style command preview window with title bar.
  Widget _buildTerminalPreview() {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(AppSpacing.two),
        border: Border.all(color: c.primary.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: c.primary.withAlpha(12),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar — traffic-light dots + prompt label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.three,
              vertical: AppSpacing.one,
            ),
            decoration: BoxDecoration(
              color: c.surfaceAlt.withAlpha(120),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.two - 1),
              ),
              border: Border(
                bottom: BorderSide(
                  color: c.primary.withAlpha(30),
                ),
              ),
            ),
            child: Row(
              children: [
                // Traffic-light dots
                ...[0xFF003C, 0xFF6600, 0x00FF41].map((hex) {
                  final c = Color(hex | 0xFF000000);
                  return Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: c.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
                const SizedBox(width: AppSpacing.two),
                ThemedText.mono(
                  _cmd,
                  color: c.primary.withAlpha(140),
                ),
                const Spacer(),
                ThemedText.mono(
                  '---',
                  color: c.textSecondary.withAlpha(60),
                ),
              ],
            ),
          ),
          // Command content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.three),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText.mono(
                  r'$ ',
                  color: c.success.withAlpha(180),
                ),
                Expanded(
                  child: ThemedText.code(_previewCommand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetDropdown() {
    final c = context.appColors;
    final items = _dropdownItems;
    final selectedPresetLabel = _selectedPreset?.label;

    String currentLabel;
    if (_selectedBuiltinId != null && selectedPresetLabel != null) {
      currentLabel = selectedPresetLabel;
    } else {
      currentLabel = _cmd;
    }

    final hasSelection = _selectedBuiltinId != null;

    return GestureDetector(
      onTap: () => _showPresetPicker(items),
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
              ? [
                  BoxShadow(
                    color: c.primary.withAlpha(15),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (_selectedPreset != null) ...[
              Text(_selectedPreset!.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.one),
            ],
            Expanded(
              child: ThemedText.mono(
                currentLabel,
                color: hasSelection ? c.primary : c.text,
              ),
            ),
            Icon(
              Icons.unfold_more,
              color: c.primary.withAlpha(140),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetPicker(List<_DropdownItem> items) {
    final c = context.appColors;
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
                Icon(
                  Icons.terminal,
                  color: c.primary.withAlpha(180),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.two),
                ThemedText.mono('SELECT PRESET', color: c.primary),
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
                      AppSpacing.four, AppSpacing.two,
                      AppSpacing.four, AppSpacing.one,
                    ),
                    child: ThemedText.mono(
                      item.separatorLabel ?? '',
                      color: c.primary.withAlpha(120),
                    ),
                  );
                }
                final isActive = item.builtin != null &&
                    item.builtin!.id == _selectedBuiltinId;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.two, vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? c.primary.withAlpha(10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.two),
                    border: isActive
                        ? Border.all(
                            color: c.primary.withAlpha(40),
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Text(item.emoji, style: const TextStyle(fontSize: 18)),
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
                        _applyBuiltin(item.builtin!);
                      } else if (item.user != null) {
                        _applyUserPreset(item.user!);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryPicker() {
    final c = context.appColors;
    final hasPath = _cwdController.text.isNotEmpty;
    return GestureDetector(
      onTap: _busy ? null : _pickDirectory,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.three),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(
            color: hasPath
                ? c.primary.withAlpha(60)
                : c.border.withAlpha(60),
            width: hasPath ? 1 : 0.5,
          ),
          boxShadow: hasPath
              ? [
                  BoxShadow(
                    color: c.primary.withAlpha(10),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder_outlined,
              color: hasPath ? c.primary : c.textSecondary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.two),
            Expanded(
              child: ThemedText.mono(
                hasPath ? _cwdController.text : 'Agent home directory',
                color: hasPath ? c.textCode : c.textSecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasPath)
              GestureDetector(
                onTap: () => _cwdController.clear(),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: c.textSecondary.withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Icon(Icons.close, size: 14, color: c.textSecondary),
                ),
              ),
            const SizedBox(width: AppSpacing.two),
            Icon(
              Icons.chevron_right,
              color: c.primary.withAlpha(120),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChips() {
    final preset = _selectedPreset!;
    final options = preset.options;
    final inline = options.take(inlineOptionLimit).toList();
    final overflow = options.length > inlineOptionLimit
        ? options.skip(inlineOptionLimit).toList()
        : <PresetOption>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.two,
          runSpacing: AppSpacing.one,
          children: [
            ...inline.map(_buildOptionChip),
            if (overflow.isNotEmpty) _buildMoreButton(overflow.length),
          ],
        ),
      ],
    );
  }

  Widget _buildMoreButton(int count) {
    final c = context.appColors;
    return GestureDetector(
      onTap: _showAllOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.one,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.three),
          border: Border.all(
            color: c.primary.withAlpha(50),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedText.mono(
              '+$count',
              color: c.primary.withAlpha(180),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 14,
              color: c.primary.withAlpha(180),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip(PresetOption opt) {
    final c = context.appColors;
    final sel = _optionSelections[opt.id];
    final isActive = sel != null;
    final displayLabel = isActive ? '${opt.label}: $sel' : opt.label;

    return GestureDetector(
      onTap: () => _toggleOption(opt),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.two,
          vertical: AppSpacing.one,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? c.primary.withAlpha(8)
              : c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.three),
          border: Border.all(
            color: isActive
                ? c.primary.withAlpha(100)
                : c.border.withAlpha(40),
            width: isActive ? 1 : 0.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: c.primary.withAlpha(15),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedText.mono(
              displayLabel,
              color: isActive ? c.primary : c.textSecondary,
            ),
            if (!opt.isToggle) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down,
                size: 14,
                color: isActive
                    ? c.primary.withAlpha(180)
                    : c.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Internal helper for the preset dropdown bottom sheet.
class _DropdownItem {
  final BuiltinPreset? builtin;
  final _UserPreset? user;
  final String? separatorLabel;
  _DropdownItem._({this.builtin, this.user, this.separatorLabel});
  factory _DropdownItem.builtin(BuiltinPreset p) => _DropdownItem._(builtin: p);
  factory _DropdownItem.user(_UserPreset p) => _DropdownItem._(user: p);
  factory _DropdownItem.separator(String label) => _DropdownItem._(separatorLabel: label);

  bool get isSeparator => separatorLabel != null;
  String get label => builtin?.label ?? user?.label ?? separatorLabel ?? '';
  String get emoji => builtin?.emoji ?? user?.emoji ?? '';
}
