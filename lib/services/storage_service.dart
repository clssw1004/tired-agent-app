import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:tired_agent_app/models/manager_profile.dart';

/// Wraps [FlutterSecureStorage] for tokens/credentials and
/// [SharedPreferences] for non-sensitive configuration (e.g. manager config).
class StorageService {
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  // ═══════════════════════════════════════════════════════════════════
  //  Manager profiles  (SharedPreferences)
  // ═══════════════════════════════════════════════════════════════════

  static const _kProfiles = 'manager_profiles';
  static const _kActiveId = 'active_profile_id';

  Future<void> saveProfiles(List<ManagerProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kProfiles,
      json.encode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  Future<List<ManagerProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfiles);
    if (raw != null) {
      final list = json.decode(raw) as List<dynamic>;
      final profiles = list
          .map((e) => ManagerProfile.fromJson(e as Map<String, dynamic>))
          .toList();
      // Hydrate refresh tokens from secure storage.
      for (final p in profiles) {
        p.refreshToken = await _secure.read(key: 'manager:${p.id}:refresh_token');
      }
      return profiles;
    }

    // No new-format profiles → attempt migration from old single-manager config.
    final migrated = await _tryMigrateFromOldConfig();
    if (migrated != null) {
      await saveProfiles(migrated);
      return migrated;
    }

    return [];
  }

  /// Migrate the old single-manager config to a [ManagerProfile].
  ///
  /// Old keys (in SharedPreferences):
  ///   `manager_config` → `{"baseUrl": "..."}`
  /// Old key (in FlutterSecureStorage):
  ///   `refresh_token` → "abc..."
  Future<List<ManagerProfile>?> _tryMigrateFromOldConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final oldConfig = prefs.getString('manager_config');
    if (oldConfig == null) return null;

    try {
      final config =
          (json.decode(oldConfig) as Map<String, dynamic>).cast<String, String>();
      final baseUrl = config['baseUrl'];
      if (baseUrl == null || baseUrl.isEmpty) return null;

      final oldToken = await _secure.read(key: 'refresh_token');
      if (oldToken == null) return null;

      final id = const Uuid().v4();
      final profile = ManagerProfile(
        id: id,
        name: 'Default',
        baseUrl: baseUrl,
        refreshToken: oldToken,
      );

      // Persist the refresh token under the new key.
      await _secure.write(key: 'manager:$id:refresh_token', value: oldToken);
      // Mark this profile as active.
      await prefs.setString(_kActiveId, id);
      // Clean up old keys.
      await prefs.remove('manager_config');
      await _secure.delete(key: 'refresh_token');

      return [profile];
    } catch (_) {
      // Migration failed — leave old keys intact.
      return null;
    }
  }

  Future<void> saveActiveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveId, id);
  }

  Future<String?> loadActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kActiveId);
  }

  // ─── Per-profile secure tokens ──────────────────────────────────────

  Future<void> saveManagerRefreshToken(String profileId, String token) =>
      _secure.write(key: 'manager:$profileId:refresh_token', value: token);

  Future<String?> loadManagerRefreshToken(String profileId) =>
      _secure.read(key: 'manager:$profileId:refresh_token');

  Future<void> clearManagerRefreshToken(String profileId) =>
      _secure.delete(key: 'manager:$profileId:refresh_token');

  // ═══════════════════════════════════════════════════════════════════
  //  Legacy single-manager helpers  (kept for callers not yet migrated)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> saveRefreshToken(String token) =>
      _secure.write(key: 'refresh_token', value: token);

  Future<String?> loadRefreshToken() =>
      _secure.read(key: 'refresh_token');

  Future<void> clearRefreshToken() =>
      _secure.delete(key: 'refresh_token');

  Future<void> saveCredential(String key, String value) =>
      _secure.write(key: key, value: value);

  Future<String?> getCredential(String key) =>
      _secure.read(key: key);

  Future<void> deleteCredential(String key) =>
      _secure.delete(key: key);

  Future<void> saveManagerConfig(Map<String, String> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manager_config', json.encode(config));
  }

  Future<Map<String, String>?> loadManagerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('manager_config');
    if (val == null) return null;
    return (json.decode(val) as Map<String, dynamic>).cast<String, String>();
  }

  Future<void> clearManagerConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('manager_config');
  }
}
