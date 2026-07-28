import 'package:flutter/widgets.dart';

/// Context passed to enhancement buildWidget/modifySpec calls.
class EnhancementContext {
  String? cwd;
  String? selectedSessionId;
  String? selectedSessionDisplayName;
  String? profileId;
  String? agentId;
  VoidCallback? onStateChanged;
}
