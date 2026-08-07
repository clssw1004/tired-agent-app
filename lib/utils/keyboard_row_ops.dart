import 'package:tired_agent_app/utils/terminal_keys.dart';

/// Direction to move a keyboard key in the scheme editor.
enum KeyMoveDir { left, right, up, down }

/// Swap-based key movement for the keyboard scheme editor.
///
/// Moves `rows[r][c]` one step in [dir] by exchanging it with the neighbour:
/// - [KeyMoveDir.left] / [KeyMoveDir.right]: swap with the adjacent key in the
///   same row.
/// - [KeyMoveDir.up] / [KeyMoveDir.down]: swap with the key in the adjacent row
///   at the same column (clamped to the target row's length, so a shorter row
///   swaps with its last key). Rows keep their length — the layout shape is
///   preserved.
///
/// Returns `false` (leaving `rows` untouched) when the move would cross a
/// boundary: first/last column, or first/last row whose neighbour is empty.
bool moveKey(List<List<TerminalKeyDef>> rows, int r, int c, KeyMoveDir dir) {
  if (r < 0 || r >= rows.length) return false;
  if (c < 0 || c >= rows[r].length) return false;

  int tr = r;
  int tc = c;
  switch (dir) {
    case KeyMoveDir.left:
      if (c == 0) return false;
      tc = c - 1;
    case KeyMoveDir.right:
      if (c >= rows[r].length - 1) return false;
      tc = c + 1;
    case KeyMoveDir.up:
      if (r == 0) return false;
      tr = r - 1;
    case KeyMoveDir.down:
      if (r >= rows.length - 1) return false;
      tr = r + 1;
  }

  final target = rows[tr];
  if (target.isEmpty) return false;
  if (tc < 0 || tc >= target.length) tc = target.length - 1;

  final tmp = rows[r][c];
  rows[r][c] = target[tc];
  target[tc] = tmp;
  return true;
}
