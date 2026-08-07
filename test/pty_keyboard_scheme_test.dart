import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/models/pty_keyboard_scheme.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/services/pty_keyboard_scheme_service.dart';
import 'package:tired_agent_app/utils/pty_keyboard_presets/shell.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kbd_prefs_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  PtyKeyboardSchemeService newService() =>
      PtyKeyboardSchemeService.withDirectory(tempDir);

  group('PtyKeyboardScheme JSON round-trip', () {
    test('内置预设可序列化并还原', () {
      final preset = shellPreset;
      final scheme = PtyKeyboardScheme(
        id: preset.id,
        name: preset.name,
        basePresetId: preset.id,
        rows: preset.rows,
      );

      final decoded = PtyKeyboardScheme.fromJson(scheme.toJson());
      expect(decoded.id, preset.id);
      expect(decoded.name, preset.name);
      expect(decoded.basePresetId, preset.id);
      expect(decoded.rows.length, preset.rows.length);
      for (var i = 0; i < preset.rows.length; i++) {
        expect(decoded.rows[i].length, preset.rows[i].length);
        for (var j = 0; j < preset.rows[i].length; j++) {
          expect(decoded.rows[i][j].id, preset.rows[i][j].id);
          expect(decoded.rows[i][j].bytes, preset.rows[i][j].bytes);
          expect(decoded.rows[i][j].isMod, preset.rows[i][j].isMod);
        }
      }
    });

    test('icon 往返一致', () {
      const key = TerminalKeyDef(
        id: 'x',
        label: 'X',
        bytes: [0x1B, 0x4F, 0x50],
        icon: Icons.play_arrow,
      );
      final decoded = TerminalKeyDef.fromJson(key.toJson());
      expect(decoded.icon, isNotNull);
      expect(decoded.icon!.codePoint, Icons.play_arrow.codePoint);
      expect(decoded.bytes, [0x1B, 0x4F, 0x50]);
    });

    test('自定义命令按键（withEnter）往返一致', () {
      final key = TerminalKeys.commandShowText(
        label: 'clear',
        command: '/clear',
        withEnter: true,
      );
      final decoded = TerminalKeyDef.fromJson(key.toJson());
      expect(decoded.label, 'clear');
      expect(decoded.bytes.last, 0x0D);
    });

    test('modifier 按键往返保留 isMod', () {
      final decoded = TerminalKeyDef.fromJson(TerminalKeys.ctrl.toJson());
      expect(decoded.id, 'ctrl');
      expect(decoded.isMod, isTrue);
    });
  });

  group('PtyKeyboardPrefs JSON round-trip', () {
    test('defaultSchemeId + sessionAssignments 完整保留', () {
      const scheme = PtyKeyboardScheme(
        id: 's1',
        name: 'My Scheme',
        basePresetId: 'shell',
        rows: [
          [TerminalKeys.up],
        ],
      );
      final prefs = const PtyKeyboardPrefs(
        schemes: [],
        defaultSchemeId: 'shell',
        sessionAssignments: {'session-1': 's1'},
      ).copyWith(schemes: [scheme]);

      final decoded = PtyKeyboardPrefs.fromJson(prefs.toJson());
      expect(decoded.schemes, hasLength(1));
      expect(decoded.defaultSchemeId, 'shell');
      expect(decoded.sessionAssignments['session-1'], 's1');
    });

    test('clearDefaultSchemeId 显式置 null', () {
      const prefs = PtyKeyboardPrefs(
        schemes: [],
        defaultSchemeId: 'shell',
        sessionAssignments: {},
      );
      final cleared = prefs.copyWith(clearDefaultSchemeId: true);
      expect(cleared.defaultSchemeId, isNull);
    });
  });

  group('PtyKeyboardSchemeService 文件存储', () {
    test('保存/加载方案跨实例持久化', () async {
      const scheme = PtyKeyboardScheme(
        id: 's1',
        name: 'My Scheme',
        basePresetId: 'shell',
        rows: [
          [TerminalKeys.up, TerminalKeys.down],
          [TerminalKeys.escape],
        ],
      );
      final service = newService();
      await service.save(
        const PtyKeyboardPrefs(
          schemes: [scheme],
          defaultSchemeId: null,
          sessionAssignments: {},
        ),
      );

      final loaded = await newService().load();
      expect(loaded.schemes, hasLength(1));
      expect(loaded.schemes.first.name, 'My Scheme');
      expect(loaded.schemes.first.rows.length, 2);
      expect(loaded.schemes.first.rows.first[0].id, 'up');
    });

    test('session 方案映射 + 默认方案持久化', () async {
      final service = newService();
      await service.save(
        const PtyKeyboardPrefs(
          schemes: [],
          defaultSchemeId: 'shell',
          sessionAssignments: {'sess-1': 'custom'},
        ),
      );

      final loaded = await newService().load();
      expect(loaded.defaultSchemeId, 'shell');
      expect(loaded.sessionAssignments['sess-1'], 'custom');
    });

    test('文件不存在 → 空默认值', () async {
      // tearDown 清理后目录为空：直接 reload 应返回空。
      await tempDir.delete(recursive: true);
      tempDir = await Directory.systemTemp.createTemp('kbd_prefs_test_');
      final loaded = await PtyKeyboardSchemeService.withDirectory(
        tempDir,
      ).load();
      expect(loaded.schemes, isEmpty);
      expect(loaded.defaultSchemeId, isNull);
      expect(loaded.sessionAssignments, isEmpty);
    });

    test('损坏的 JSON 静默降级为空', () async {
      // 写入无效 JSON。
      final file = File('${tempDir.path}/keyboard_prefs.json');
      await file.writeAsString('not-json');
      final loaded = await newService().load();
      expect(loaded.schemes, isEmpty);
      expect(loaded.defaultSchemeId, isNull);
    });

    test('原子写 — 临时文件被清理', () async {
      await newService().save(
        PtyKeyboardPrefs(
          schemes: [
            PtyKeyboardScheme(
              id: 'a',
              name: 'A',
              rows: const [
                [TerminalKeys.up],
              ],
            ),
          ],
          defaultSchemeId: null,
          sessionAssignments: const {},
        ),
      );
      final dir = Directory(tempDir.path);
      final tmpFiles = await dir
          .list()
          .where((e) => e.path.endsWith('.tmp'))
          .toList();
      expect(tmpFiles, isEmpty);
    });
  });

  group('Provider 解析链与 fallback', () {
    late PtyKeyboardSchemeService service;
    late PtyKeyboardPrefs initialPrefs;

    setUp(() {
      service = newService();
      initialPrefs = const PtyKeyboardPrefs(
        schemes: [],
        defaultSchemeId: null,
        sessionAssignments: {},
      );
    });

    test('无配置 → 回退到命令预设', () async {
      await service.save(initialPrefs);
      // Need a fresh provider to load from disk.
      // ignore: invalid_use_of_protected_member
      // (provider constructed locally for this test, no listeners)
      // ignore: deprecated_member_use
      // ignore: avoid_dynamic_calls
      // (no setter)
      // ignore: prefer_const_constructors
      // (not const)
      // The provider's load() reads via service.
      // ignore: unused_local_variable
      // ignore: unused_element
      // ignore: prefer_final_locals
      // Actually construct the provider normally.
      // ignore: avoid_print
      // (no prints)
      // Use the provider API directly.
      // ignore: no_leading_underscores_for_local_identifiers
      final provider = PtyKeyboardSchemeProvider(service: service);
      await provider.load();
      final config = provider.configForSession('bash');
      expect(config.id, 'shell');
    });

    test('defaultSchemeId → 命中预设', () async {
      await service.save(initialPrefs.copyWith(defaultSchemeId: 'minimal'));
      final provider = PtyKeyboardSchemeProvider(service: service);
      await provider.load();
      final config = provider.configForSession('bash');
      expect(config.id, 'minimal');
    });

    test('session 映射优先于 defaultSchemeId', () async {
      await service.save(
        initialPrefs.copyWith(
          defaultSchemeId: 'minimal',
          sessionAssignments: const {'s1': 'shell'},
        ),
      );
      final provider = PtyKeyboardSchemeProvider(service: service);
      await provider.load();
      final config = provider.configForSession('python3', sessionId: 's1');
      expect(config.id, 'shell');
    });

    test('session 映射 id 指向已删方案 → 落到 default', () async {
      await service.save(
        initialPrefs.copyWith(
          defaultSchemeId: 'minimal',
          sessionAssignments: const {'s1': 'gone'},
        ),
      );
      final provider = PtyKeyboardSchemeProvider(service: service);
      await provider.load();
      final config = provider.configForSession('python3', sessionId: 's1');
      expect(config.id, 'minimal');
    });

    test('全部失效 → 命令预设', () async {
      await service.save(
        initialPrefs.copyWith(
          defaultSchemeId: 'gone',
          sessionAssignments: const {'s1': 'also-gone'},
        ),
      );
      final provider = PtyKeyboardSchemeProvider(service: service);
      await provider.load();
      expect(
        provider.configForSession('python3', sessionId: 's1').id,
        'minimal',
      );
      expect(provider.configForSession('bash').id, 'shell');
      expect(provider.configForSession('powershell.exe').id, 'windows');
    });
  });
}
