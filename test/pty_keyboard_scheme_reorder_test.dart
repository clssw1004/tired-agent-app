import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/models/pty_keyboard_scheme.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/services/pty_keyboard_scheme_service.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// Integration test for the custom-keyboard reorder flow.
///
/// Covers the data-model + provider round-trip that backs the editor's
/// `ReorderableListView`: simulate a user drag (mutate the rows list),
/// call `update()`, and verify the new order persists and reloads.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kbd_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<PtyKeyboardScheme> seedScheme(
    PtyKeyboardSchemeProvider provider, {
    required String name,
    required List<List<TerminalKeyDef>> rows,
    String? basePresetId,
  }) {
    return provider.create(name: name, rows: rows, basePresetId: basePresetId);
  }

  /// Mirror the editor's ReorderableListView.onReorder algorithm:
  /// removeAt(oldIndex); if newIndex > oldIndex, newIndex -= 1; insert.
  List<TerminalKeyDef> reorder(
    List<TerminalKeyDef> row,
    int oldIndex,
    int newIndex,
  ) {
    final result = List<TerminalKeyDef>.from(row);
    final moved = result.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex -= 1;
    result.insert(newIndex, moved);
    return result;
  }

  test('update preserves reordered rows', () async {
    final service = PtyKeyboardSchemeService.withDirectory(tempDir);
    final provider = PtyKeyboardSchemeProvider(service: service);

    final created = await seedScheme(
      provider,
      name: 'Test Scheme',
      rows: [
        [TerminalKeys.up, TerminalKeys.down, TerminalKeys.left, TerminalKeys.right],
      ],
      basePresetId: 'shell',
    );
    final id = created.id;

    // Simulate a drag: move `up` (index 0) to the very end.
    // ReorderableListView passes newIndex = row.length (4); the algorithm
    // adjusts it to 3, giving [down, left, right, up].
    final reordered = reorder(created.rows[0], 0, created.rows[0].length);

    await provider.update(
      PtyKeyboardScheme.fromConfig(
        id: id,
        name: created.name,
        rows: [reordered],
        basePresetId: created.basePresetId,
      ),
    );

    final updated = provider.byId(id)!;
    expect(updated.rows[0].map((k) => k.id), ['down', 'left', 'right', 'up']);

    // Verify it round-trips through the on-disk service.
    await provider.load();
    final reloaded = provider.byId(id)!;
    expect(reloaded.rows[0].map((k) => k.id), ['down', 'left', 'right', 'up']);
  });

  test('update preserves multi-row reorder', () async {
    final service = PtyKeyboardSchemeService.withDirectory(tempDir);
    final provider = PtyKeyboardSchemeProvider(service: service);

    final created = await seedScheme(
      provider,
      name: 'Multi',
      rows: [
        [TerminalKeys.escape, TerminalKeys.tab, TerminalKeys.enter],
        [TerminalKeys.up, TerminalKeys.down],
      ],
      basePresetId: 'shell',
    );
    final id = created.id;

    // Reorder row 0: drag `enter` (index 2) to the front → [enter, escape, tab].
    final row0 = reorder(created.rows[0], 2, 0);

    await provider.update(
      PtyKeyboardScheme.fromConfig(
        id: id,
        name: created.name,
        rows: [row0, created.rows[1]],
        basePresetId: created.basePresetId,
      ),
    );

    final updated = provider.byId(id)!;
    expect(updated.rows[0].map((k) => k.id), ['enter', 'escape', 'tab']);
    expect(updated.rows[1].map((k) => k.id), ['up', 'down']);
  });

  test('resetToPreset restores original rows after a reorder', () async {
    final service = PtyKeyboardSchemeService.withDirectory(tempDir);
    final provider = PtyKeyboardSchemeProvider(service: service);

    final base = PtyKeyboardConfig.byId('shell')!;
    final created = await seedScheme(
      provider,
      name: 'Resettable',
      rows: [List<TerminalKeyDef>.from(base.rows[0])],
      basePresetId: 'shell',
    );
    final id = created.id;

    // Reorder row 0.
    final reordered = reorder(created.rows[0], 0, 2);
    await provider.update(
      PtyKeyboardScheme.fromConfig(
        id: id,
        name: created.name,
        rows: [reordered],
        basePresetId: 'shell',
      ),
    );
    expect(provider.byId(id)!.rows[0].first, isNot(created.rows[0].first));

    // Reset should restore preset rows.
    await provider.resetToPreset(id);
    final reset = provider.byId(id)!;
    expect(reset.rows[0].map((k) => k.id), base.rows[0].map((k) => k.id));
  });

  test('Round-trip JSON serialization preserves reordered keys', () async {
    // Rows may be reordered but each TerminalKeyDef must serialize+deserialize
    // back with the same id/label/bytes so the rendered button is identical
    // after reload.
    final orig = [
      TerminalKeys.enter,
      TerminalKeys.escape,
      TerminalKeys.combo([TerminalKeyCode.ctrl, TerminalKeyCode.c]),
    ];
    final viaJson = TerminalKeyDef.fromJson(orig.first.toJson());
    expect(viaJson.id, orig.first.id);
    expect(viaJson.label, orig.first.label);
    expect(viaJson.bytes, orig.first.bytes);

    final viaJson2 = TerminalKeyDef.fromJson(orig[2].toJson());
    expect(viaJson2.id, orig[2].id);
    expect(viaJson2.bytes, orig[2].bytes);
  });
}
