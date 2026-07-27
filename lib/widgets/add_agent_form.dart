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
  const AddAgentForm({super.key});

  @override
  AddAgentFormState createState() => AddAgentFormState();
}

class AddAgentFormState extends State<AddAgentForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _urlController = TextEditingController();
    _tokenController = TextEditingController();
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
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppStrings.of.labelAgentName,
              hintText: 'web-01',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.three,
                vertical: AppSpacing.three,
              ),
            ),
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.three),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: AppStrings.of.labelAgentUrl,
              hintText: 'http://192.168.1.10:3100',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.three,
                vertical: AppSpacing.three,
              ),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.three),
          TextField(
            controller: _tokenController,
            decoration: InputDecoration(
              labelText: AppStrings.of.labelAgentToken,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.three,
                vertical: AppSpacing.three,
              ),
            ),
            obscureText: true,
            autocorrect: false,
          ),
        ],
      ),
    );
  }
}
