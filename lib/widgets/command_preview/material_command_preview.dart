import 'package:flutter/material.dart';
import 'package:tired_agent_app/widgets/command_preview/contract.dart';

/// Material Design 3 风格命令预览：原生 [Card] + 等宽代码块。
class MaterialCommandPreview extends CommandPreviewContract {
  const MaterialCommandPreview();

  @override
  Widget build(
    BuildContext context, {
    required String cmd,
    required String commandLine,
    Widget? actions,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mono = const TextStyle(fontFamily: 'monospace');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar — cmd + optional actions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cmd,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: scheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?actions,
              ],
            ),
          ),
          // Command content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$ ', style: mono.copyWith(color: scheme.primary)),
                Expanded(
                  child: Text(
                    commandLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
