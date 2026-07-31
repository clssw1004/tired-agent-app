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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row1: name | token 两列并排 ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameController,
                  decoration: context.appComponents.buildInputDecoration(
                    context,
                    label: AppStrings.of.labelAgentName,
                    hint: AppStrings.of.agentNameHint,
                  ),
                  autocorrect: false,
                ),
              ),
              const SizedBox(width: AppSpacing.two),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _tokenController,
                  decoration: context.appComponents.buildInputDecoration(
                    context,
                    label: AppStrings.of.labelAgentToken,
                  ),
                  obscureText: true,
                  autocorrect: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.two),
          // ── Row2: url 独占一行 ─────────────────────────────
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
        ],
      ),
    );
  }
}
