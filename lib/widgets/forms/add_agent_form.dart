import 'package:flutter/material.dart';

import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/theme.dart';

/// Form data returned by [AddAgentForm].
class AddAgentFormData {
  final String name;
  final String url;
  final String token;
  const AddAgentFormData(this.name, this.url, this.token);
}

/// Stateful form widget that owns its [TextEditingController]s and disposes
/// them in sync with the dialog's widget tree lifecycle.
class AddAgentForm extends StatefulWidget {
  final String? initialName;
  final String? initialUrl;
  final String? initialToken;

  const AddAgentForm({
    super.key,
    this.initialName,
    this.initialUrl,
    this.initialToken,
  });

  @override
  AddAgentFormState createState() => AddAgentFormState();
}

class AddAgentFormState extends State<AddAgentForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  AddAgentFormData get data => AddAgentFormData(
    _nameController.text.trim(),
    _urlController.text.trim(),
    _tokenController.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: context.appComponents.buildInputDecoration(
              context,
              label: AppStrings.of.labelAgentName,
              hint: AppStrings.of.agentNameHint,
            ),
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.two),
          TextField(
            controller: _urlController,
            decoration: context.appComponents.buildInputDecoration(
              context,
              label: AppStrings.of.labelAgentUrl,
              hint: AppStrings.of.agentUrlHint,
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.two),
          TextField(
            controller: _tokenController,
            decoration: context.appComponents.buildInputDecoration(
              context,
              label: AppStrings.of.labelAgentToken,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscureToken ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
              ),
            ),
            obscureText: _obscureToken,
            autocorrect: false,
          ),
        ],
      ),
    );
  }
}
