import 'package:flutter/material.dart';

/// A dialog text field with safe [TextEditingController] lifecycle.
///
/// Follows the CLAUDE.md guideline: controller created in [initState]
/// and disposed in [dispose], avoiding `_dependents.isEmpty` crash
/// on dialog close.
///
/// Use with [GlobalKey] to read the trimmed text value:
/// ```dart
/// final formKey = GlobalKey<LabelFormFieldState>();
/// // ... in dialog action:
/// final label = formKey.currentState?.text;
/// ```
class LabelFormField extends StatefulWidget {
  /// Initial text to populate the field with.
  final String initialText;

  /// Label text shown in the [InputDecoration].
  final String labelText;

  const LabelFormField({
    super.key,
    required this.initialText,
    required this.labelText,
  });

  @override
  LabelFormFieldState createState() => LabelFormFieldState();
}

class LabelFormFieldState extends State<LabelFormField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The trimmed text value, or `null` if empty.
  String? get text {
    final t = _controller.text.trim();
    return t.isNotEmpty ? t : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.labelText),
        autofocus: true,
      ),
    );
  }
}
