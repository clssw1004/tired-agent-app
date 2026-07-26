import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/directory_picker_modal.dart';
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

class _Preset {
  final String id;
  final String label;
  final String cmd;
  final List<String> args;
  final String hint;
  final String emoji;
  final List<_Option> options;

  /// OS families this preset applies to. `null` = all platforms.
  /// `['win32']` = Windows only; `['linux', 'darwin']` = Unix only.
  final List<String>? platforms;

  const _Preset({
    required this.id,
    required this.label,
    required this.cmd,
    this.args = const [],
    required this.hint,
    required this.emoji,
    this.options = const [],
    this.platforms,
  });
}

class _Option {
  final String id;
  final String label;
  final List<String> args;
  final String hint;
  const _Option({
    required this.id,
    required this.label,
    required this.args,
    required this.hint,
  });
}

const _presets = [
  _Preset(
    id: 'claude',
    label: 'Claude',
    cmd: 'claude',
    hint: 'Anthropic Claude Code CLI',
    emoji: '✦',
    // All platforms
  ),
  _Preset(
    id: 'bash',
    label: 'Bash',
    cmd: 'bash',
    hint: 'POSIX shell',
    emoji: r'$',
    platforms: ['linux', 'darwin'],
    options: [
      _Option(
        id: 'interactive',
        label: 'Interactive',
        args: ['-i'],
        hint: 'Force interactive mode',
      ),
      _Option(
        id: 'login',
        label: 'Login',
        args: ['-l'],
        hint: 'Start as a login shell',
      ),
    ],
  ),
  _Preset(
    id: 'zsh',
    label: 'Zsh',
    cmd: 'zsh',
    hint: 'Z shell',
    emoji: r'$',
    platforms: ['linux', 'darwin'],
    options: [
      _Option(
        id: 'interactive',
        label: 'Interactive',
        args: ['-i'],
        hint: 'Force interactive mode',
      ),
      _Option(
        id: 'login',
        label: 'Login',
        args: ['-l'],
        hint: 'Start as a login shell',
      ),
    ],
  ),
  _Preset(
    id: 'cmd',
    label: 'cmd.exe',
    cmd: 'cmd.exe',
    hint: 'Windows command prompt',
    emoji: '>',
    platforms: ['win32'],
    options: [
      _Option(
        id: 'no-auto-run',
        label: 'No AutoRun',
        args: ['/d'],
        hint: 'Disable AutoRun commands',
      ),
    ],
  ),
  _Preset(
    id: 'powershell',
    label: 'PowerShell',
    cmd: 'powershell.exe',
    hint: 'Windows PowerShell',
    emoji: '>',
    platforms: ['win32'],
    options: [
      _Option(
        id: 'no-logo',
        label: 'No logo',
        args: ['-NoLogo'],
        hint: 'Hide startup logo',
      ),
      _Option(
        id: 'no-profile',
        label: 'No profile',
        args: ['-NoProfile'],
        hint: 'Skip profile scripts',
      ),
    ],
  ),
  _Preset(
    id: 'python',
    label: 'Python',
    cmd: 'python3',
    args: ['-i'],
    hint: 'Interactive Python REPL',
    emoji: '🐍',
    // All platforms
    options: [
      _Option(
        id: 'interactive',
        label: 'Interactive',
        args: ['-i'],
        hint: 'Force interactive mode',
      ),
    ],
  ),
  _Preset(
    id: 'node',
    label: 'Node',
    cmd: 'node',
    hint: 'Node.js REPL',
    emoji: '⬢',
    // All platforms
    options: [
      _Option(
        id: 'interactive',
        label: 'Interactive',
        args: ['-i'],
        hint: 'Force interactive mode',
      ),
    ],
  ),
];

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
  final Set<String> _activeOptionIds = {};
  bool _busy = false;

  /// Agent OS platform — used to filter presets.
  /// `null` = platform unknown (show all presets).
  String? _platform;

  @override
  void initState() {
    super.initState();
    // Read agent platform from cache (already loaded by the time we get here).
    final auth = context.read<AuthProvider>();
    final conn = auth.connectionFor(widget.profileId);
    if (conn != null) {
      final agent = conn.agents.where((a) => a.id == widget.agentId).firstOrNull;
      _platform = agent?.platform?.os;
    }
  }

  /// Presets visible on the current agent platform.
  List<_Preset> get _visiblePresets {
    if (_platform == null) return _presets;
    return _presets.where(
      (p) => p.platforms == null || p.platforms!.contains(_platform),
    ).toList();
  }

  _Preset? get _selectedPreset =>
      _visiblePresets.where((p) => p.cmd == _cmd).firstOrNull;

  List<String> get _effectiveArgs {
    final preset = _selectedPreset;
    final optionArgs = (preset?.options ?? [])
        .where((o) => _activeOptionIds.contains(o.id))
        .expand((o) => o.args)
        .toList();
    return [...?preset?.args, ...optionArgs];
  }

  void _applyPreset(_Preset p) {
    setState(() {
      _cmd = p.cmd;
      _activeOptionIds.clear();
      _argsController.clear();
      _labelController.clear();
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      final conn = auth.connectionFor(widget.profileId);
      if (conn == null || conn.profile.sessionToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not connected'),
              backgroundColor: AppColors.danger,
            ),
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

      final session = await conn.transport.createSession(
        mgrRef,
        spec,
        agentId: widget.agentId,
      );

      if (mounted) {
        context.replace(
          '/session/${widget.profileId}/${widget.agentId}/${session.id}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
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
      setState(() {
        _cwdController.text = path;
      });
    }
  }

  @override
  void dispose() {
    _argsController.dispose();
    _cwdController.dispose();
    _labelController.dispose();
    super.dispose();
  }

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
            // ── Quick start presets ──────────────────────────────────
            ThemedText.small('Quick start', color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.two),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _visiblePresets.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.two),
                itemBuilder: (context, index) {
                  final p = _visiblePresets[index];
                  final active = p.cmd == _cmd;
                  return GestureDetector(
                    onTap: () => _applyPreset(p),
                    child: Container(
                      width: 76,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.one,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.surfaceAlt
                            : AppColors.backgroundElement,
                        borderRadius: BorderRadius.circular(AppSpacing.two),
                        border: Border.all(
                          color: active
                              ? AppColors.primary.withAlpha(80)
                              : Colors.transparent,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ThemedText(p.emoji, fontSize: 16),
                          ThemedText.small(
                            p.label,
                            color: active
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.four),

            // ── Command ──────────────────────────────────────────────
            ThemedText.small('Command', color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.two),
            TextField(
              controller: TextEditingController.fromValue(
                TextEditingValue(text: _cmd),
              ),
              onChanged: (v) {
                setState(() {
                  _cmd = v;
                });
              },
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.textCode,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.three,
                  vertical: AppSpacing.two,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.three),

            // ── Args ─────────────────────────────────────────────────
            ThemedText.small(
              'Arguments (space-separated)',
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.one),
            TextField(
              controller: _argsController,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.textCode,
              ),
              decoration: const InputDecoration(
                hintText: '--no-input',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.three,
                  vertical: AppSpacing.two,
                ),
              ),
              enabled: !_busy,
            ),

            // ── Option chips ─────────────────────────────────────────
            if (_selectedPreset?.options != null &&
                _selectedPreset!.options.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.two),
              Wrap(
                spacing: AppSpacing.two,
                runSpacing: AppSpacing.one,
                children: _selectedPreset!.options.map((opt) {
                  final active = _activeOptionIds.contains(opt.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (active) {
                          _activeOptionIds.remove(opt.id);
                        } else {
                          _activeOptionIds.add(opt.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.two,
                        vertical: AppSpacing.one,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.surfaceAlt
                            : AppColors.backgroundElement,
                        borderRadius: BorderRadius.circular(AppSpacing.three),
                        border: Border.all(
                          color: active
                              ? AppColors.primary.withAlpha(80)
                              : Colors.transparent,
                          width: 0.5,
                        ),
                      ),
                      child: ThemedText.small(
                        opt.label,
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // ── Command preview ──────────────────────────────────────
            if (_effectiveArgs.isNotEmpty ||
                _argsController.text.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.two),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.two),
                decoration: BoxDecoration(
                  color: AppColors.codeBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.two),
                ),
                child: Row(
                  children: [
                    ThemedText.small('preview', color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.two),
                    Expanded(
                      child: ThemedText.code(
                        [
                          _cmd,
                          ..._effectiveArgs,
                          ...(_argsController.text
                              .trim()
                              .split(RegExp(r'\s+'))
                              .where((s) => s.isNotEmpty)),
                        ].join(' '),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.four),

            // ── Options ──────────────────────────────────────────────
            ThemedText.small(
              'Label (optional)',
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.one),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                hintText: 'Leave empty to auto-generate',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.three,
                  vertical: AppSpacing.two,
                ),
              ),
              enabled: !_busy,
            ),
            const SizedBox(height: AppSpacing.three),

            ThemedText.small(
              'Working directory',
              color: AppColors.textSecondary,
            ),
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
                    const Icon(
                      Icons.folder_outlined,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.two),
                    Expanded(
                      child: ThemedText.body(
                        _cwdController.text.isNotEmpty
                            ? _cwdController.text
                            : 'Agent home directory',
                        color: _cwdController.text.isNotEmpty
                            ? AppColors.text
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (_cwdController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _cwdController.clear(),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.two),
            ThemedText.small(
              'Terminal size auto-matches browser window after session starts',
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.six),

            // ── Submit ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(
                        color: AppColors.backgroundElement,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.three,
                      ),
                    ),
                    child: ThemedText.body('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.three),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _busy || _cmd.trim().isEmpty ? null : _submit,
                    child: _busy
                        ? const NeonLoading(size: 20)
                        : Text('Create session'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
