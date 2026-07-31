import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/theme/app_colors.dart';
import 'package:tired_agent_app/widgets/dialog/contract.dart';
import 'package:tired_agent_app/widgets/dialog/geek_dialog.dart';
import 'package:tired_agent_app/widgets/dialog/material_dialog.dart';

/// 回归测试：对话框按钮的 `Navigator.of(ctx)` 必须使用对话框自身的 context，
/// 而非调用方页面 context。
///
/// 背景：`/` 页面在 StatefulShellRoute 分支的嵌套 Navigator 中，而 showDialog
/// 默认把对话框压到 root Navigator。若按钮用页面 context 弹栈，会 pop 掉嵌套
/// Navigator 里的页面路由（甚至最后一个页面）而不是关闭对话框。
void main() {
  for (final impl in [
    const MaterialDialogImpl(),
    const GeekDialogImpl(),
  ]) {
    testWidgets('${impl.runtimeType} 按钮 pop 对话框而非宿主页面', (tester) async {
      var poppedValue = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppColors.light]),
          home: Navigator(
            key: GlobalKey<NavigatorState>(),
            initialRoute: '/',
            onGenerateRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => Builder(
                builder: (nestedCtx) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final v = await impl.show<int>(
                          nestedCtx,
                          title: 't',
                          content: const SizedBox.shrink(),
                          actions: [
                            DialogAction(
                              label: 'ok',
                              isPrimary: true,
                              onPressed: (ctx) => Navigator.of(ctx).pop(42),
                            ),
                          ],
                        );
                        poppedValue = v ?? -1;
                      },
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('t'), findsOneWidget, reason: '对话框应打开');

      await tester.tap(find.text('ok'));
      await tester.pumpAndSettle();

      expect(find.text('t'), findsNothing, reason: '对话框应关闭');
      expect(poppedValue, 42, reason: '按钮应返回对话框结果');
      expect(find.text('open'), findsOneWidget, reason: '宿主页面不应被 pop 掉');
    });
  }
}
