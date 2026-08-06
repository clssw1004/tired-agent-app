import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/forms/connection_test_button.dart';
import 'package:tired_agent_app/widgets/forms/url_scheme_dropdown.dart';

/// Form data returned by [AddAgentForm].
class AddAgentFormData {
  final String name;
  final String url;
  final String token;
  const AddAgentFormData(this.name, this.url, this.token);
}

/// Stateful form widget that owns its [TextEditingController]s and disposes
/// them in sync with the host page's widget tree lifecycle.
///
/// Embedding: place this widget inside a `SingleChildScrollView` so the
/// page handles scrolling — the form itself is a plain `Column`.
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

  /// URL scheme selected via [UrlSchemeDropdown]. Defaults to `http://`;
  /// in edit mode it is parsed out of [widget.initialUrl] so the user sees
  /// the actual scheme the agent was registered with.
  String _scheme = 'http://';

  /// Ephemeral transport for "Test Connection" — see [AddManagerFormState]
  /// for the rationale on keeping this separate from any live connection.
  HttpSseTransport? _testTransport;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _urlController = TextEditingController();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');

    // Edit mode: split the persisted URL into scheme + host:port.
    final initialUrl = widget.initialUrl;
    if (initialUrl != null && initialUrl.isNotEmpty) {
      final m = RegExp(r'^([a-z][a-z0-9+.-]*):\/\/').firstMatch(initialUrl);
      if (m != null) {
        _scheme = '${m.group(1)}://';
        _urlController.text = initialUrl.substring(_scheme.length);
      } else {
        _urlController.text = initialUrl;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    _testTransport?.dispose();
    super.dispose();
  }

  /// Concatenates the dropdown scheme with whatever the user typed in the
  /// URL field. Strips a stray `http://` / `https://` prefix the user might
  /// have pasted, so we never end up with `http://https://host` after submit.
  String get _effectiveUrl {
    final host = _urlController.text.trim().replaceFirst(
      RegExp(r'^https?://'),
      '',
    );
    return '$_scheme$host';
  }

  AddAgentFormData get data => AddAgentFormData(
    _nameController.text.trim(),
    _effectiveUrl,
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
    return Column(
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
          decoration: context.appComponents
              .buildInputDecoration(
                context,
                label: AppStrings.of.labelAgentUrl,
                hint: AppStrings.of.agentUrlHint,
              )
              .copyWith(
                prefix: UrlSchemeDropdown(
                  value: _scheme,
                  onChanged: (v) => setState(() => _scheme = v),
                ),
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
          url: () => _effectiveUrl,
          token: () => _tokenController.text,
          test: _testConnection,
        ),
      ],
    );
  }
}
