import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('默认 defaultManagerId 为 null（自动）', () async {
    final p = AppSettingsProvider();
    await p.load();
    expect(p.defaultManagerId, isNull);
  });

  test('setDefaultManagerId 持久化后新实例可读回', () async {
    final p = AppSettingsProvider();
    await p.load();
    await p.setDefaultManagerId('m1');

    final q = AppSettingsProvider();
    await q.load();
    expect(q.defaultManagerId, 'm1');
  });

  test('setDefaultManagerId(null) 清除持久化', () async {
    SharedPreferences.setMockInitialValues({'default_manager_id': 'm1'});
    final p = AppSettingsProvider();
    await p.load();
    expect(p.defaultManagerId, 'm1');

    await p.setDefaultManagerId(null);
    final q = AppSettingsProvider();
    await q.load();
    expect(q.defaultManagerId, isNull);
  });

  test('setDefaultManagerId 相同值不重复通知', () async {
    final p = AppSettingsProvider();
    await p.load();
    var notified = 0;
    p.addListener(() => notified++);
    await p.setDefaultManagerId(null); // 已是默认
    expect(notified, 0);
    await p.setDefaultManagerId('m1');
    expect(notified, 1);
  });
}
