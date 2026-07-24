import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/renderer/claude_renderer.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/chat_timeline.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class ClaudeChatView extends StatefulWidget {
  final ServerRef serverRef;
  final String agentId;
  final Session session;

  const ClaudeChatView({
    super.key,
    required this.serverRef,
    required this.agentId,
    required this.session,
  });

  @override
  State<ClaudeChatView> createState() => _ClaudeChatViewState();
}

class _ClaudeChatViewState extends State<ClaudeChatView> {
  final ClaudeRenderer _renderer = ClaudeRenderer();
  final TextEditingController _inputController = TextEditingController();
  final HttpSseTransport _transport = HttpSseTransport();

  List<StructuredContent> _contents = [];
  bool _sending = false;
  Subscription? _subscription;
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _currentOffset = widget.session.byteOffset;
    // Fetch existing output first so the user sees what's already been printed
    try {
      final result = await _transport.fetchOutput(
        widget.serverRef,
        widget.session.id,
        agentId: widget.agentId,
        tail: 5000,
      );
      if (result.chunks.isNotEmpty && mounted) {
        String pending = '';
        for (final chunk in result.chunks) {
          pending += utf8.decode(
            base64.decode(chunk.data),
            allowMalformed: true,
          );
        }
        final renderResult = _renderer.processChunk(
          pending,
          session: (
            cmd: widget.session.cmd,
            args: widget.session.args,
            label: widget.session.label,
          ),
        );
        _currentOffset = result.upTo;
        setState(() => _contents = renderResult.contents);
      }
    } catch (_) {
      // fetchOutput may fail (no output yet, session starting, etc.)
    }
    // Now subscribe to live updates from the current offset
    _subscribe();
  }

  void _subscribe() {
    String pending = '';
    _subscription = _transport.subscribe(
      widget.serverRef,
      widget.session.id,
      SubscribeHandlers(
        onChunk: (chunk) {
          final text = utf8.decode(chunk.data, allowMalformed: true);
          pending += text;
          final result = _renderer.processChunk(
            pending,
            session: (
              cmd: widget.session.cmd,
              args: widget.session.args,
              label: widget.session.label,
            ),
            streaming: true,
            existing: _contents,
          );
          final nl = pending.lastIndexOf('\n');
          if (nl >= 0) pending = pending.substring(nl + 1);
          if (mounted) {
            setState(() => _contents = result.contents);
          }
        },
        onState: (session) {
          if (session.status == SessionStatus.exited && mounted) {
            setState(() {
              _contents = [
                ..._contents,
                const ContentStatus(
                  kind: StatusKind.idle,
                  text: 'Session ended',
                ),
              ];
            });
          }
        },
        onError: (error) {
          debugPrint('[ClaudeChatView] SSE error: $error');
        },
      ),
      agentId: widget.agentId,
      fromOffset: _currentOffset,
    );
  }

  void _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final payload = StructuredUserMessage(
        content: text,
        executionMode: ExecutionMode.auto,
      );
      final bytes = utf8.encode(json.encode(payload.toJson()));
      await _transport.sendInput(
        widget.serverRef,
        widget.session.id,
        bytes,
        agentId: widget.agentId,
      );
      _inputController.clear();
      setState(() {
        _contents = [..._contents, ContentUserMessage(text: text)];
      });
    } catch (e) {
      debugPrint('[ClaudeChatView] sendInput error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ChatTimeline(contents: _contents)),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.three,
            AppSpacing.two,
            AppSpacing.three,
            AppSpacing.two,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    maxLines: 4,
                    minLines: 1,
                    enabled: !_sending,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.three,
                        vertical: AppSpacing.two,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.two),
                ElevatedButton(
                  onPressed: (_inputController.text.trim().isEmpty || _sending)
                      ? null
                      : _send,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.three,
                      vertical: AppSpacing.two,
                    ),
                  ),
                  child: ThemedText.mono('Send'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
