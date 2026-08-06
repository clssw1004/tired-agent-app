import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';

/// Compact inline `http://` / `https://` selector used as an input prefix
/// on URL fields. The user picks a scheme from the dropdown and types only
/// the host:port part.
class UrlSchemeDropdown extends StatelessWidget {
  /// Currently selected scheme, e.g. `http://` or `https://`.
  final String value;

  /// Called when the user picks a different scheme.
  final ValueChanged<String> onChanged;

  const UrlSchemeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const List<String> schemes = ['http://', 'https://'];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.one),
      child: DropdownButton<String>(
        value: schemes.contains(value) ? value : schemes.first,
        isDense: true,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.arrow_drop_down, size: 16, color: c.primary),
        borderRadius: BorderRadius.circular(6),
        style: TextStyle(
          fontFamily: 'monospace',
          color: c.primary.withAlpha(180),
          fontSize: 13,
        ),
        items: [
          for (final s in schemes) DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
