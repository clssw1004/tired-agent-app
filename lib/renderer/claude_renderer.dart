import 'dart:convert';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/renderer/registry.dart';

class ClaudeRenderer implements AgentRenderer {
  String _thinkingBuffer = '';

  @override
  ({List<StructuredContent> contents, String remainder}) processChunk(
    String buffer, {
    required ({String cmd, List<String> args, String? label}) session,
    bool streaming = false,
    List<StructuredContent> existing = const [],
  }) {
    final contents = <StructuredContent>[...existing];
    final lines = buffer.split('\n');
    final complete = lines.length > 1 ? lines.sublist(0, lines.length - 1) : <String>[];
    final remainder = lines.isNotEmpty ? lines.last : '';

    for (final line in complete) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        final type = json['type'] as String?;

        switch (type) {
          case 'text':
            final text = json['text'] as String? ?? '';
            if (text.isNotEmpty) contents.add(ContentText(text: text));
            break;
          case 'thinking':
            _thinkingBuffer += (json['thinking'] as String? ?? '');
            break;
          case 'done_thinking':
            if (_thinkingBuffer.isNotEmpty) {
              contents.add(ContentStatus(kind: StatusKind.thinking, text: _thinkingBuffer, ephemeral: true));
              _thinkingBuffer = '';
            }
            break;
          case 'tool_use':
            contents.add(ContentToolUse(
              name: json['name'] as String? ?? 'unknown',
              input: json['input']?.toString() ?? '{}',
              toolUseId: json['tool_use_id'] as String? ?? '',
              completed: false,
            ));
            break;
          case 'tool_result':
            contents.add(ContentToolResult(
              toolUseId: json['tool_use_id'] as String? ?? '',
              content: json['content']?.toString() ?? '',
              mimeType: json['mime_type'] as String?,
              isError: json['is_error'] as bool? ?? false,
            ));
            break;
          case 'user_message':
            contents.add(ContentUserMessage(text: json['text'] as String? ?? ''));
            break;
          case 'stream_event':
            final text = json['text'] as String? ?? '';
            if (text.isNotEmpty) {
              contents.add(ContentStreamEvent(text: text, append: json['append'] as bool? ?? false));
            }
            break;
          case 'status':
            final statusStr = json['status'] as String? ?? 'idle';
            contents.add(ContentStatus(
              kind: StatusKind.values.firstWhere((k) => k.name == statusStr, orElse: () => StatusKind.idle),
              text: json['text'] as String? ?? '',
              ephemeral: json['ephemeral'] as bool? ?? false,
            ));
            break;
          case 'usage':
            contents.add(ContentUsage(
              inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
              outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
            ));
            break;
          case 'divider':
            contents.add(ContentDivider(label: json['label'] as String?));
            break;
          case 'code':
            contents.add(ContentCode(
              code: json['code'] as String? ?? '',
              language: json['language'] as String?,
              displayBlock: (json['display'] as String?) != 'inline',
            ));
            break;
          default:
            // Unknown JSON type — render as text
            contents.add(ContentText(text: trimmed));
        }
      } catch (_) {
        // Not valid JSON — render as raw text
        contents.add(ContentText(text: trimmed));
      }
    }

    return (contents: contents, remainder: remainder);
  }
}
