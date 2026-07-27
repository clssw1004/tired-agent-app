import 'package:flutter/material.dart';

import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/theme.dart';

/// Form data returned by [AddManagerForm].
class AddManagerFormData {
  final String name;
  final String url;
  final String token;
  const AddManagerFormData(this.name, this.url, this.token);
}

/// Stateful form widget that owns its [TextEditingController]s and disposes
/// them in sync with the dialog's widget tree lifecycle.
class AddManagerForm extends StatefulWidget {
  final String initialName;

  const AddManagerForm({super.key, required this.initialName});

  @override
  AddManagerFormState createState() => AddManagerFormState();
}

class AddManagerFormState extends State<AddManagerForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
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

  AddManagerFormData get data => AddManagerFormData(
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
              labelText: AppStrings.of.labelName,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.three,
                vertical: AppSpacing.three,
              ),
            ),
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.three),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Manager URL',
              hintText: 'http://192.168.1.10:3099',
              contentPadding: EdgeInsets.symmetric(
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
            decoration: const InputDecoration(
              labelText: 'Access Token',
              contentPadding: EdgeInsets.symmetric(
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
