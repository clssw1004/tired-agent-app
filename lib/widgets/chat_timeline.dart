import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/neon_divider.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class ChatTimeline extends StatefulWidget {
  final List<StructuredContent> contents;

  const ChatTimeline({super.key, required this.contents});

  @override
  State<ChatTimeline> createState() => _ChatTimelineState();
}

class _ChatTimelineState extends State<ChatTimeline> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ChatTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contents.length > oldWidget.contents.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.three),
      itemCount: widget.contents.length,
      itemBuilder: (context, index) {
        final content = widget.contents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.two),
          child: _MessageBubble(content: content),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final StructuredContent content;

  const _MessageBubble({required this.content});

  @override
  Widget build(BuildContext context) {
    return switch (content) {
      ContentUserMessage(:final text) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.three),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.three),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: ThemedText.body(text),
        ),
      ),
      ContentText(:final text) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.three),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.three),
            border: Border.all(color: AppColors.border.withAlpha(60), width: 0.5),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: ThemedText.body(text),
        ),
      ),
      ContentCode(:final code) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.three),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(color: AppColors.primary.withAlpha(25)),
        ),
        child: SelectableText(
          code,
          style: const TextStyle(color: AppColors.textCode, fontSize: 12, fontFamily: 'monospace'),
        ),
      ),
      ContentStatus(:final kind, :final text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.one),
        child: Row(
          children: [
            _statusIcon(kind),
            const SizedBox(width: AppSpacing.two),
            ThemedText.small(_statusLabel(kind)),
            if (text.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.two),
              Expanded(child: ThemedText.small(text)),
            ],
          ],
        ),
      ),
      ContentToolUse(:final name, :final completed) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.three),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.two),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThemedText.small('${completed ? "✓" : "⏳"} $name', color: AppColors.textSecondary),
          ],
        ),
      ),
      ContentDivider(:final label) => NeonDivider(label: label),
      ContentUsage(:final inputTokens, :final outputTokens) => Align(
        alignment: Alignment.centerRight,
        child: ThemedText.small('tokens in: $inputTokens · out: $outputTokens',
            color: AppColors.textSecondary),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  String _statusLabel(StatusKind kind) => switch (kind) {
    StatusKind.thinking => 'Thinking…',
    StatusKind.working => 'Working…',
    StatusKind.done => 'Done',
    StatusKind.error => 'Error',
    StatusKind.idle => 'Idle',
    StatusKind.starting => 'Starting',
  };

  Widget _statusIcon(StatusKind kind) => switch (kind) {
    StatusKind.thinking => SizedBox(
      width: 12,
      height: 12,
      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
    ),
    StatusKind.done => const Icon(Icons.check_circle, size: 14, color: AppColors.success),
    StatusKind.error => const Icon(Icons.error, size: 14, color: AppColors.danger),
    _ => const SizedBox(width: 12),
  };
}
