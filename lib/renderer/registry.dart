import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/renderer/claude_renderer.dart';

typedef Detector = bool Function(String cmd, List<String> args);

abstract class AgentRenderer {
  ({List<StructuredContent> contents, String remainder}) processChunk(
    String buffer, {
    required ({String cmd, List<String> args, String? label}) session,
    bool streaming = false,
    List<StructuredContent> existing = const [],
  });
}

class RendererRegistration {
  final Detector detector;
  final AgentRenderer Function() factory;
  const RendererRegistration({required this.detector, required this.factory});
}

class RendererRegistry {
  final List<RendererRegistration> _registrations = [];
  void register(RendererRegistration reg) => _registrations.add(reg);
  AgentRenderer? detect(String cmd, List<String> args) {
    for (final reg in _registrations) {
      if (reg.detector(cmd, args)) return reg.factory();
    }
    return null;
  }
}

RendererRegistry defaultRegistry() {
  final reg = RendererRegistry();
  reg.register(RendererRegistration(
    detector: (cmd, args) => cmd == 'claude' || args.contains('claude') || args.contains('--persistent'),
    factory: () => ClaudeRenderer(),
  ));
  return reg;
}
