/// Strip ANSI escape codes from a string.
class AnsiUtil {
  static final RegExp _ansiPattern = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
  static String stripAnsi(String input) => input.replaceAll(_ansiPattern, '');
}
