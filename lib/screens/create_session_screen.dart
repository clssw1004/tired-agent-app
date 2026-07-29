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

import 'package:tired_agent_app/utils/app_strings.dart';

import 'package:tired_agent_app/enhancements/enhancement.dart';
import 'package:tired_agent_app/enhancements/enhancement_context.dart';
import 'package:tired_agent_app/enhancements/types.dart';
import 'package:tired_agent_app/services/session_api_service.dart';
import 'package:tired_agent_app/widgets/session_command_preview.dart';
import 'package:tired_agent_app/widgets/directory_picker_field.dart';
import 'package:tired_agent_app/widgets/preset_option_chips.dart';
import 'package:tired_agent_app/widgets/session_preset_dropdown.dart';

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

  final EnhancementContext _enhancementCtx = EnhancementContext();
  List<SessionEnhancement> _activeEnhancements = [];

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
  List<UserPreset> _customPresets = [];
  List<UserPreset> _recentPresets = [];

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
    if (_enhancementCtx.selectedSessionId != null) {
      parts.addAll(['--resume', _enhancementCtx.selectedSessionId!]);
    }
    return parts.join(' ');
  }

  void _applyBuiltin(BuiltinPreset p) {
    setState(() {
      _selectedBuiltinId = p.id;
      _cmd = p.cmd;
      _optionSelections.clear();
      _argsController.clear();
      _labelController.clear();
    });
    _updateEnhancements();
  }

  void _applyUserPreset(UserPreset p) {
    setState(() {
      _selectedBuiltinId = null;
      _cmd = p.cmd;
      _optionSelections.clear();
      _argsController.text = p.args.join(' ');
      _labelController.clear();
    });
    _updateEnhancements();
  }

  void _onOptionsChanged(Map<String, String?> updated) {
    setState(() => _optionSelections
      ..clear()
      ..addAll(updated));
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
    _enhancementCtx
      ..profileId = widget.profileId
      ..agentId = widget.agentId
      ..onStateChanged = () => setState(() {});
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getString(_kCustomPresets);
    if (customRaw != null) {
      final list = json.decode(customRaw) as List<dynamic>;
      _customPresets = list
          .map((e) => UserPreset.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final recentRaw = prefs.getString(_kRecentPresets);
    if (recentRaw != null) {
      final list = json.decode(recentRaw) as List<dynamic>;
      _recentPresets = list
          .map((e) => UserPreset.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (mounted) setState(() {});
  }

  void _updateEnhancements() {
    _activeEnhancements = EnhancementRegistry.forPoint(
      EnhancementPoint.directorySelected,
      _cmd,
      _selectedBuiltinId,
    );
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
            SnackBar(content: Text(AppStrings.of.createNotConnected), backgroundColor: c.danger),
          );
        }
        return;
      }
      final api = SessionApiService(conn: conn, agentId: widget.agentId);

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

      // Apply all active enhancements (including directory-selected ones
      // like ClaudeProjectsEnhancement that inject --name/--resume).
      var finalSpec = spec;
      for (final e in _activeEnhancements) {
        finalSpec = await e.modifySpec(finalSpec, _enhancementCtx);
      }
      // Also run beforeSubmit-only enhancements.
      for (final e in EnhancementRegistry.forPoint(
        EnhancementPoint.beforeSubmit, _cmd, _selectedBuiltinId,
      )) {
        finalSpec = await e.modifySpec(finalSpec, _enhancementCtx);
      }

      final session = await api.createSession(finalSpec);

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
      UserPreset(
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
    final result = await NeonDialog.show<UserPreset>(
      context: context,
      title: AppStrings.of.createSaveAsPreset,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedText.small(AppStrings.of.createPresetName),
          TextField(controller: labelCtrl, autofocus: true, decoration: const InputDecoration(isDense: true)),
        ],
      ),
      actions: [
        NeonDialogAction<UserPreset>(
          label: AppStrings.of.cancel,
          onPressed: (ctx) => Navigator.of(ctx).pop(),
        ),
        NeonDialogAction<UserPreset>(
          label: AppStrings.of.createSave,
          isPrimary: true,
          onPressed: (ctx) {
            final label = labelCtrl.text.trim();
            if (label.isEmpty) return;
            final manualArgs = _argsController.text
                .trim()
                .split(RegExp(r'\s+'))
                .where((s) => s.isNotEmpty)
                .toList();
            Navigator.of(ctx).pop(UserPreset(
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
    final path = await DirectoryPickerModal.show(
      context,
      serverRef: conn.managerRef,
      agentId: widget.agentId,
      initialPath: _cwdController.text.isNotEmpty ? _cwdController.text : null,
    );
    if (path != null && mounted) {
      _cwdController.text = path;
      _enhancementCtx.cwd = path;
      _updateEnhancements();
      setState(() {});
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
        title: ThemedText.mono(AppStrings.of.createTitle, color: c.primary),
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
            _sectionHeader(AppStrings.of.createPreset),
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
              _sectionHeader(AppStrings.of.createPreview),
              _buildTerminalPreview(),
              const SizedBox(height: AppSpacing.four),
            ],

            // ── COMMAND ───────────────────────────────────────
            _sectionHeader(AppStrings.of.createCommand),
            TextField(
              controller: TextEditingController.fromValue(
                TextEditingValue(text: _cmd),
              ),
              onChanged: (v) {
                setState(() => _cmd = v);
                _updateEnhancements();
              },
              style: TextStyle(
                fontFamily: 'monospace',
                color: c.textCode,
                fontSize: 14,
              ),
              decoration: _neonInput(prefixText: r'$ '),
            ),
            const SizedBox(height: AppSpacing.four),

            // ── ARGUMENTS ─────────────────────────────────────
            _sectionHeader(AppStrings.of.createArguments),
            TextField(
              controller: _argsController,
              style: TextStyle(
                fontFamily: 'monospace',
                color: c.textCode,
                fontSize: 14,
              ),
              decoration: _neonInput(hint: AppStrings.of.createArgsHint),
              onChanged: (_) => setState(() {}),
              enabled: !_busy,
            ),

            // ── OPTIONS ───────────────────────────────────────
            if (_selectedPreset != null &&
                _selectedPreset!.options.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.four),
              _sectionHeader(AppStrings.of.createOptions),
              _buildOptionChips(),
            ],

            const SizedBox(height: AppSpacing.four),

            // ── LABEL ─────────────────────────────────────────
            _sectionHeader(AppStrings.of.createSessionLabel),
            TextField(
              controller: _labelController,
              style: TextStyle(color: c.text, fontSize: 14),
              decoration: _neonInput(hint: AppStrings.of.createAutoLabel),
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.four),

            // ── WORKING DIRECTORY ────────────────────────────
            _sectionHeader(AppStrings.of.createWorkingDir),
            _buildDirectoryPicker(),
            const SizedBox(height: AppSpacing.two),
            ThemedText.mono(
              AppStrings.of.createTerminalSizeHint,
              color: c.textSecondary.withAlpha(120),
            ),
            const SizedBox(height: AppSpacing.six),

            // ── ENHANCEMENTS ──────────────────────────────────────
            if (_activeEnhancements.isNotEmpty) ...[
              for (final e in _activeEnhancements) e.buildWidget(context, _enhancementCtx),
              const SizedBox(height: AppSpacing.four),
            ],

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
                    child: ThemedText.mono(AppStrings.of.createCancel),
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
                        : ThemedText.mono(AppStrings.of.createLaunch, color: c.primary),
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
            ThemedText.mono(AppStrings.of.createSave, color: c.primary.withAlpha(180)),
          ],
        ),
      ),
    );
  }

  /// Terminal-style command preview window with title bar.
  Widget _buildTerminalPreview() => SessionCommandPreview(
    cmd: _cmd,
    commandLine: _previewCommand,
  );

  Widget _buildPresetDropdown() {
    final selectedPresetLabel = _selectedPreset?.label;
    final label = _selectedBuiltinId != null && selectedPresetLabel != null
        ? selectedPresetLabel
        : _cmd;
    return SessionPresetDropdown(
      currentLabel: label,
      hasSelection: _selectedBuiltinId != null,
      emoji: _selectedPreset?.emoji ?? '⚡',
      builtinPresets: _visibleBuiltinPresets,
      recentPresets: _recentPresets,
      customPresets: _customPresets,
      selectedBuiltinId: _selectedBuiltinId,
      onSelectBuiltin: _applyBuiltin,
      onSelectUser: _applyUserPreset,
    );
  }

  Widget _buildDirectoryPicker() => DirectoryPickerField(
    path: _cwdController.text.isNotEmpty ? _cwdController.text : null,
    enabled: !_busy,
    onPick: _pickDirectory,
    onClear: () => _cwdController.clear(),
  );

  Widget _buildOptionChips() {
    if (_selectedPreset == null) return const SizedBox.shrink();
    return PresetOptionChips(
      preset: _selectedPreset!,
      selections: _optionSelections,
      onChanged: _onOptionsChanged,
    );
  }
}
