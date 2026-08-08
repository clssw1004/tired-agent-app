import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('默认首页展示模式为 managerAgent', () async {
    final p = AppSettingsProvider();
    await p.load();
    expect(p.homeDisplayMode, HomeDisplayMode.managerAgent);
  });

  test('setHomeDisplayMode 持久化后新实例可读回', () async {
    final p = AppSettingsProvider();
    await p.load();
    await p.setHomeDisplayMode(HomeDisplayMode.managerList);

    final q = AppSettingsProvider();
    await q.load();
    expect(q.homeDisplayMode, HomeDisplayMode.managerList);
  });

  test('load 解析缺省/非法/合法字符串', () async {
    // 缺省 → 默认
    SharedPreferences.setMockInitialValues({});
    final a = AppSettingsProvider();
    await a.load();
    expect(a.homeDisplayMode, HomeDisplayMode.managerAgent);

    // 非法值 → 回落默认
    SharedPreferences.setMockInitialValues({'home_display_mode': 'bogus'});
    final b = AppSettingsProvider();
    await b.load();
    expect(b.homeDisplayMode, HomeDisplayMode.managerAgent);

    // 两种合法值
    SharedPreferences.setMockInitialValues({
      'home_display_mode': 'managerList',
    });
    final c = AppSettingsProvider();
    await c.load();
    expect(c.homeDisplayMode, HomeDisplayMode.managerList);

    SharedPreferences.setMockInitialValues({
      'home_display_mode': 'managerAgent',
    });
    final d = AppSettingsProvider();
    await d.load();
    expect(d.homeDisplayMode, HomeDisplayMode.managerAgent);
  });

  test('setHomeDisplayMode 相同值不重复通知', () async {
    final p = AppSettingsProvider();
    await p.load();
    var notified = 0;
    p.addListener(() => notified++);
    await p.setHomeDisplayMode(HomeDisplayMode.managerAgent); // 已是默认
    expect(notified, 0);
    await p.setHomeDisplayMode(HomeDisplayMode.managerList);
    expect(notified, 1);
  });
}
