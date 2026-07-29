import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Reconnect form — owns its [TextEditingController] and disposes it in
/// [State.dispose], in sync with the widget tree lifecycle.
class ReconnectForm extends StatefulWidget {
  const ReconnectForm({super.key});

  @override
  ReconnectFormState createState() => ReconnectFormState();
}

class ReconnectFormState extends State<ReconnectForm> {
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String? get token {
    final t = _tokenController.text.trim();
    return t.isNotEmpty ? t : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedText.small(
          AppStrings.of.managersSessionExpired,
          color: c.textSecondary,
        ),
        const SizedBox(height: AppSpacing.three),
        TextField(
          controller: _tokenController,
          decoration: InputDecoration(labelText: AppStrings.of.managersAccessToken),
          obscureText: true,
          autocorrect: false,
        ),
      ],
    );
  }
}
