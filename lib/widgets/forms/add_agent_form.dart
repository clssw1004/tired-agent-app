import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/forms/connection_test_button.dart';

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

  /// Ephemeral transport for "Test Connection" — see [AddManagerFormState]
  /// for the rationale on keeping this separate from any live connection.
  HttpSseTransport? _testTransport;

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
    _testTransport?.dispose();
    super.dispose();
  }

  AddAgentFormData get data => AddAgentFormData(
    _nameController.text.trim(),
    _urlController.text.trim(),
    _tokenController.text.trim(),
  );

  /// Probe the agent by hitting its `/health` (reachability + identity) and
  /// a Bearer-protected `/api/v1/sessions` (token validity). Success detail
  /// surfaces the agent's name/version when `/health` advertises them.
  Future<ConnectionTestResult> _testConnection(String url, String token) async {
    _testTransport ??= HttpSseTransport();
    try {
      final r = await _testTransport!.testAgentConnection(url, token);
      if (!r.ok) {
        return ConnectionTestResult.fail(renderTransportError(r.error ?? ''));
      }
      String? detail;
      if (r.name != null && r.version != null) {
        detail = '${r.name} v${r.version}';
      } else if (r.name != null) {
        detail = r.name;
      } else if (r.version != null) {
        detail = 'v${r.version}';
      }
      return ConnectionTestResult.ok(detail: detail);
    } catch (e) {
      return ConnectionTestResult.fail(
        renderTransportError(describeTransportError(e)),
      );
    }
  }

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
            decoration: context.appComponents
                .buildInputDecoration(
                  context,
                  label: AppStrings.of.labelAgentToken,
                )
                .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureToken ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureToken = !_obscureToken),
                  ),
                ),
            obscureText: _obscureToken,
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.three),
          ConnectionTestButton(
            url: () => _urlController.text,
            token: () => _tokenController.text,
            test: _testConnection,
          ),
        ],
      ),
    );
  }
}
