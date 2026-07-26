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

  // ── Custom & recent presets ─────────────────────────────────────
  List<_UserPreset> _customPresets = [];
  List<_UserPreset> _recentPresets = [];

  static const _kCustomPresets = 'create_session_custom_presets';
  static const _kRecentPresets = 'create_session_recent_presets';
  static const _maxRecent = 5;

  /// The currently selected builtin preset, if any.
  BuiltinPreset? get _selectedPreset =>
      builtinPresets.where((p) => p.id == _selectedBuiltinId).firstOrNull;

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
    for (final p in builtinPresets) {
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
            selectedTileColor: AppColors.accent.withAlpha(20),
            title: ThemedText.body(v.label),
            subtitle: v.hint.isNotEmpty ? ThemedText.small(v.hint) : null,
            trailing: sel ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
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
    final preset = _selectedPreset;
    if (preset == null || preset.options.isEmpty) return;
    final temp = Map<String, String?>.from(_optionSelections);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                  child: ThemedText.body('${preset.emoji} ${preset.label} options', color: AppColors.textSecondary),
                ),
                const Divider(height: 1, color: AppColors.border),
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
                                  activeThumbColor: AppColors.primary,
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
                                      color: AppColors.backgroundElement,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ThemedText.small(
                                          sel ?? 'Select…',
                                          color: sel != null ? AppColors.text : AppColors.textSecondary,
                                        ),
                                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
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
                const Divider(height: 1, color: AppColors.border),
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
    showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ThemedText.body(opt.label, color: AppColors.textSecondary),
            ),
            ...opt.values.map((v) {
              final sel = v.label == target[opt.id];
              return ListTile(
                selected: sel,
                selectedTileColor: AppColors.accent.withAlpha(20),
                title: ThemedText.body(v.label),
                subtitle: v.hint.isNotEmpty ? ThemedText.small(v.hint) : null,
                trailing: sel ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
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
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not connected'), backgroundColor: AppColors.danger),
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
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: ThemedText.title('New Session'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: AppColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.four),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Preset dropdown + Save ─────────────────────────────
            Row(
              children: [
                Expanded(child: _buildPresetDropdown()),
                const SizedBox(width: AppSpacing.two),
                GestureDetector(
                  onTap: _showAddCustomPresetDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: AppSpacing.one),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElement,
                      borderRadius: BorderRadius.circular(AppSpacing.one),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        ThemedText.small('Save', color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.three),

            // ── Command preview ──────────────────────────────────
            if (_previewCommand.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.two),
                decoration: BoxDecoration(
                  color: AppColors.codeBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.two),
                ),
                child: ThemedText.code(_previewCommand),
              ),
              const SizedBox(height: AppSpacing.two),
            ],

            // ── Command ─────────────────────────────────────────
            ThemedText.small('Command', color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.two),
            TextField(
              controller: TextEditingController.fromValue(TextEditingValue(text: _cmd)),
              onChanged: (v) => setState(() => _cmd = v),
              style: const TextStyle(fontFamily: 'monospace', color: AppColors.textCode),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.three, vertical: AppSpacing.two),
              ),
            ),
            const SizedBox(height: AppSpacing.three),

            // ── Args ────────────────────────────────────────────
            ThemedText.small('Arguments (space-separated)', color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.one),
            TextField(
              controller: _argsController,
              style: const TextStyle(fontFamily: 'monospace', color: AppColors.textCode),
              decoration: const InputDecoration(
                hintText: '--no-input',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.three, vertical: AppSpacing.two),
              ),
              onChanged: (_) => setState(() {}),
              enabled: !_busy,
            ),

            // ── Option chips (inline + more) ────────────────────
            if (_selectedPreset != null && _selectedPreset!.options.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.two),
              _buildOptionChips(),
            ],

            const SizedBox(height: AppSpacing.four),

            // ── Label ───────────────────────────────────────────
            ThemedText.small('Label (optional)', color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.one),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                hintText: 'Leave empty to auto-generate',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.three, vertical: AppSpacing.two),
              ),
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.three),

            // ── Working directory ───────────────────────────────
            ThemedText.small('Working directory', color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.one),
            GestureDetector(
              onTap: _busy ? null : _pickDirectory,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.three),
                decoration: BoxDecoration(
                  color: AppColors.backgroundElement,
                  borderRadius: BorderRadius.circular(AppSpacing.two),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: AppSpacing.two),
                    Expanded(
                      child: ThemedText.body(
                        _cwdController.text.isNotEmpty ? _cwdController.text : 'Agent home directory',
                        color: _cwdController.text.isNotEmpty ? AppColors.text : AppColors.textSecondary,
                      ),
                    ),
                    if (_cwdController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _cwdController.clear(),
                        child: const Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.two),
            ThemedText.small(
              'Terminal size auto-matches after session starts',
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.six),

            // ── Submit ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.backgroundElement),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.three),
                    ),
                    child: ThemedText.body('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.three),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _busy || _cmd.trim().isEmpty ? null : _submit,
                    child: _busy ? const NeonLoading(size: 20) : Text('Create session'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildPresetDropdown() {
    final items = _dropdownItems;
    final selectedPresetLabel = _selectedPreset?.label;

    String currentLabel;
    if (_selectedBuiltinId != null && selectedPresetLabel != null) {
      currentLabel = selectedPresetLabel;
    } else {
      currentLabel = _cmd;
    }

    return GestureDetector(
      onTap: () => _showPresetPicker(items),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.three, vertical: AppSpacing.two),
        decoration: BoxDecoration(
          color: AppColors.backgroundElement,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(color: AppColors.border.withAlpha(60), width: 0.5),
        ),
        child: Row(
          children: [
            if (_selectedPreset != null) ...[
              Text(_selectedPreset!.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.one),
            ],
            Expanded(
              child: ThemedText.body(currentLabel, color: AppColors.text),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPresetPicker(List<_DropdownItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.four),
            child: ThemedText.body('Select preset', color: AppColors.textSecondary),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                if (item.isSeparator) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: ThemedText.small(
                      item.separatorLabel ?? '',
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                final isActive = item.builtin != null && item.builtin!.id == _selectedBuiltinId;
                return ListTile(
                  dense: true,
                  leading: Text(item.emoji, style: const TextStyle(fontSize: 18)),
                  title: ThemedText.body(item.label),
                  selected: isActive,
                  selectedTileColor: AppColors.accent.withAlpha(20),
                  trailing: isActive ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (item.builtin != null) {
                      _applyBuiltin(item.builtin!);
                    } else if (item.user != null) {
                      _applyUserPreset(item.user!);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionChips() {
    final preset = _selectedPreset!;
    final options = preset.options;
    final inline = options.take(inlineOptionLimit).toList();
    final overflow = options.length > inlineOptionLimit ? options.skip(inlineOptionLimit).toList() : <PresetOption>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.two,
          runSpacing: AppSpacing.one,
          children: [
            ...inline.map(_buildOptionChip),
            if (overflow.isNotEmpty)
              GestureDetector(
                onTap: _showAllOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: AppSpacing.one),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundElement,
                    borderRadius: BorderRadius.circular(AppSpacing.three),
                    border: Border.all(color: AppColors.border.withAlpha(40), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ThemedText.small('+${overflow.length} more', color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionChip(PresetOption opt) {
    final sel = _optionSelections[opt.id];
    final isActive = sel != null;
    final displayLabel = isActive ? '${opt.label}: $sel' : opt.label;

    return GestureDetector(
      onTap: () => _toggleOption(opt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: AppSpacing.one),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceAlt : AppColors.backgroundElement,
          borderRadius: BorderRadius.circular(AppSpacing.three),
          border: Border.all(
            color: isActive ? AppColors.primary.withAlpha(80) : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedText.small(
              displayLabel,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            if (!opt.isToggle) ...[
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textSecondary),
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
