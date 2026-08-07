import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tired_agent_app/generated/l10n/app_localizations_en.dart';
import 'package:tired_agent_app/theme/app_colors.dart';
import 'package:tired_agent_app/widgets/session/preset_selector.dart';
import 'package:tired_agent_app/utils/app_strings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) => MaterialApp(
    theme: ThemeData(extensions: [AppColors.light]),
    home: Builder(
      builder: (context) {
        AppStrings.init(AppLocalizationsEn('en'));
        return Scaffold(body: Center(child: child));
      },
    ),
  );

  testWidgets('保存自定义预设后再次打开下拉列表应包含新预设', (tester) async {
    final key = GlobalKey<PresetSelectorState>();
    await tester.pumpWidget(
      wrap(
        PresetSelector(
          key: key,
          platform: 'win32',
          cmd: 'powershell.exe',
          argsText: '-NoProfile -NoLogo',
          onChanged: (_) {},
          onSaved: (_) {},
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.of.createSave));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.of.createSaveAsPreset), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'My Custom');
    await tester.tap(find.widgetWithText(TextButton, AppStrings.of.createSave));
    await tester.pumpAndSettle();

    expect(key.currentState!.customPresets.length, 1);
    expect(key.currentState!.customPresets.first.label, 'My Custom');

    expect(key.currentState!.selectedUserId, isNotNull);
    expect(key.currentState!.selectedUserPreset?.label, 'My Custom');
    expect(
      find.text('My Custom'),
      findsOneWidget,
      reason: '保存后触发器应显示新预设 label，而非 cmd',
    );

    await tester.tap(find.text('My Custom'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.of.createSectionCustom), findsOneWidget);
    final customTile = find.widgetWithText(ListTile, 'My Custom');
    expect(customTile, findsOneWidget);
    expect(
      find.descendant(of: customTile, matching: find.byIcon(Icons.check)),
      findsOneWidget,
      reason: '选中的自定义预设应在 picker 中高亮',
    );
  });

  testWidgets('重启后自定义预设应从 SharedPreferences 恢复', (tester) async {
    final key = GlobalKey<PresetSelectorState>();
    await tester.pumpWidget(
      wrap(
        PresetSelector(
          key: key,
          platform: 'win32',
          cmd: 'powershell.exe',
          argsText: '-NoProfile',
          onChanged: (_) {},
          onSaved: (_) {},
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.of.createSave));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Persisted Preset');
    await tester.tap(find.widgetWithText(TextButton, AppStrings.of.createSave));
    await tester.pumpAndSettle();
    await tester.pump();

    final restartKey = GlobalKey<PresetSelectorState>();
    await tester.pumpWidget(
      wrap(
        PresetSelector(
          key: restartKey,
          platform: 'win32',
          cmd: 'bash',
          argsText: '',
          onChanged: (_) {},
          onSaved: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(restartKey.currentState!.customPresets.length, 1);
    expect(
      restartKey.currentState!.customPresets.first.label,
      'Persisted Preset',
    );
  });
}
