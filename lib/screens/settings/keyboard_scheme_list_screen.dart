import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/models/pty_keyboard_scheme.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/common/neon_dialog.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

/// Manager for user-defined keyboard schemes.
///
/// Lists builtin presets (read-only, offer "create from") and user schemes
/// (rename/reset/delete/duplicate/enter editor).
class KeyboardSchemeListScreen extends StatelessWidget {
  const KeyboardSchemeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final provider = context.watch<PtyKeyboardSchemeProvider>();
    final builtins = provider.builtinSchemes;
    final user = provider.userSchemes;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: ThemedText.title(AppStrings.of.kbdSchemeTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: c.primary),
            tooltip: AppStrings.of.kbdSchemeNew,
            onPressed: () => _createNew(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: c.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.two,
          AppSpacing.two,
          AppSpacing.two,
          AppSpacing.four,
        ),
        children: [
          // ── Default scheme ───────────────────────────────────────
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.kbdSchemeDefault,
          ),
          const SizedBox(height: AppSpacing.one),
          context.appComponents.buildSettingsTile(
            context,
            SettingsTileData(
              label: AppStrings.of.kbdSchemeDefault,
              value: provider.byId(provider.defaultSchemeId)?.name ??
                  AppStrings.of.kbdSchemeAuto,
              onTap: () => _pickDefaultKeyboardScheme(context),
            ),
          ),
          const SizedBox(height: AppSpacing.four),
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.kbdSchemePresets,
          ),
          const SizedBox(height: AppSpacing.one),
          for (final s in builtins) ...[
            _BuiltinTile(scheme: s, provider: provider),
            const SizedBox(height: AppSpacing.one),
          ],
          const SizedBox(height: AppSpacing.four),
          context.appComponents.buildSectionHeader(
            context,
            AppStrings.of.kbdSchemeMine,
          ),
          const SizedBox(height: AppSpacing.one),
          if (user.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.four),
              child: Center(
                child: ThemedText.small(
                  AppStrings.of.kbdSchemeEmpty,
                  color: c.textSecondary,
                ),
              ),
            ),
          for (final s in user) ...[
            _UserSchemeTile(scheme: s),
            const SizedBox(height: AppSpacing.one),
          ],
          const SizedBox(height: AppSpacing.four),
        ],
      ),
    );
  }

  void _createNew(BuildContext context) {
    final provider = context.read<PtyKeyboardSchemeProvider>();
    final c = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final builtins = provider.builtinSchemes;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.four),
                child: ThemedText.title(
                  AppStrings.of.kbdSchemeCreateFrom,
                  color: c.primary,
                ),
              ),
              Divider(height: 1, color: c.border),
              for (final s in builtins)
                ListTile(
                  dense: true,
                  leading: Icon(Icons.keyboard, color: c.primary, size: 18),
                  title: ThemedText.body(s.name, color: c.text),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push('/settings/keyboard/new?base=${s.id}');
                  },
                ),
              Divider(height: 1, color: c.border),
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.add_box_outlined,
                  color: c.textSecondary,
                  size: 18,
                ),
                title: ThemedText.body(
                  AppStrings.of.kbdSchemeBlank,
                  color: c.text,
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/settings/keyboard/new?base=none');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BuiltinTile extends StatelessWidget {
  final PtyKeyboardScheme scheme;
  final PtyKeyboardSchemeProvider provider;
  const _BuiltinTile({required this.scheme, required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.two),
        border: Border.all(color: c.border.withAlpha(40), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_outline, color: c.textSecondary, size: 16),
          const SizedBox(width: AppSpacing.two),
          Expanded(child: ThemedText.body(scheme.name, color: c.text)),
          ThemedText.small(
            '${scheme.rows.length} ${AppStrings.of.kbdSchemeRows}',
            color: c.textSecondary,
          ),
          const SizedBox(width: AppSpacing.two),
          IconButton(
            icon: Icon(
              Icons.create_new_folder_outlined,
              size: 18,
              color: c.primary,
            ),
            tooltip: AppStrings.of.kbdSchemeDuplicate,
            onPressed: () => _duplicate(context),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicate(BuildContext context) async {
    final name = await _promptName(context, '${scheme.name} Copy');
    if (name == null || !context.mounted) return;
    await provider.create(
      name: name,
      rows: scheme.rows.map((row) => List<TerminalKeyDef>.of(row)).toList(),
      basePresetId: scheme.id,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ThemedText.small(AppStrings.of.kbdSchemeDuplicated),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }
}

class _UserSchemeTile extends StatelessWidget {
  final PtyKeyboardScheme scheme;
  const _UserSchemeTile({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.two),
        border: Border.all(color: c.primary.withAlpha(30), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.keyboard, color: c.primary, size: 16),
          const SizedBox(width: AppSpacing.two),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText.body(scheme.name, color: c.text),
                ThemedText.small(
                  '${scheme.rows.length} ${AppStrings.of.kbdSchemeRows} · '
                  '${scheme.basePresetId ?? AppStrings.of.kbdSchemeBlank}',
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: c.primary),
            tooltip: AppStrings.of.kbdSchemeEdit,
            onPressed: () => context.push('/settings/keyboard/${scheme.id}'),
          ),
          IconButton(
            icon: Icon(Icons.restart_alt, size: 18, color: c.warning),
            tooltip: AppStrings.of.kbdSchemeReset,
            onPressed: () => _reset(context),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: c.danger),
            tooltip: AppStrings.of.kbdSchemeDelete,
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _reset(BuildContext context) async {
    final c = context.appColors;
    final provider = context.read<PtyKeyboardSchemeProvider>();
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: AppStrings.of.kbdSchemeReset,
      content: ThemedText.body(
        AppStrings.of.kbdSchemeResetDesc,
        color: c.textSecondary,
      ),
      showRobot: false,
      confirmText: AppStrings.of.confirm,
    );
    if (confirmed != true) return;
    await provider.resetToPreset(scheme.id);
  }

  Future<void> _delete(BuildContext context) async {
    final c = context.appColors;
    final provider = context.read<PtyKeyboardSchemeProvider>();
    final confirmed = await NeonDialog.showConfirm(
      context: context,
      title: AppStrings.of.kbdSchemeDelete,
      content: ThemedText.body(
        '${AppStrings.of.kbdSchemeDeleteDesc} "${scheme.name}"',
        color: c.textSecondary,
      ),
      showRobot: false,
      confirmText: AppStrings.of.confirm,
      confirmIsDanger: true,
    );
    if (confirmed != true) return;
    await provider.delete(scheme.id);
  }
}

/// 弹出「默认键盘方案」选择 bottom sheet。
void _pickDefaultKeyboardScheme(BuildContext context) {
  final provider = context.read<PtyKeyboardSchemeProvider>();
  final c = context.appColors;
  final schemes = provider.allSchemes;
  final currentId = provider.defaultSchemeId;
  showModalBottomSheet(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.four),
            child: Row(
              children: [
                Icon(Icons.keyboard_alt_outlined, color: c.primary, size: 20),
                const SizedBox(width: AppSpacing.two),
                ThemedText.title(
                  AppStrings.of.kbdSchemeDefault,
                  color: c.primary,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: schemes.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.auto_fix_high,
                      color: c.textSecondary,
                      size: 18,
                    ),
                    title: ThemedText.body(
                      AppStrings.of.kbdSchemeAuto,
                      color: c.text,
                    ),
                    subtitle: ThemedText.small(
                      AppStrings.of.kbdSchemeAutoDesc,
                      color: c.textSecondary,
                    ),
                    trailing: currentId == null
                        ? Icon(Icons.check, color: c.primary, size: 18)
                        : null,
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await provider.setDefaultSchemeId(null);
                    },
                  );
                }
                final s = schemes[i - 1];
                final active = s.id == currentId;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    provider.isBuiltin(s.id)
                        ? Icons.bookmark_outline
                        : Icons.keyboard,
                    color: active ? c.primary : c.textSecondary,
                    size: 18,
                  ),
                  title: ThemedText.body(
                    s.name,
                    color: active ? c.primary : c.text,
                  ),
                  subtitle: ThemedText.small(
                    '${s.rows.length} ${AppStrings.of.kbdSchemeRows}',
                    color: c.textSecondary,
                  ),
                  trailing: active
                      ? Icon(Icons.check, color: c.primary, size: 18)
                      : null,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await provider.setDefaultSchemeId(s.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Future<String?> _promptName(BuildContext context, String initial) =>
    showDialog<String>(
      context: context,
      builder: (_) => _NamePromptDialog(initial: initial),
    );

/// Simple dialog that asks for a single-line text input.
///
/// Owns its [TextEditingController] so disposal happens after the route is
/// fully removed — avoids the "used after disposed" crash that happens when
/// the caller disposes the controller immediately after `showDialog` returns,
/// while the dialog is still animating out.
class _NamePromptDialog extends StatefulWidget {
  final String initial;

  const _NamePromptDialog({required this.initial});

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    Navigator.of(context).pop(value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.of.kbdSchemeName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.of.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(AppStrings.of.confirm)),
      ],
    );
  }
}
