import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/models/pty_keyboard_scheme.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/services/pty_keyboard_scheme_service.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// Provider CRUD + reset round-trips that back the scheme editor, plus the
/// `TerminalKeyDef.copyWith` used by the edit bar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kbd_crud_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('update persists a mutated layout and reloads from disk', () async {
    final service = PtyKeyboardSchemeService.withDirectory(tempDir);
    final provider = PtyKeyboardSchemeProvider(service: service);

    final created = await provider.create(
      name: 'Test Scheme',
      rows: [
        [
          TerminalKeys.up,
          TerminalKeys.down,
          TerminalKeys.left,
          TerminalKeys.right,
        ],
      ],
      basePresetId: 'shell',
    );
    final id = created.id;

    // Simulate the editor's swap-based moves: move `up` to the end.
    final reordered = List<TerminalKeyDef>.from(created.rows[0]);
    final moved = reordered.removeAt(0);
    reordered.add(moved);

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

  test('update preserves multi-row edits', () async {
    final service = PtyKeyboardSchemeService.withDirectory(tempDir);
    final provider = PtyKeyboardSchemeProvider(service: service);

    final created = await provider.create(
      name: 'Multi',
      rows: [
        [TerminalKeys.escape, TerminalKeys.tab, TerminalKeys.enter],
        [TerminalKeys.up, TerminalKeys.down],
      ],
      basePresetId: 'shell',
    );
    final id = created.id;

    // Reorder row 0 via swap semantics: drag `enter` to the front.
    final row0 = List<TerminalKeyDef>.from(created.rows[0]);
    final enter = row0.removeAt(2);
    row0.insert(0, enter);

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

  test('resetToPreset restores original rows after edits', () async {
    final service = PtyKeyboardSchemeService.withDirectory(tempDir);
    final provider = PtyKeyboardSchemeProvider(service: service);

    final base = PtyKeyboardConfig.byId('shell')!;
    final created = await provider.create(
      name: 'Resettable',
      rows: [List<TerminalKeyDef>.from(base.rows[0])],
      basePresetId: 'shell',
    );
    final id = created.id;

    // Mutate a row as the editor would (swap + relabel).
    final mutated = List<TerminalKeyDef>.from(created.rows[0]);
    mutated[0] = mutated[0].copyWith(label: 'X');
    await provider.update(
      PtyKeyboardScheme.fromConfig(
        id: id,
        name: created.name,
        rows: [mutated],
        basePresetId: 'shell',
      ),
    );
    expect(provider.byId(id)!.rows[0].first.label, 'X');

    // Reset should restore preset rows (id + label).
    await provider.resetToPreset(id);
    final reset = provider.byId(id)!;
    expect(reset.rows[0].map((k) => k.id), base.rows[0].map((k) => k.id));
    expect(reset.rows[0].first.label, base.rows[0].first.label);
  });

  test('delete removes the scheme', () async {
    final service = PtyKeyboardSchemeService.withDirectory(tempDir);
    final provider = PtyKeyboardSchemeProvider(service: service);

    final created = await provider.create(
      name: 'To Delete',
      rows: [
        [TerminalKeys.up],
      ],
      basePresetId: 'shell',
    );
    final id = created.id;
    expect(provider.byId(id), isNotNull);

    await provider.delete(id);
    expect(provider.byId(id), isNull);
  });

  test('TerminalKeyDef.copyWith relabels without touching bytes or id', () {
    final original = TerminalKeys.combo([
      TerminalKeyCode.ctrl,
      TerminalKeyCode.c,
    ]);
    final relabeled = original.copyWith(label: 'Copy');
    expect(relabeled.label, 'Copy');
    expect(relabeled.id, original.id);
    expect(relabeled.bytes, original.bytes);
    expect(relabeled.composedOf, original.composedOf);
    expect(relabeled.icon, original.icon);
  });
}
