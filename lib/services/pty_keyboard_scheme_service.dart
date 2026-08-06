import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:tired_agent_app/models/pty_keyboard_scheme.dart';

/// File-backed persistence for user-defined keyboard schemes, the default
/// scheme id, and per-session scheme assignments.
///
/// All three live in a single JSON file (`keyboard_prefs.json`) under the
/// platform's app-private support directory. Writes go through a temp file +
/// rename so a mid-write crash never leaves a half-written prefs file.
class PtyKeyboardSchemeService {
  /// Default file name (lives under the app support directory).
  static const String defaultFileName = 'keyboard_prefs.json';

  /// Resolves to the prefs file location. Injectable for tests.
  final Future<File> Function() _fileProvider;

  PtyKeyboardSchemeService({Future<File> Function()? fileProvider})
    : _fileProvider =
          fileProvider ?? _defaultFileProvider(defaultFileName);

  /// Build a file provider that resolves `getApplicationSupportDirectory()`
  /// on every call (so the path is fresh after tests reset `PathProviderPlatform`).
  static Future<File> Function() _defaultFileProvider(String fileName) {
    return () async {
      final dir = await getApplicationSupportDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return File('${dir.path}/$fileName');
    };
  }

  /// Factory used by tests to inject a temp directory.
  factory PtyKeyboardSchemeService.withDirectory(Directory dir) =>
      PtyKeyboardSchemeService(
        fileProvider: () async => File('${dir.path}/$defaultFileName'),
      );

  /// Load the persisted preferences bundle. Missing or corrupt file yields
  /// empty defaults — never throws, so a bad disk write can't crash the app.
  Future<PtyKeyboardPrefs> load() async {
    final file = await _fileProvider();
    if (!await file.exists()) return PtyKeyboardPrefs.empty();
    try {
      final raw = await file.readAsString();
      if (raw.isEmpty) return PtyKeyboardPrefs.empty();
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return PtyKeyboardPrefs.empty();
      return PtyKeyboardPrefs.fromJson(json);
    } catch (_) {
      return PtyKeyboardPrefs.empty();
    }
  }

  /// Persist the preferences bundle atomically (write to temp file, rename).
  Future<void> save(PtyKeyboardPrefs prefs) async {
    final file = await _fileProvider();
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final tmp = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await tmp.writeAsString(jsonEncode(prefs.toJson()));
      await tmp.rename(file.path);
    } catch (_) {
      // Best-effort cleanup of the temp file on failure.
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      rethrow;
    }
  }
}