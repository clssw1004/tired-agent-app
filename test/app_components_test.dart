import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/agent_card/neon_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/material_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/geek_agent_card.dart';
import 'package:tired_agent_app/widgets/manager_card/neon_manager_card.dart';
import 'package:tired_agent_app/widgets/manager_card/material_manager_card.dart';
import 'package:tired_agent_app/widgets/manager_card/geek_manager_card.dart';
import 'package:tired_agent_app/widgets/session_card/neon_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/material_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/geek_session_card.dart';

/// AppComponents 两层兜底解析的验证：
/// ① 风格自定义兜底（base 链）② 系统默认兜底（systemFallback = neon）。
void main() {
  group('AppComponents 兜底解析', () {
    test('neon 全实现，命中自身', () {
      expect(AppComponents.neon.sessionCardOrFallback, isA<NeonSessionCard>());
      expect(AppComponents.neon.managerCardOrFallback, isA<NeonManagerCard>());
      expect(AppComponents.neon.agentCardOrFallback, isA<NeonAgentCard>());
    });

    test('geek 全实现，命中自身', () {
      expect(AppComponents.geek.sessionCardOrFallback, isA<GeekSessionCard>());
      expect(AppComponents.geek.managerCardOrFallback, isA<GeekManagerCard>());
      expect(AppComponents.geek.agentCardOrFallback, isA<GeekAgentCard>());
    });

    test('material 全实现，命中自身', () {
      expect(AppComponents.material.sessionCardOrFallback, isA<MD3SessionCard>());
      expect(AppComponents.material.managerCardOrFallback, isA<MD3ManagerCard>());
      expect(AppComponents.material.agentCardOrFallback, isA<MD3AgentCard>());
    });

    test('部分实现且无 base → 未实现回落系统默认 neon', () {
      const partial = AppComponents(sessionCard: GeekSessionCard());
      expect(partial.sessionCardOrFallback, isA<GeekSessionCard>());
      expect(partial.managerCardOrFallback, isA<NeonManagerCard>());
      expect(partial.agentCardOrFallback, isA<NeonAgentCard>());
    });

    test('基于 geek 增强，未实现回落 geek 而非 neon', () {
      const enhanced = AppComponents(
        sessionCard: NeonSessionCard(),
        base: AppComponents.geek,
      );
      expect(enhanced.sessionCardOrFallback, isA<NeonSessionCard>());
      expect(enhanced.managerCardOrFallback, isA<GeekManagerCard>());
      expect(enhanced.agentCardOrFallback, isA<GeekAgentCard>());
    });

    test('完全空实例 → 全部回落系统默认', () {
      const empty = AppComponents();
      expect(empty.sessionCardOrFallback, isA<NeonSessionCard>());
      expect(empty.managerCardOrFallback, isA<NeonManagerCard>());
      expect(empty.agentCardOrFallback, isA<NeonAgentCard>());
    });

    test('systemFallback 即 neon 全量实现', () {
      expect(AppComponents.systemFallback, same(AppComponents.neon));
    });
  });
}
