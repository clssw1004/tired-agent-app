import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/forms/connection_test_button.dart';

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
  bool _obscureToken = true;

  /// Ephemeral transport used only for the "Test Connection" probe.
  ///
  /// Kept separate from the manager's real [HttpSseTransport] so the probe
  /// cannot accidentally refresh a session or share a Dio interceptor's
  /// retry state with the live connection. Disposed in [dispose].
  HttpSseTransport? _testTransport;

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
    _testTransport?.dispose();
    super.dispose();
  }

  AddManagerFormData get data => AddManagerFormData(
    _nameController.text.trim(),
    _urlController.text.trim(),
    _tokenController.text.trim(),
  );

  /// Probe the manager by attempting a fresh login. We deliberately avoid
  /// calling [ManagerConnection.connect] here — that would persist session
  /// tokens and mutate [AuthProvider] state, which is not what "test"
  /// should do. The temporary transport has no `tokenProvider`, so the
  /// 401-retry interceptor stays a no-op and we get the original error.
  Future<ConnectionTestResult> _testConnection(String url, String token) async {
    _testTransport ??= HttpSseTransport();
    final ref = ServerRef(id: '_test', name: '', baseUrl: url, token: token);
    try {
      await _testTransport!.login(ref, token);
      return ConnectionTestResult.ok();
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
              label: AppStrings.of.labelName,
            ),
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.two),
          TextField(
            controller: _urlController,
            decoration: context.appComponents.buildInputDecoration(
              context,
              label: AppStrings.of.labelManagerUrl,
              hint: AppStrings.of.managerUrlHint,
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
                  label: AppStrings.of.managersAccessToken,
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
