/// Terminal key definitions and composition utilities.
///
/// Provides:
/// - [TerminalKeyCode] enum covering all base keys (letters, digits, modifiers,
///   navigation, function keys, special keys)
/// - [TerminalKeyDef] value class holding id, display label, byte sequence,
///   modifier flag, composition info, and optional icon
/// - [TerminalKeys] static factory with pre-defined constants for every base
///   key and helper methods to produce combination shortcuts (Ctrl+X, Alt+X,
///   text commands with optional icons)
library;

import 'dart:math';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Key codes
// ---------------------------------------------------------------------------

/// Identifies every terminal key that can appear in a shortcut definition or
/// on a virtual keyboard button.
enum TerminalKeyCode {
  // Modifiers
  ctrl,
  alt,
  shift,

  // Letters (a–z)
  a,
  b,
  c,
  d,
  e,
  f,
  g,
  h,
  i,
  j,
  k,
  l,
  m,
  n,
  o,
  p,
  q,
  r,
  s,
  t,
  u,
  v,
  w,
  x,
  y,
  z,

  // Digits (0–9) — prefixed with n to avoid Dart keyword clash
  n0,
  n1,
  n2,
  n3,
  n4,
  n5,
  n6,
  n7,
  n8,
  n9,

  // Navigation
  up,
  down,
  left,
  right,

  // Special
  tab,
  escape,
  enter,
  backspace,
  home,
  end,
  pageUp,
  pageDown,
  delete,

  // Function
  f1,
  f2,
  f3,
  f4,
  f5,
  f6,
  f7,
  f8,
  f9,
  f10,
  f11,
  f12,

  // Symbols
  space,
  dot,
  comma,
  semicolon,
  colon,
  slash,
  backslash,
  minus,
  equal,
  backquote,
  bracketLeft,
  bracketRight,
  quote,
}

// ---------------------------------------------------------------------------
// Key definition
// ---------------------------------------------------------------------------

/// Immutable descriptor for a single key or a key combination.
///
/// Instances are created via:
/// - Pre-defined constants on [TerminalKeys] for every base key
/// - [TerminalKeys.combo] for auto-resolved combinations
/// - [TerminalKeys.commandShowText] for text command buttons with optional icon
class TerminalKeyDef {
  /// Machine-readable identifier (e.g. `"ctrl+c"`, `"up"`, `"f1"`).
  final String id;

  /// Human-readable label shown on the virtual key button.
  /// When [icon] is set, this may still be used for accessibility / tooltip.
  final String label;

  /// Optional icon to show on the button instead of plain text.
  final IconData? icon;

  /// Byte sequence to send over the PTY transport.
  final List<int> bytes;

  /// Whether this is a modifier toggle key (Ctrl / Alt / Shift).
  final bool isMod;

  /// The individual key codes this definition is composed of.
  /// Empty list for primitive keys; `[ctrl, c]` for Ctrl+C, etc.
  final List<TerminalKeyCode> composedOf;

  /// Whether tapping this key requires confirmation before sending.
  /// When `true` a default confirm dialog is shown.
  /// Combine with [confirmMessage] for custom prompt text.
  final bool confirm;

  /// Custom confirmation message. When set alongside [confirm], overrides
  /// the default dialog text.
  final String? confirmMessage;

  const TerminalKeyDef({
    required this.id,
    required this.label,
    required this.bytes,
    this.icon,
    this.isMod = false,
    this.composedOf = const [],
    this.confirm = false,
    this.confirmMessage,
  });
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

/// Pre-defined terminal key constants and composition helpers.
class TerminalKeys {
  TerminalKeys._();

  // ── Modifiers ──────────────────────────────────────────────────────────
  static const ctrl = TerminalKeyDef(
    id: 'ctrl',
    label: 'Ctrl',
    bytes: [],
    isMod: true,
  );
  static const alt = TerminalKeyDef(
    id: 'alt',
    label: 'Alt',
    bytes: [],
    isMod: true,
  );
  static const shift = TerminalKeyDef(
    id: 'shift',
    label: 'Shift',
    bytes: [],
    isMod: true,
  );

  // ── Letters a–z ───────────────────────────────────────────────────────
  static const a = TerminalKeyDef(id: 'a', label: 'A', bytes: [0x61]);
  static const b = TerminalKeyDef(id: 'b', label: 'B', bytes: [0x62]);
  static const c = TerminalKeyDef(id: 'c', label: 'C', bytes: [0x63]);
  static const d = TerminalKeyDef(id: 'd', label: 'D', bytes: [0x64]);
  static const e = TerminalKeyDef(id: 'e', label: 'E', bytes: [0x65]);
  static const f = TerminalKeyDef(id: 'f', label: 'F', bytes: [0x66]);
  static const g = TerminalKeyDef(id: 'g', label: 'G', bytes: [0x67]);
  static const h = TerminalKeyDef(id: 'h', label: 'H', bytes: [0x68]);
  static const i = TerminalKeyDef(id: 'i', label: 'I', bytes: [0x69]);
  static const j = TerminalKeyDef(id: 'j', label: 'J', bytes: [0x6A]);
  static const k = TerminalKeyDef(id: 'k', label: 'K', bytes: [0x6B]);
  static const l = TerminalKeyDef(id: 'l', label: 'L', bytes: [0x6C]);
  static const m = TerminalKeyDef(id: 'm', label: 'M', bytes: [0x6D]);
  static const n = TerminalKeyDef(id: 'n', label: 'N', bytes: [0x6E]);
  static const o = TerminalKeyDef(id: 'o', label: 'O', bytes: [0x6F]);
  static const p = TerminalKeyDef(id: 'p', label: 'P', bytes: [0x70]);
  static const q = TerminalKeyDef(id: 'q', label: 'Q', bytes: [0x71]);
  static const r = TerminalKeyDef(id: 'r', label: 'R', bytes: [0x72]);
  static const s = TerminalKeyDef(id: 's', label: 'S', bytes: [0x73]);
  static const t = TerminalKeyDef(id: 't', label: 'T', bytes: [0x74]);
  static const u = TerminalKeyDef(id: 'u', label: 'U', bytes: [0x75]);
  static const v = TerminalKeyDef(id: 'v', label: 'V', bytes: [0x76]);
  static const w = TerminalKeyDef(id: 'w', label: 'W', bytes: [0x77]);
  static const x = TerminalKeyDef(id: 'x', label: 'X', bytes: [0x78]);
  static const y = TerminalKeyDef(id: 'y', label: 'Y', bytes: [0x79]);
  static const z = TerminalKeyDef(id: 'z', label: 'Z', bytes: [0x7A]);

  // ── Digits 0–9 ────────────────────────────────────────────────────────
  static const n0 = TerminalKeyDef(id: '0', label: '0', bytes: [0x30]);
  static const n1 = TerminalKeyDef(id: '1', label: '1', bytes: [0x31]);
  static const n2 = TerminalKeyDef(id: '2', label: '2', bytes: [0x32]);
  static const n3 = TerminalKeyDef(id: '3', label: '3', bytes: [0x33]);
  static const n4 = TerminalKeyDef(id: '4', label: '4', bytes: [0x34]);
  static const n5 = TerminalKeyDef(id: '5', label: '5', bytes: [0x35]);
  static const n6 = TerminalKeyDef(id: '6', label: '6', bytes: [0x36]);
  static const n7 = TerminalKeyDef(id: '7', label: '7', bytes: [0x37]);
  static const n8 = TerminalKeyDef(id: '8', label: '8', bytes: [0x38]);
  static const n9 = TerminalKeyDef(id: '9', label: '9', bytes: [0x39]);

  // ── Navigation ────────────────────────────────────────────────────────
  static const up = TerminalKeyDef(
    id: 'up',
    label: '↑',
    bytes: [0x1B, 0x5B, 0x41],
  );
  static const down = TerminalKeyDef(
    id: 'down',
    label: '↓',
    bytes: [0x1B, 0x5B, 0x42],
  );
  static const left = TerminalKeyDef(
    id: 'left',
    label: '←',
    bytes: [0x1B, 0x5B, 0x44],
  );
  static const right = TerminalKeyDef(
    id: 'right',
    label: '→',
    bytes: [0x1B, 0x5B, 0x43],
  );

  // ── Special ───────────────────────────────────────────────────────────
  static const tab = TerminalKeyDef(id: 'tab', label: 'Tab', bytes: [0x09]);
  static const escape = TerminalKeyDef(
    id: 'escape',
    label: 'Esc',
    bytes: [0x1B],
  );
  static const enter = TerminalKeyDef(
    id: 'enter',
    label: '⏎',
    bytes: [0x0D],
    icon: Icons.keyboard_return,
  );
  static const backspace = TerminalKeyDef(
    id: 'backspace',
    label: '⌫',
    bytes: [0x7F],
    icon: Icons.backspace,
  );
  static const home = TerminalKeyDef(
    id: 'home',
    label: 'Home',
    bytes: [0x1B, 0x5B, 0x48],
  );
  static const end = TerminalKeyDef(
    id: 'end',
    label: 'End',
    bytes: [0x1B, 0x5B, 0x46],
  );
  static const pageUp = TerminalKeyDef(
    id: 'pageUp',
    label: 'PgUp',
    bytes: [0x1B, 0x5B, 0x35, 0x7E],
  );
  static const pageDown = TerminalKeyDef(
    id: 'pageDown',
    label: 'PgDn',
    bytes: [0x1B, 0x5B, 0x36, 0x7E],
  );
  static const delete = TerminalKeyDef(
    id: 'delete',
    label: 'Del',
    bytes: [0x1B, 0x5B, 0x33, 0x7E],
  );

  // ── Function keys F1–F12 ──────────────────────────────────────────────
  static const f1 = TerminalKeyDef(
    id: 'f1',
    label: 'F1',
    bytes: [0x1B, 0x4F, 0x50],
  );
  static const f2 = TerminalKeyDef(
    id: 'f2',
    label: 'F2',
    bytes: [0x1B, 0x4F, 0x51],
  );
  static const f3 = TerminalKeyDef(
    id: 'f3',
    label: 'F3',
    bytes: [0x1B, 0x4F, 0x52],
  );
  static const f4 = TerminalKeyDef(
    id: 'f4',
    label: 'F4',
    bytes: [0x1B, 0x4F, 0x53],
  );
  static const f5 = TerminalKeyDef(
    id: 'f5',
    label: 'F5',
    bytes: [0x1B, 0x5B, 0x31, 0x35, 0x7E],
  );
  static const f6 = TerminalKeyDef(
    id: 'f6',
    label: 'F6',
    bytes: [0x1B, 0x5B, 0x31, 0x37, 0x7E],
  );
  static const f7 = TerminalKeyDef(
    id: 'f7',
    label: 'F7',
    bytes: [0x1B, 0x5B, 0x31, 0x38, 0x7E],
  );
  static const f8 = TerminalKeyDef(
    id: 'f8',
    label: 'F8',
    bytes: [0x1B, 0x5B, 0x31, 0x39, 0x7E],
  );
  static const f9 = TerminalKeyDef(
    id: 'f9',
    label: 'F9',
    bytes: [0x1B, 0x5B, 0x32, 0x30, 0x7E],
  );
  static const f10 = TerminalKeyDef(
    id: 'f10',
    label: 'F10',
    bytes: [0x1B, 0x5B, 0x32, 0x31, 0x7E],
  );
  static const f11 = TerminalKeyDef(
    id: 'f11',
    label: 'F11',
    bytes: [0x1B, 0x5B, 0x32, 0x33, 0x7E],
  );
  static const f12 = TerminalKeyDef(
    id: 'f12',
    label: 'F12',
    bytes: [0x1B, 0x5B, 0x32, 0x34, 0x7E],
  );

  // ── Symbols ───────────────────────────────────────────────────────────
  static const space = TerminalKeyDef(id: 'space', label: '␣', bytes: [0x20]);
  static const dot = TerminalKeyDef(id: 'dot', label: '.', bytes: [0x2E]);
  static const comma = TerminalKeyDef(id: 'comma', label: ',', bytes: [0x2C]);
  static const semicolon = TerminalKeyDef(
    id: 'semicolon',
    label: ';',
    bytes: [0x3B],
  );

  // ═══════════════════════════════════════════════════════════════════════
  // Combo factories
  // ═══════════════════════════════════════════════════════════════════════

  /// Create a combo from a list of key codes — auto-resolves bytes and label.
  ///
  /// Supported patterns:
  /// | Input | Result | Default label |
  /// |-------|--------|---------------|
  /// | `[ctrl, a]` … `[ctrl, z]` | control char `0x01`…`0x1A` | `^X` |
  /// | `[alt, a]` … `[alt, z]` | `ESC` + letter | `M-X` |
  /// | `[shift, a]` … `[shift, z]` | uppercase ASCII | `X` |
  /// | `[shift, tab]` | backtab `\E[Z` | `⇧Tab` |
  ///
  /// Throws [ArgumentError] for unrecognised patterns — use [commandShowText] instead.
  static TerminalKeyDef combo(
    List<TerminalKeyCode> keys, {
    String? label,
    String? id,
    IconData? icon,
    bool confirm = false,
    String? confirmMessage,
  }) {
    final resolvedBytes = _resolveBytes(keys);
    if (resolvedBytes == null) _throwUnrecognised(keys);

    final msg =
        confirmMessage ??
        (confirm ? 'Send ${keys.map((k) => k.name).join('+')}?' : null);

    return TerminalKeyDef(
      id: id ?? keys.map((k) => k.name).join('+'),
      label:
          label ??
          (keys.length == 2
              ? _defaultLabel(keys[0], keys[1])
              : keys.map((k) => k.name).join('+')),
      bytes: resolvedBytes,
      icon: icon,
      composedOf: keys,
      confirm: confirm,
      confirmMessage: msg,
    );
  }

  /// Define a key that sends a text command with a text label.
  static TerminalKeyDef commandShowText({
    required String label,
    required String command,
    bool withEnter = false,
    List<TerminalKeyCode>? composedOf,
    String? id,
    bool confirm = false,
    String? confirmMessage,
  }) {
    return _command(
      command: command,
      label: label,
      withEnter: withEnter,
      composedOf: composedOf,
      id: id,
      confirm: confirm,
      confirmMessage: confirmMessage,
    );
  }

  /// Define a key that sends a text command with an icon instead of text.
  static TerminalKeyDef commandShowIcon({
    required IconData icon,
    required String command,
    bool withEnter = false,
    List<TerminalKeyCode>? composedOf,
    String? id,
    bool confirm = false,
    String? confirmMessage,
  }) {
    return _command(
      command: command,
      icon: icon,
      withEnter: withEnter,
      composedOf: composedOf,
      id: id,
      confirm: confirm,
      confirmMessage: confirmMessage,
    );
  }

  /// Shared implementation for [commandShowText] / [commandShowIcon].
  static TerminalKeyDef _command({
    required String command,
    String? label,
    IconData? icon,
    bool withEnter = false,
    List<TerminalKeyCode>? composedOf,
    String? id,
    bool confirm = false,
    String? confirmMessage,
  }) {
    final bytes = withEnter ? [...command.codeUnits, 0x0D] : command.codeUnits;
    final msg = confirmMessage ?? (confirm ? 'Execute [$command]?' : null);
    return TerminalKeyDef(
      id: id ?? _randomId(),
      label: label ?? '',
      bytes: bytes,
      icon: icon,
      composedOf: composedOf ?? const [],
      confirm: confirm,
      confirmMessage: msg,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────

  static final _rng = Random();
  static const _idChars = 'abcdefghijklmnopqrstuvwxyz23456789';

  /// Generate an 8‑character random string for use as a key id.
  static String _randomId() =>
      List.generate(8, (_) => _idChars[_rng.nextInt(_idChars.length)]).join();

  static Never _throwUnrecognised(List<TerminalKeyCode> keys) {
    throw ArgumentError(
      'Unrecognised combo: $keys. '
      'Use TerminalKeys.command() for text commands.',
    );
  }

  /// Generate default label for a two-key combo.
  static String _defaultLabel(TerminalKeyCode first, TerminalKeyCode second) {
    if (first == TerminalKeyCode.ctrl) {
      return '^${second.name.toUpperCase()}';
    }
    if (first == TerminalKeyCode.alt) {
      return 'M-${second.name.toUpperCase()}';
    }
    if (first == TerminalKeyCode.shift) {
      if (second == TerminalKeyCode.tab) return '⇧Tab';
      return second.name.toUpperCase();
    }
    return '${first.name}+${second.name}';
  }

  /// Try to resolve the byte sequence for [keys].
  /// Returns `null` if the pattern isn't recognised.
  static List<int>? _resolveBytes(List<TerminalKeyCode> keys) {
    if (keys.length < 2) return null;

    // Ctrl + letter a-z
    if (keys[0] == TerminalKeyCode.ctrl &&
        keys.length == 2 &&
        _isLetter(keys[1])) {
      return [keys[1].index - TerminalKeyCode.a.index + 1];
    }

    // Alt + letter a-z
    if (keys[0] == TerminalKeyCode.alt &&
        keys.length == 2 &&
        _isLetter(keys[1])) {
      return [0x1B, 97 + keys[1].index - TerminalKeyCode.a.index];
    }

    // Shift + letter a-z
    if (keys[0] == TerminalKeyCode.shift &&
        keys.length == 2 &&
        _isLetter(keys[1])) {
      return [65 + keys[1].index - TerminalKeyCode.a.index];
    }

    // Shift + Tab -> backtab
    if (keys.length == 2 &&
        keys[0] == TerminalKeyCode.shift &&
        keys[1] == TerminalKeyCode.tab) {
      return [0x1B, 0x5B, 0x5A];
    }

    return null;
  }

  /// Whether [code] is a letter a-z.
  static bool _isLetter(TerminalKeyCode code) {
    final idx = code.index - TerminalKeyCode.a.index;
    return idx >= 0 && idx <= 25;
  }
}
