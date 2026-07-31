import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/form_utils.dart';
import 'package:tired_agent_app/utils/session_presets.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/enhancements/enhancement.dart';
import 'package:tired_agent_app/enhancements/enhancement_context.dart';
import 'package:tired_agent_app/enhancements/types.dart';
import 'package:tired_agent_app/services/session_api_service.dart';
import 'package:tired_agent_app/widgets/forms/directory_picker_field.dart';
import 'package:tired_agent_app/widgets/forms/directory_picker_modal.dart';
import 'package:tired_agent_app/widgets/forms/launch_chip.dart';
import 'package:tired_agent_app/widgets/session/preset_option_chips.dart';
import 'package:tired_agent_app/widgets/session/preset_selector.dart';
import 'package:tired_agent_app/widgets/session/resume_option_chip.dart';
import 'package:tired_agent_app/widgets/session/resume_session_dialog.dart';
import 'package:tired_agent_app/widgets/session/session_command_preview.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

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
  final _presetKey = GlobalKey<PresetSelectorState>();

  String _cmd = 'bash';
  final Map<String, String?> _optionSelections = {};
  bool _busy = false;

  final EnhancementContext _enhancementCtx = EnhancementContext();
  List<SessionEnhancement> _activeEnhancements = [];

  /// Currently selected resume session (from dialog), if any.
  ResumeSelection? _resumeSelection;

  /// Agent OS platform, used to filter builtin presets.
  String? _platform;

  // Convenience accessors into the PresetSelector state.
  BuiltinPreset? get _selectedPreset => _presetKey.currentState?.selectedPreset;
  String? get _selectedBuiltinId => _presetKey.currentState?.selectedBuiltinId;

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

  bool get _isClaude =>
      _selectedBuiltinId == 'claude' || _cmd.trim() == 'claude';

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

  void _onPresetChanged(PresetSelection sel) {
    if (sel.builtin != null) {
      _applyBuiltin(sel.builtin!);
    } else if (sel.user != null) {
      _applyUserPreset(sel.user!);
    }
  }

  void _applyBuiltin(BuiltinPreset p) {
    setState(() {
      _cmd = p.cmd;
      _optionSelections.clear();
      _argsController.clear();
      _labelController.clear();
      _onResumeChanged(null);
    });
    _updateEnhancements();
  }

  void _applyUserPreset(UserPreset p) {
    setState(() {
      _cmd = p.cmd;
      _optionSelections.clear();
      _argsController.text = p.args.join(' ');
      _labelController.clear();
      _onResumeChanged(null);
    });
    _updateEnhancements();
  }

  void _onOptionsChanged(Map<String, String?> updated) {
    setState(
      () => _optionSelections
        ..clear()
        ..addAll(updated),
    );
  }

  void _onResumeChanged(ResumeSelection? selection) {
    setState(() => _resumeSelection = selection);
    _enhancementCtx.selectedSessionId = selection?.sessionId;
    _enhancementCtx.selectedSessionDisplayName = selection?.displayName;
  }

  @override
  void initState() {
    super.initState();
    // Use platform-appropriate default command.
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    final agent = conn?.agents.where((a) => a.id == widget.agentId).firstOrNull;
    _platform = agent?.platform?.os;
    if (_platform == 'win32') {
      _cmd = 'powershell.exe';
    }
    _enhancementCtx
      ..profileId = widget.profileId
      ..agentId = widget.agentId
      ..onStateChanged = () => setState(() {});
  }

  void _updateEnhancements() {
    _activeEnhancements = EnhancementRegistry.forPoint(
      EnhancementPoint.directorySelected,
      _cmd,
      _selectedBuiltinId,
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
            SnackBar(
              content: Text(AppStrings.of.createNotConnected),
              backgroundColor: c.danger,
            ),
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
        cwd: _cwdController.text.trim().isNotEmpty
            ? _cwdController.text.trim()
            : null,
        label: _labelController.text.trim().isNotEmpty
            ? _labelController.text.trim()
            : _generateDefaultLabel(),
        cols: 80,
        rows: 24,
        mode: SessionMode.process,
      );

      var finalSpec = spec;
      for (final e in _activeEnhancements) {
        finalSpec = await e.modifySpec(finalSpec, _enhancementCtx);
      }
      for (final e in EnhancementRegistry.forPoint(
        EnhancementPoint.beforeSubmit,
        _cmd,
        _selectedBuiltinId,
      )) {
        finalSpec = await e.modifySpec(finalSpec, _enhancementCtx);
      }

      final session = await api.createSession(finalSpec);

      if (mounted) {
        _presetKey.currentState?.trackRecent(_cmd.trim(), manualArgs);
        context.replace(
          '/session/${widget.profileId}/${widget.agentId}/${session.id}',
        );
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
      _onResumeChanged(null);
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
      body: Column(
        children: [
          if (_previewCommand.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.four,
                AppSpacing.four,
                AppSpacing.four,
                0,
              ),
              child: SessionCommandPreview(
                cmd: _cmd,
                commandLine: _previewCommand,
                actions: LaunchChip(
                  busy: _busy,
                  disabled: _busy || _cmd.trim().isEmpty,
                  onTap: _submit,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.four),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionHeader(context, AppStrings.of.createPreset),
                  PresetSelector(
                    key: _presetKey,
                    platform: _platform,
                    cmd: _cmd,
                    argsText: _argsController.text,
                    onChanged: _onPresetChanged,
                    onSaved: (_) {},
                  ),
                  const SizedBox(height: AppSpacing.four),

                  sectionHeader(context, AppStrings.of.createCommand),
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
                    decoration: neonInputDecoration(context, prefixText: r'$ '),
                  ),
                  const SizedBox(height: AppSpacing.four),

                  sectionHeader(context, AppStrings.of.createSessionLabel),
                  TextField(
                    controller: _labelController,
                    style: TextStyle(color: c.text, fontSize: 14),
                    decoration: neonInputDecoration(
                      context,
                      hint: AppStrings.of.createAutoLabel,
                    ),
                    enabled: !_busy,
                  ),
                  const SizedBox(height: AppSpacing.four),

                  sectionHeader(context, AppStrings.of.createWorkingDir),
                  _buildDirectoryPicker(),
                  const SizedBox(height: AppSpacing.two),
                  ThemedText.mono(
                    AppStrings.of.createTerminalSizeHint,
                    color: c.textSecondary.withAlpha(120),
                  ),
                  const SizedBox(height: AppSpacing.six),

                  sectionHeader(context, AppStrings.of.createArguments),
                  TextField(
                    controller: _argsController,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: c.textCode,
                      fontSize: 14,
                    ),
                    decoration: neonInputDecoration(
                      context,
                      hint: AppStrings.of.createArgsHint,
                    ),
                    onChanged: (_) => setState(() {}),
                    enabled: !_busy,
                  ),

                  if (_selectedPreset != null &&
                      _selectedPreset!.options.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.four),
                    sectionHeader(context, AppStrings.of.createOptions),
                    _buildOptionChips(
                      extra: [
                        ResumeOptionChip(
                          profileId: widget.profileId,
                          agentId: widget.agentId,
                          cwd: _enhancementCtx.cwd,
                          enabled: _isClaude,
                          selection: _resumeSelection,
                          onChanged: _onResumeChanged,
                        ),
                      ],
                    ),
                  ] else ...[
                    ResumeOptionChip(
                      profileId: widget.profileId,
                      agentId: widget.agentId,
                      cwd: _enhancementCtx.cwd,
                      enabled: _isClaude,
                      selection: _resumeSelection,
                      onChanged: _onResumeChanged,
                    ),
                    if (_resumeSelection == null)
                      const SizedBox(height: AppSpacing.six),
                  ],

                  if (_activeEnhancements.isNotEmpty) ...[
                    for (final e in _activeEnhancements)
                      e.buildWidget(context, _enhancementCtx),
                    const SizedBox(height: AppSpacing.four),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryPicker() => DirectoryPickerField(
    path: _cwdController.text.isNotEmpty ? _cwdController.text : null,
    enabled: !_busy,
    onPick: _pickDirectory,
    onClear: () => _cwdController.clear(),
  );

  Widget _buildOptionChips({List<Widget>? extra}) {
    if (_selectedPreset == null) return const SizedBox.shrink();
    return PresetOptionChips(
      preset: _selectedPreset!,
      selections: _optionSelections,
      onChanged: _onOptionsChanged,
      extra: extra,
    );
  }
}
