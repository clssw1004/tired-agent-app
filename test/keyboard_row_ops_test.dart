import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/utils/keyboard_row_ops.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// Unit tests for [moveKey] — the swap-based movement behind the scheme
/// editor's arrow buttons.
void main() {
  /// rows: row0 [a,b,c] · row1 [d,e,f] · row2 [g] (variable length)
  List<List<TerminalKeyDef>> rows() => [
    [TerminalKeys.a, TerminalKeys.b, TerminalKeys.c],
    [TerminalKeys.d, TerminalKeys.e, TerminalKeys.f],
    [TerminalKeys.g],
  ];

  List<List<String>> ids(List<List<TerminalKeyDef>> rows) =>
      rows.map((r) => r.map((k) => k.id).toList()).toList();

  group('moveKey — left/right (same row)', () {
    test('left swaps with the previous key', () {
      final r = rows();
      expect(moveKey(r, 0, 1, KeyMoveDir.left), isTrue);
      expect(ids(r), [
        ['b', 'a', 'c'],
        ['d', 'e', 'f'],
        ['g'],
      ]);
    });

    test('right swaps with the next key', () {
      final r = rows();
      expect(moveKey(r, 0, 1, KeyMoveDir.right), isTrue);
      expect(ids(r), [
        ['a', 'c', 'b'],
        ['d', 'e', 'f'],
        ['g'],
      ]);
    });

    test('left at column 0 is a no-op', () {
      final r = rows();
      expect(moveKey(r, 0, 0, KeyMoveDir.left), isFalse);
      expect(ids(r), ids(rows()));
    });

    test('right at last column is a no-op', () {
      final r = rows();
      expect(moveKey(r, 1, 2, KeyMoveDir.right), isFalse);
      expect(ids(r), ids(rows()));
    });
  });

  group('moveKey — up/down (across rows)', () {
    test('up swaps with the key above at the same column', () {
      final r = rows();
      expect(moveKey(r, 1, 1, KeyMoveDir.up), isTrue);
      expect(ids(r), [
        ['a', 'e', 'c'],
        ['d', 'b', 'f'],
        ['g'],
      ]);
    });

    test('down swaps with the key below at the same column', () {
      final r = rows();
      expect(moveKey(r, 1, 1, KeyMoveDir.down), isTrue);
      expect(ids(r), [
        ['a', 'b', 'c'],
        ['d', 'g', 'f'],
        ['e'],
      ]);
    });

    test('up from the first row is a no-op', () {
      final r = rows();
      expect(moveKey(r, 0, 1, KeyMoveDir.up), isFalse);
      expect(ids(r), ids(rows()));
    });

    test('down from the last row is a no-op', () {
      final r = rows();
      expect(moveKey(r, 2, 0, KeyMoveDir.down), isFalse);
      expect(ids(r), ids(rows()));
    });

    test('down clamps to a shorter target row', () {
      final r = rows();
      // row2 is [g] only; moving row1 col2 (f) down clamps to row2 col0.
      expect(moveKey(r, 1, 2, KeyMoveDir.down), isTrue);
      expect(ids(r), [
        ['a', 'b', 'c'],
        ['d', 'e', 'g'],
        ['f'],
      ]);
    });

    test('moving into an empty target row is a no-op', () {
      final r = <List<TerminalKeyDef>>[
        [TerminalKeys.a],
        [],
        [TerminalKeys.b],
      ];
      expect(moveKey(r, 0, 0, KeyMoveDir.down), isFalse);
      expect(moveKey(r, 2, 0, KeyMoveDir.up), isFalse);
      expect(ids(r), [
        ['a'],
        [],
        ['b'],
      ]);
    });

    test('invalid position is a no-op', () {
      final r = rows();
      expect(moveKey(r, -1, 0, KeyMoveDir.down), isFalse);
      expect(moveKey(r, 0, 99, KeyMoveDir.left), isFalse);
      expect(moveKey(r, 99, 0, KeyMoveDir.up), isFalse);
      expect(ids(r), ids(rows()));
    });
  });
}
