import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/generated/l10n/app_localizations_en.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/agent_card/agent_status_badge.dart';

void main() {
  setUp(() {
    AppStrings.init(AppLocalizationsEn('en'));
  });

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  test('agentStateLabel 返回对应 i18n 文案', () {
    expect(agentStateLabel(AgentState.online), 'Online');
    expect(agentStateLabel(AgentState.offline), 'Offline');
    expect(agentStateLabel(AgentState.pending), 'Pending');
  });

  testWidgets('AgentStatusBadge 渲染文字标签', (tester) async {
    await tester.pumpWidget(
      wrap(const AgentStatusBadge(color: Colors.green, label: 'Online')),
    );
    expect(find.text('Online'), findsOneWidget);
    // 胶囊内色点（圆形 BoxDecoration）存在。
    final dots = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(AgentStatusBadge),
            matching: find.byType(Container),
          ),
        )
        .where((w) =>
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle);
    expect(dots, isNotEmpty);
  });
}
