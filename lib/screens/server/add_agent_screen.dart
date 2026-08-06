import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/forms/add_agent_form.dart';

/// Arguments passed via go_router `extra` to [AddAgentScreen].
///
/// `agentId == null` → add mode; `agentId != null` → edit mode (the caller
/// already has the existing agent registered on the manager and wants to
/// update name/URL/token).
class AddAgentPageArgs {
  final String? agentId;
  final String? initialName;
  final String? initialUrl;
  final String? initialToken;

  const AddAgentPageArgs({
    this.agentId,
    this.initialName,
    this.initialUrl,
    this.initialToken,
  });
}

/// Full-screen page for registering a new Agent or editing an existing one.
///
/// Pops [AddAgentFormData] on submit so the caller can dispatch the
/// appropriate `addAgent` / `updateAgent` call against the manager.
class AddAgentScreen extends StatefulWidget {
  final String profileId;
  final AddAgentPageArgs args;

  const AddAgentScreen({
    super.key,
    required this.profileId,
    this.args = const AddAgentPageArgs(),
  });

  @override
  State<AddAgentScreen> createState() => _AddAgentScreenState();
}

class _AddAgentScreenState extends State<AddAgentScreen> {
  final _formKey = GlobalKey<AddAgentFormState>();

  bool get _isEdit => widget.args.agentId != null;

  String get _title =>
      _isEdit ? AppStrings.of.agentEditTitle : AppStrings.of.agentAddTitle;

  String get _submitLabel =>
      _isEdit ? AppStrings.of.agentSave : AppStrings.of.agentRegister;

  Future<void> _submit() async {
    final data = _formKey.currentState?.data;
    if (data == null) return;
    // Edit mode allows the token field to stay empty (caller treats empty
    // token as "keep existing"); add mode requires it.
    if (data.url.isEmpty || data.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ThemedText.small(AppStrings.of.testConnectionNeedUrlToken),
        ),
      );
      return;
    }
    if (!_isEdit && data.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ThemedText.small(AppStrings.of.testConnectionNeedUrlToken),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(data);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        title: ThemedText.mono(_title, color: c.primary),
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.of.cancel,
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: c.primary.withAlpha(80)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.four),
          child: AddAgentForm(
            key: _formKey,
            initialName: widget.args.initialName,
            initialUrl: widget.args.initialUrl,
            initialToken: widget.args.initialToken,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.four),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.three,
                    ),
                  ),
                  child: Text(AppStrings.of.cancel),
                ),
              ),
              const SizedBox(width: AppSpacing.three),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.background,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.three,
                    ),
                  ),
                  child: Text(
                    _submitLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
