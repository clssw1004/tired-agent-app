import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/forms/add_manager_form.dart';

/// Full-screen page for adding a new Manager.
///
/// Pops [AddManagerFormData] on submit so the caller can drive
/// [AuthProvider.login] with the validated input.
class AddManagerScreen extends StatefulWidget {
  /// Default name prefilled into the form, e.g. `"管理器 3"`. Caller
  /// computes this from the current connection count so the default is
  /// stable across reopens.
  final String initialName;

  const AddManagerScreen({super.key, this.initialName = ''});

  @override
  State<AddManagerScreen> createState() => _AddManagerScreenState();
}

class _AddManagerScreenState extends State<AddManagerScreen> {
  final _formKey = GlobalKey<AddManagerFormState>();

  Future<void> _submit() async {
    final data = _formKey.currentState?.data;
    if (data == null) return;
    if (data.url.isEmpty || data.token.isEmpty) {
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
        title: ThemedText.mono(AppStrings.of.managersAdd, color: c.primary),
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
          child: AddManagerForm(key: _formKey, initialName: widget.initialName),
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
                    AppStrings.of.managersConnect,
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
