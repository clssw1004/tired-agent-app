import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:tired_agent_app/models/pty_keyboard_scheme.dart';
import 'package:tired_agent_app/services/pty_keyboard_scheme_service.dart';
import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// Reactive wrapper over [PtyKeyboardSchemeService].
///
/// Call [load] once at boot. Every create/update/delete/reset notifies
/// listeners so the scheme manager, create-session picker and PTY page stay
/// in sync.
class PtyKeyboardSchemeProvider extends ChangeNotifier {
  final PtyKeyboardSchemeService _service;
  final Uuid _uuid = const Uuid();

  PtyKeyboardPrefs _prefs = PtyKeyboardPrefs.empty();
  bool _loaded = false;

  PtyKeyboardSchemeProvider({PtyKeyboardSchemeService? service})
    : _service = service ?? PtyKeyboardSchemeService();

  // ── Scheme accessors ──────────────────────────────────────────────

  /// Builtin presets surfaced as schemes so pickers can offer them uniformly.
  List<PtyKeyboardScheme> get builtinSchemes => PtyKeyboardConfig.presets
      .map(
        (c) => PtyKeyboardScheme(
          id: c.id,
          name: c.name,
          basePresetId: c.id,
          rows: c.rows,
        ),
      )
      .toList();

  List<PtyKeyboardScheme> get userSchemes =>
      List.unmodifiable(_prefs.schemes.reversed);

  /// All schemes (builtin + user) in display order.
  List<PtyKeyboardScheme> get allSchemes => [
    ...builtinSchemes,
    ..._prefs.schemes.reversed,
  ];

  /// Client-side default scheme id, or `null` for "let the command preset
  /// decide".
  String? get defaultSchemeId => _prefs.defaultSchemeId;

  bool get isLoaded => _loaded;

  // ── Boot ──────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await _service.load();
    _loaded = true;
    notifyListeners();
  }

  // ── Lookup ────────────────────────────────────────────────────────

  /// Look up a scheme by id, searching user schemes first then builtin
  /// presets. Returns `null` when the id is unknown or refers to a scheme
  /// that's been deleted — callers (e.g. [configForSession]) fall through.
  PtyKeyboardScheme? byId(String? id) {
    if (id == null) return null;
    for (final s in allSchemes) {
      if (s.id == id) return s;
    }
    return null;
  }

  bool isBuiltin(String id) => PtyKeyboardConfig.byId(id) != null;

  /// Resolve the effective config for a session.
  ///
  /// Resolution chain:
  ///   1. Session-specific scheme id (if any).
  ///   2. Client-wide default scheme id (if any).
  ///   3. Builtin preset matched by command name.
  ///
  /// Each step falls through to the next when its id no longer resolves to
  /// an existing scheme (e.g. user deleted it on the server / file), so
  /// stale ids never strand the user on a blank layout.
  PtyKeyboardConfig configForSession(String cmd, {String? sessionId}) {
    final id = sessionId != null ? _prefs.sessionAssignments[sessionId] : null;
    final sessionScheme = byId(id);
    if (sessionScheme != null) return sessionScheme.toConfig();
    final defaultScheme = byId(_prefs.defaultSchemeId);
    if (defaultScheme != null) return defaultScheme.toConfig();
    return PtyKeyboardConfig.fromCommand(cmd);
  }

  // ── Default scheme ────────────────────────────────────────────────

  Future<void> setDefaultSchemeId(String? id) async {
    if (_prefs.defaultSchemeId == id) return;
    _prefs = _prefs.copyWith(
      defaultSchemeId: id,
      clearDefaultSchemeId: id == null,
    );
    await _service.save(_prefs);
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────

  Future<PtyKeyboardScheme> create({
    required String name,
    required List<List<TerminalKeyDef>> rows,
    String? basePresetId,
  }) async {
    final scheme = PtyKeyboardScheme(
      id: _uuid.v4(),
      name: name,
      basePresetId: basePresetId,
      rows: rows,
    );
    _prefs = _prefs.copyWith(schemes: [..._prefs.schemes, scheme]);
    await _service.save(_prefs);
    notifyListeners();
    return scheme;
  }

  Future<void> update(PtyKeyboardScheme scheme) async {
    final idx = _prefs.schemes.indexWhere((s) => s.id == scheme.id);
    if (idx == -1) return;
    final next = [..._prefs.schemes]..[idx] = scheme;
    _prefs = _prefs.copyWith(schemes: next);
    await _service.save(_prefs);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final next = _prefs.schemes.where((s) => s.id != id).toList();
    var prefs = _prefs.copyWith(schemes: next);
    // If the deleted scheme was the default, clear it so byId falls through.
    if (prefs.defaultSchemeId == id) {
      prefs = prefs.copyWith(clearDefaultSchemeId: true);
    }
    // Drop stale session assignments pointing at it.
    final assignments = Map<String, String>.from(prefs.sessionAssignments)
      ..removeWhere((_, schemeId) => schemeId == id);
    prefs = prefs.copyWith(sessionAssignments: assignments);
    _prefs = prefs;
    await _service.save(_prefs);
    notifyListeners();
  }

  /// Replace a user scheme's rows with those of its base preset.
  Future<void> resetToPreset(String id) async {
    final idx = _prefs.schemes.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final scheme = _prefs.schemes[idx];
    final preset = scheme.basePresetId == null
        ? null
        : PtyKeyboardConfig.byId(scheme.basePresetId!);
    if (preset == null) return;
    final next = [..._prefs.schemes]
      ..[idx] = PtyKeyboardScheme(
        id: scheme.id,
        name: scheme.name,
        basePresetId: scheme.basePresetId,
        rows: preset.rows,
      );
    _prefs = _prefs.copyWith(schemes: next);
    await _service.save(_prefs);
    notifyListeners();
  }

  // ── Per-session assignment ─────────────────────────────────────────

  final Map<String, String> _sessionSchemeId = {};

  /// Remember a session's chosen scheme id in memory only (sync path).
  void rememberSessionScheme(String sessionId, String schemeId) {
    _sessionSchemeId[sessionId] = schemeId;
  }

  /// Load a session's assigned scheme id from storage (async).
  Future<String?> loadSessionScheme(String sessionId) async {
    final existing = _sessionSchemeId[sessionId];
    if (existing != null) return existing;
    final id = _prefs.sessionAssignments[sessionId];
    if (id != null) _sessionSchemeId[sessionId] = id;
    return id;
  }

  /// Persist a session's scheme assignment.
  Future<void> assignSchemeToSession(String sessionId, String schemeId) async {
    _sessionSchemeId[sessionId] = schemeId;
    final assignments = Map<String, String>.from(_prefs.sessionAssignments)
      ..[sessionId] = schemeId;
    _prefs = _prefs.copyWith(sessionAssignments: assignments);
    await _service.save(_prefs);
    notifyListeners();
  }

  /// Remove a session's scheme assignment (falls back through the chain).
  Future<void> unassignSessionScheme(String sessionId) async {
    _sessionSchemeId.remove(sessionId);
    if (!_prefs.sessionAssignments.containsKey(sessionId)) return;
    final assignments = Map<String, String>.from(_prefs.sessionAssignments)
      ..remove(sessionId);
    _prefs = _prefs.copyWith(sessionAssignments: assignments);
    await _service.save(_prefs);
    notifyListeners();
  }
}
