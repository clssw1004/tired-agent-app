import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/generated/l10n/app_localizations_en.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/screens/settings/keyboard_scheme_editor_screen.dart';
import 'package:tired_agent_app/services/pty_keyboard_scheme_service.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';
import 'package:tired_agent_app/widgets/shell/pty_key_cap.dart';

/// Widget tests for the key-icon picker and its editor integration:
/// picking a Material / Font Awesome icon from the edit bar, the live preview
/// switching to icon-only, save persistence (JSON round-trip), clearing the
/// icon back to the text label, and the search filter.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PtyKeyboardSchemeProvider provider;
  late String schemeId;

  setUp(() async {
    AppStrings.init(AppLocalizationsEn('en'));
    tempDir = await Directory.systemTemp.createTemp('kbd_icon_test_');
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

  /// Select the text-only `Tab` key and open the icon picker from the edit bar.
  Future<void> selectTabAndOpenIconPicker(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(PtyKeyCap, 'Tab'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kbd_edit_icon')));
    await tester.pumpAndSettle();
  }

  testWidgets('Material 图标选中后预览更新并持久化', (tester) async {
    await pumpEditor(tester);
    await selectTabAndOpenIconPicker(tester);

    // Material tab is the default; play_arrow is the first entry.
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // Sheet closed; the Tab cap now shows the icon, not its text label.
    expect(find.byKey(const ValueKey('kbd_edit_bar')), findsOneWidget);
    expect(find.widgetWithText(PtyKeyCap, 'Tab'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(PtyKeyCap),
        matching: find.byIcon(Icons.play_arrow),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.of.kbdSchemeSave));
    await tester.pumpAndSettle();

    final saved = provider.byId(schemeId)!;
    expect(saved.rows[0][1].icon?.codePoint, Icons.play_arrow.codePoint);
  });

  testWidgets('FontAwesome 图标跨 Tab 选中后持久化保留 fontFamily', (tester) async {
    await pumpEditor(tester);
    await selectTabAndOpenIconPicker(tester);

    // Switch to the FontAwesome tab; `play` is the first entry there.
    await tester.tap(find.text(AppStrings.of.kbdIconPickerFontAwesome));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(FontAwesomeIcons.play.data));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.of.kbdSchemeSave));
    await tester.pumpAndSettle();

    final saved = provider.byId(schemeId)!;
    final icon = saved.rows[0][1].icon;
    expect(icon, isNotNull);
    expect(icon!.codePoint, FontAwesomeIcons.play.data.codePoint);
    expect(icon.fontFamily, 'FontAwesomeSolid');
  });

  testWidgets('清除图标后按键恢复显示文本', (tester) async {
    await pumpEditor(tester);
    await selectTabAndOpenIconPicker(tester);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    // Reopen the picker and clear the icon.
    await tester.tap(find.byKey(const ValueKey('kbd_edit_icon')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.of.kbdIconPickerClear));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(PtyKeyCap, 'Tab'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PtyKeyCap),
        matching: find.byIcon(Icons.play_arrow),
      ),
      findsNothing,
    );
  });

  testWidgets('搜索框按名称过滤图标', (tester) async {
    await pumpEditor(tester);
    await selectTabAndOpenIconPicker(tester);

    await tester.enterText(
      find.byKey(const ValueKey('kbd_icon_search')),
      'play',
    );
    await tester.pumpAndSettle();

    // Only entries whose name contains "play" remain.
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('窄屏下编辑条（含图标按钮）不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpEditor(tester);
    await tester.tap(find.widgetWithText(PtyKeyCap, 'Tab'));
    await tester.pumpAndSettle();

    // Icon + Action buttons both render without overflow exceptions.
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('kbd_edit_icon')), findsOneWidget);
    expect(find.text(AppStrings.of.kbdEditorAction), findsOneWidget);
  });
}
