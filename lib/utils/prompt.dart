import 'package:tired_agent_app/utils/ansi.dart';

class PromptUtil {
  static final RegExp _shellPrompt = RegExp(r'[\w@][\w.@:/~-]*[\$#%>] ');
  static final RegExp _bashContinuation = RegExp(r'^>\s+');
  static bool isAtPrompt(String output) {
    final stripped = AnsiUtil.stripAnsi(output);
    final lines = stripped.split('\n');
    if (lines.isEmpty) return false;
    final last = lines.last;
    return _shellPrompt.hasMatch(last) || _bashContinuation.hasMatch(last);
  }
  static String? extractPrompt(String output) {
    final stripped = AnsiUtil.stripAnsi(output);
    final lines = stripped.split('\n');
    if (lines.isEmpty) return null;
    final last = lines.last;
    final match = _shellPrompt.firstMatch(last);
    return match?.group(0);
  }
}
