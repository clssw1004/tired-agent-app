import 'package:tired_agent_app/protocol/types.dart';

class ExecutionModes {
  static const List<ExecutionMode> all = ExecutionMode.values;
  static String label(ExecutionMode mode) => switch (mode) {
    ExecutionMode.auto => 'Auto',
    ExecutionMode.manual => 'Manual',
    ExecutionMode.plan => 'Plan',
  };
  static String description(ExecutionMode mode) => switch (mode) {
    ExecutionMode.auto => 'Claude executes tools automatically',
    ExecutionMode.manual => 'Claude asks before every tool invocation',
    ExecutionMode.plan => 'Claude produces a plan first, then executes on approval',
  };
}
