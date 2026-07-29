import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Terminal-style command preview with traffic-light title bar.
class SessionCommandPreview extends StatelessWidget {
  final String cmd;
  final String commandLine;

  const SessionCommandPreview({
    super.key,
    required this.cmd,
    required this.commandLine,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(AppSpacing.two),
        border: Border.all(color: c.primary.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: c.primary.withAlpha(12),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar — traffic-light dots + prompt label
          _TitleBar(cmd: cmd),
          // Command content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.three),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText.mono(
                  r'$ ',
                  color: c.success.withAlpha(180),
                ),
                Expanded(
                  child: ThemedText.code(commandLine),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  final String cmd;
  const _TitleBar({required this.cmd});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.one,
      ),
      decoration: BoxDecoration(
        color: c.surfaceAlt.withAlpha(120),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.two - 1),
        ),
        border: Border(
          bottom: BorderSide(color: c.primary.withAlpha(30)),
        ),
      ),
      child: Row(
        children: [
          // Traffic-light dots
          ...[0xFF003C, 0xFF6600, 0x00FF41].map((hex) {
            final dotColor = Color(hex | 0xFF000000);
            return Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: dotColor.withAlpha(120),
                shape: BoxShape.circle,
              ),
            );
          }),
          const SizedBox(width: AppSpacing.two),
          ThemedText.mono(
            cmd,
            color: c.primary.withAlpha(140),
          ),
          const Spacer(),
          ThemedText.mono(
            '---',
            color: c.textSecondary.withAlpha(60),
          ),
        ],
      ),
    );
  }
}
