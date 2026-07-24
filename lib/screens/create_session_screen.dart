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
  final pad = (int n) => n.toString().padLeft(2, '0');
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

  const _Preset({
    required this.id,
    required this.label,
    required this.cmd,
    this.args = const [],
    required this.hint,
    required this.emoji,
    this.options = const [],
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
  ),
  _Preset(
    id: 'bash',
    label: 'Bash',
    cmd: 'bash',
    hint: 'POSIX shell',
    emoji: r'$',
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
  final String serverId;

  const CreateSessionScreen({super.key, required this.serverId});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _argsController = TextEditingController();
  final _cwdController = TextEditingController();
  final _labelController = TextEditingController();

  String _cmd = 'bash';
  final Set<String> _activeOptionIds = {};
  SessionMode _mode = SessionMode.process;
  bool _busy = false;

  _Preset? get _selectedPreset =>
      _presets.where((p) => p.cmd == _cmd).firstOrNull;

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
      _mode = p.cmd == 'claude' ? SessionMode.persistent : SessionMode.process;
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.ensureFreshSession();
      final ref = auth.managerRef;
      if (ref == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not authenticated'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

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
        mode: _mode,
      );

      final session = await auth.authService.transport.createSession(
        ref,
        spec,
        agentId: widget.serverId,
      );

      if (mounted) {
        context.replace('/session/${widget.serverId}/${session.id}');
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
    await auth.ensureFreshSession();
    final ref = auth.managerRef;
    if (ref == null) return;

    final path = await DirectoryPickerModal.show(
      context,
      serverRef: ref,
      agentId: widget.serverId,
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
                itemCount: _presets.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.two),
                itemBuilder: (context, index) {
                  final p = _presets[index];
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

            // ── Lifecycle mode ────────────────────────────────────────
            ThemedText.small('Lifecycle', color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.two),
            Row(
              children: [
                _modeChip(SessionMode.process, 'Process', 'Ends with process'),
                const SizedBox(width: AppSpacing.two),
                _modeChip(
                  SessionMode.persistent,
                  'Persistent',
                  'Manual kill only',
                  available: _cmd == 'claude',
                ),
              ],
            ),
            if (_cmd != 'claude')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.one),
                child: ThemedText.small(
                  'Persistent mode only available for Claude',
                  color: AppColors.textSecondary,
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
                  if (_cmd != 'claude' && _mode == SessionMode.persistent) {
                    _mode = SessionMode.process;
                  }
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

  Widget _modeChip(
    SessionMode m,
    String label,
    String desc, {
    bool available = true,
  }) {
    final active = _mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: available ? () => setState(() => _mode = m) : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.three),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent.withAlpha(30)
                : AppColors.backgroundElement,
            borderRadius: BorderRadius.circular(AppSpacing.two),
            border: Border.all(
              color: active ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemedText.body(
                label,
                color: active
                    ? AppColors.accent
                    : (available ? AppColors.text : AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.one),
              ThemedText.small(
                desc,
                color: available
                    ? AppColors.textSecondary
                    : AppColors.textSecondary.withAlpha(100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
