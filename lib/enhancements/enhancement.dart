import 'package:flutter/widgets.dart';

import 'package:tired_agent_app/enhancements/enhancement_context.dart';
import 'package:tired_agent_app/enhancements/types.dart';
import 'package:tired_agent_app/protocol/types.dart';

/// Base class for session creation enhancements.
abstract class SessionEnhancement {
  String get id;
  EnhancementActivation get activation;
  EnhancementPoint get point;

  Widget buildWidget(BuildContext context, EnhancementContext ctx);
  Future<SessionSpec> modifySpec(SessionSpec spec, EnhancementContext ctx);
}

/// Registry for session enhancements — static, add via register() in main.dart.
class EnhancementRegistry {
  static final List<SessionEnhancement> _items = [];

  static void register(SessionEnhancement e) => _items.add(e);

  static List<SessionEnhancement> forPoint(
    EnhancementPoint point,
    String cmd,
    String? presetId,
  ) => _items
      .where((e) => e.point == point && e.activation.matches(cmd, presetId))
      .toList();
}
