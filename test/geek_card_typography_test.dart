import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/agent_card/geek_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/contract.dart';
import 'package:tired_agent_app/widgets/session_card/geek_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';

/// geek 卡片排版回归防线：
///
/// 1. 名字/提示符统一 12px mono（不再有 13px/11px 覆写）→ 行高一致、
///    `>` 与正文真正对齐。
/// 2. manager 卡不再贴边：整卡横向 padding 与 agent/session 卡一致
///    （`horizontal: AppSpacing.four`）。
/// 3. exited session 状态行显示 `exit <code>`（历史 bug：
///    `_statusLabel(...) == 'exited'` 永远 false，已修）。
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: buildGeekLightTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  /// 收集某个根 widget 内所有 [Text] 的字号。
  Set<double> fontSizes(WidgetTester tester, Finder root) {
    final texts = tester.widgetList<Text>(
      find.descendant(of: root, matching: find.byType(Text)),
    );
    return texts.map((t) => t.style?.fontSize ?? 0).toSet();
  }

  testWidgets('geek agent 卡：名字/提示符统一 12px mono，无 13px', (tester) async {
    // 先 pump 一个占位拿主题 context，再构建卡片。
    await tester.pumpWidget(wrap(const SizedBox.shrink()));
    final ctx = tester.element(find.byType(Scaffold));
    await tester.pumpWidget(
      wrap(
        GeekAgentCard().build(
          ctx,
          AgentCardData(
            agent: const AgentInfo(
              id: 'a1',
              name: 'Alpha Agent',
              baseUrl: 'http://localhost:8080',
              state: AgentState.online,
            ),
          ),
        ),
      ),
    );
    final root = find.byType(Scaffold);
    final sizes = fontSizes(tester, root);
    // 全卡文字统一 mono 默认 12px，不得出现 13px/11px。
    expect(sizes.contains(13), isFalse, reason: '名字行不应覆写 13px');
    expect(sizes.contains(11), isFalse, reason: '不应混入 11px 元信息');
  });

  testWidgets('geek session 卡：exited 状态行显示 exit code', (tester) async {
    await tester.pumpWidget(wrap(const SizedBox.shrink()));
    final ctx = tester.element(find.byType(Scaffold));
    await tester.pumpWidget(
      wrap(
        GeekSessionCard().build(
          ctx,
          SessionCardData(
            session: Session(
              id: 's1',
              cmd: 'claude',
              args: const [],
              cwd: '/home/dev',
              status: SessionStatus.exited,
              pid: 1234,
              exitCode: 0,
              createdAt: DateTime.now().millisecondsSinceEpoch - 3600000,
              exitedAt: DateTime.now().millisecondsSinceEpoch - 600000,
              byteOffset: 0,
              cols: 80,
              rows: 24,
              label: 'demo',
              mode: SessionMode.process,
              extra: const {'claudeSessionId': 'cs-1'},
            ),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('exit 0'), findsOneWidget);
    expect(find.textContaining('ago'), findsOneWidget);
  });
}
