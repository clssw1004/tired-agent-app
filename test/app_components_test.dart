import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/agent_card/cyberpunk_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/material_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/minimal_agent_card.dart';
import 'package:tired_agent_app/widgets/manager_card/cyberpunk_manager_card.dart';
import 'package:tired_agent_app/widgets/manager_card/material_manager_card.dart';
import 'package:tired_agent_app/widgets/manager_card/minimal_manager_card.dart';
import 'package:tired_agent_app/widgets/session_card/cyberpunk_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/material_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/minimal_session_card.dart';

/// AppComponents 两层兜底解析的验证：
/// ① 风格自定义兜底（base 链）② 系统默认兜底（systemFallback = cyberpunk）。
void main() {
  group('AppComponents 兜底解析', () {
    test('cyberpunk 全实现，命中自身', () {
      expect(AppComponents.cyberpunk.sessionCardOrFallback, isA<CyberpunkSessionCard>());
      expect(AppComponents.cyberpunk.managerCardOrFallback, isA<CyberpunkManagerCard>());
      expect(AppComponents.cyberpunk.agentCardOrFallback, isA<CyberpunkAgentCard>());
    });

    test('minimal 全实现，命中自身', () {
      expect(AppComponents.minimal.sessionCardOrFallback, isA<MinimalSessionCard>());
      expect(AppComponents.minimal.managerCardOrFallback, isA<MinimalManagerCard>());
      expect(AppComponents.minimal.agentCardOrFallback, isA<MinimalAgentCard>());
    });

    test('material 全实现，命中自身', () {
      expect(AppComponents.material.sessionCardOrFallback, isA<MD3SessionCard>());
      expect(AppComponents.material.managerCardOrFallback, isA<MD3ManagerCard>());
      expect(AppComponents.material.agentCardOrFallback, isA<MD3AgentCard>());
    });

    test('部分实现且无 base → 未实现回落系统默认 cyberpunk', () {
      const partial = AppComponents(sessionCard: MinimalSessionCard());
      expect(partial.sessionCardOrFallback, isA<MinimalSessionCard>());
      expect(partial.managerCardOrFallback, isA<CyberpunkManagerCard>());
      expect(partial.agentCardOrFallback, isA<CyberpunkAgentCard>());
    });

    test('基于 minimal 增强，未实现回落 minimal 而非 cyberpunk', () {
      const enhanced = AppComponents(
        sessionCard: CyberpunkSessionCard(),
        base: AppComponents.minimal,
      );
      expect(enhanced.sessionCardOrFallback, isA<CyberpunkSessionCard>());
      expect(enhanced.managerCardOrFallback, isA<MinimalManagerCard>());
      expect(enhanced.agentCardOrFallback, isA<MinimalAgentCard>());
    });

    test('完全空实例 → 全部回落系统默认', () {
      const empty = AppComponents();
      expect(empty.sessionCardOrFallback, isA<CyberpunkSessionCard>());
      expect(empty.managerCardOrFallback, isA<CyberpunkManagerCard>());
      expect(empty.agentCardOrFallback, isA<CyberpunkAgentCard>());
    });

    test('systemFallback 即 cyberpunk 全量实现', () {
      expect(AppComponents.systemFallback, same(AppComponents.cyberpunk));
    });
  });
}
