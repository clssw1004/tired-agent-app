import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/generated/l10n/app_localizations_en.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/screens/settings/keyboard_scheme_editor_screen.dart';
import 'package:tired_agent_app/services/pty_keyboard_scheme_service.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/shell/pty_key_cap.dart';

/// Widget tests for the scheme editor: PTY-style preview, tap-to-select, the
/// inline edit bar (relabel / arrow-move / delete), and save persistence.
///
/// The first test is the regression guard for the invisible-keys bug that the
/// old ReorderableListView introduced.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PtyKeyboardSchemeProvider provider;
  late String schemeId;

  setUp(() async {
    AppStrings.init(AppLocalizationsEn('en'));
    tempDir = await Directory.systemTemp.createTemp('kbd_editor_test_');
    provider = PtyKeyboardSchemeProvider(
      service: PtyKeyboardSchemeService.withDirectory(tempDir),
    );
    final created = await provider.create(
      name: 'My Scheme',
      rows: [
        [TerminalKeys.escape, TerminalKeys.tab, TerminalKeys.enter],
        [TerminalKeys.up, TerminalKeys.down],
      ],
      basePresetId: 'shell',
    );
    schemeId = created.id;
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// Push the editor on top of a placeholder so its Save action can pop
  /// without tearing down the root navigator.
  Future<void> pumpEditor(WidgetTester tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider<PtyKeyboardSchemeProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: buildNeonLightTheme(),
          navigatorKey: navKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    navKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => KeyboardSchemeEditorScreen(schemeId: schemeId),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('按键以 PTY 样式预览渲染（回归防线：不再看不到按键）', (tester) async {
    await pumpEditor(tester);

    expect(find.widgetWithText(PtyKeyCap, 'Esc'), findsOneWidget);
    expect(find.widgetWithText(PtyKeyCap, 'Tab'), findsOneWidget);
    expect(find.widgetWithText(PtyKeyCap, '↑'), findsOneWidget);
    expect(find.widgetWithText(PtyKeyCap, '↓'), findsOneWidget);
    // No edit bar before anything is selected.
    expect(find.byKey(const ValueKey('kbd_edit_bar')), findsNothing);
  });

  testWidgets('点按按键选中并出现编辑条，再次点按取消选中', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.widgetWithText(PtyKeyCap, 'Tab'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('kbd_edit_bar')), findsOneWidget);
    // Label field is prefilled with the selected key's label.
    expect(find.widgetWithText(TextField, 'Tab'), findsOneWidget);

    await tester.tap(find.widgetWithText(PtyKeyCap, 'Tab'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kbd_edit_bar')), findsNothing);
  });

  testWidgets('编辑按键文本实时更新预览', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.widgetWithText(PtyKeyCap, 'Tab'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Tab'), 'TabX');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(PtyKeyCap, 'TabX'), findsOneWidget);
    expect(find.text('Tab'), findsNothing);
  });

  testWidgets('箭头右移交换按键、选中跟随、保存后持久化', (tester) async {
    await pumpEditor(tester);

    // row0 = [Esc, Tab, Enter]
    final tabBefore = tester.getTopLeft(find.widgetWithText(PtyKeyCap, 'Tab'));
    await tester.tap(find.widgetWithText(PtyKeyCap, 'Tab'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_right));
    await tester.pumpAndSettle();

    // Tab moved right; selection followed it (label field still shows Tab).
    final tabAfter = tester.getTopLeft(find.widgetWithText(PtyKeyCap, 'Tab'));
    expect(tabAfter.dx, greaterThan(tabBefore.dx));
    expect(find.widgetWithText(TextField, 'Tab'), findsOneWidget);

    await tester.tap(find.text(AppStrings.of.kbdSchemeSave));
    await tester.pumpAndSettle();

    final saved = provider.byId(schemeId)!;
    expect(saved.rows[0].map((k) => k.id), ['escape', 'enter', 'tab']);
  });

  testWidgets('编辑条删除选中按键并取消选中', (tester) async {
    await pumpEditor(tester);

    await tester.tap(find.widgetWithText(PtyKeyCap, 'Esc'));
    await tester.pumpAndSettle();

    final editBar = find.byKey(const ValueKey('kbd_edit_bar'));
    await tester.tap(
      find.descendant(of: editBar, matching: find.byIcon(Icons.delete_outline)),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(PtyKeyCap, 'Esc'), findsNothing);
    expect(find.byKey(const ValueKey('kbd_edit_bar')), findsNothing);
  });
}
