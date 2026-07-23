import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [FlutterSecureStorage] for tokens/credentials and
/// [SharedPreferences] for non-sensitive configuration (e.g. manager URL).
class StorageService {
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  // ─── Refresh token ────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) =>
      _secure.write(key: 'refresh_token', value: token);

  Future<String?> loadRefreshToken() =>
      _secure.read(key: 'refresh_token');

  Future<void> clearRefreshToken() =>
      _secure.delete(key: 'refresh_token');

  // ─── Generic credentials ──────────────────────────────────────────────

  Future<void> saveCredential(String key, String value) =>
      _secure.write(key: key, value: value);

  Future<String?> getCredential(String key) =>
      _secure.read(key: key);

  Future<void> deleteCredential(String key) =>
      _secure.delete(key: key);

  // ─── Manager config (non-sensitive, persisted in shared prefs) ────────

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
