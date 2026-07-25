import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/services/storage_service.dart';

/// Manages multiple simultaneous manager connections.
///
/// No concept of "active profile" — every profile is an independent
/// [ManagerConnection] with its own transport. Callers obtain the
/// connection they need via [connectionFor] or [transportFor].
class AuthService {
  final StorageService storage;
  final Map<String, ManagerConnection> _connections = {};

  AuthService({StorageService? storage})
    : storage = storage ?? StorageService();

  // ─── Connections ──────────────────────────────────────────────────────

  /// All live connections (read-only).
  List<ManagerConnection> get connections => List.unmodifiable(
    _connections.values.toList(),
  );

  /// The stored profiles (read-only).
  List<ManagerProfile> get profiles => List.unmodifiable(
    _connections.values.map((c) => c.profile).toList(),
  );

  /// Get or create a connection for [profileId].
  ///
  /// The transport is lazily created on first access.
  ManagerConnection? connectionFor(String profileId) =>
      _connections[profileId];

  /// Get the transport for [profileId].
  ///
  /// Convenience shortcut — equivalent to
  /// `connectionFor(profileId)?.transport`.
  Transport? transportFor(String profileId) =>
      connectionFor(profileId)?.transport;

  /// Connect (or re-authenticate) the given profile.
  Future<void> connectProfile(String profileId, {String? apiToken}) async {
    final conn = _connections[profileId];
    if (conn == null) throw Exception('Profile not found: $profileId');
    await conn.connect(apiToken: apiToken);

    // Persist the new refresh token after any successful auth.
    if (conn.status == ConnectionStatus.connected &&
        conn.profile.refreshToken != null) {
      await storage.saveManagerRefreshToken(
        profileId,
        conn.profile.refreshToken!,
      );
    }
  }

  /// Disconnect and unregister a connection.
  Future<void> disconnectProfile(String profileId) async {
    final conn = _connections.remove(profileId);
    if (conn != null) {
      await conn.disconnect();
      conn.dispose();
    }
  }

  /// Connect all profiles that have credentials (for app boot).
  Future<void> connectAll() async {
    await Future.wait(
      _connections.values.map((conn) async {
        if (conn.profile.refreshToken != null || conn.profile.sessionToken != null) {
          await conn.connect();
          // Persist rotated refresh token (single-use sliding refresh).
          if (conn.status == ConnectionStatus.connected &&
              conn.profile.refreshToken != null) {
            await storage.saveManagerRefreshToken(
              conn.profile.id,
              conn.profile.refreshToken!,
            );
          }
        }
      }),
      eagerError: false,
    );
  }

  // ─── Boot / load ──────────────────────────────────────────────────────

  /// Load persisted profiles from storage and create connections.
  ///
  /// Does NOT automatically connect — call [connectAll] separately.
  Future<void> loadProfiles() async {
    final saved = await storage.loadProfiles();
    debugPrint('[AuthService] loadProfiles: ${saved.length} profiles loaded');
    _connections.clear();
    for (final profile in saved) {
      final conn = ManagerConnection(profile: profile);
      _connections[profile.id] = conn;
    }

    // Restore refresh tokens from secure storage.
    for (final conn in _connections.values) {
      conn.profile.refreshToken =
          await storage.loadManagerRefreshToken(conn.profile.id);
      debugPrint(
        '[AuthService]  profile=${conn.profile.name} '
        'refreshToken=${conn.profile.refreshToken != null}',
      );
    }
  }

  // ─── Login (add new manager) ──────────────────────────────────────────

  /// Add and authenticate a new manager.
  ///
  /// Creates a [ManagerProfile] (or reuses an existing one with the same
  /// URL), then connects it.  Returns the [ManagerConnection] on success.
  Future<ManagerConnection> login(
    String url,
    String apiToken, {
    String? name,
  }) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');

    // Check for existing profile with the same URL.
    final existing = _connections.values
        .where((c) => c.profile.baseUrl == normalized)
        .firstOrNull;

    if (existing != null) {
      await existing.disconnect();
      await existing.connect(apiToken: apiToken);
      // Persist the new refresh token (rotated by login).
      if (existing.status == ConnectionStatus.connected &&
          existing.profile.refreshToken != null) {
        await storage.saveManagerRefreshToken(
          existing.profile.id,
          existing.profile.refreshToken!,
        );
      }
      // Update name if caller provided one.
      if (name != null) existing.profile.name = name;
      await _persistProfiles();
      return existing;
    }

    // Create new profile.
    // Create new profile.
    final profile = ManagerProfile(
      id: const Uuid().v4(),
      name: name ?? _suggestName(normalized),
      baseUrl: normalized,
    );
    final conn = ManagerConnection(profile: profile);
    await conn.connect(apiToken: apiToken);
    _connections[profile.id] = conn;

    // Persist refresh token.
    if (conn.profile.refreshToken != null) {
      await storage.saveManagerRefreshToken(
        profile.id,
        conn.profile.refreshToken!,
      );
    }

    await _persistProfiles();
    return conn;
  }

  // ─── Remove manager ───────────────────────────────────────────────────

  /// Remove a manager profile and its connection entirely.
  Future<void> removeManager(String id) async {
    await disconnectProfile(id);
    await storage.clearManagerRefreshToken(id);
    await _persistProfiles();
  }

  // ─── Agent refs ───────────────────────────────────────────────────────

  /// Build a [ServerRef] for the given agent under the given profile.
  Future<ServerRef?> getServerRef(
    String profileId,
    String agentId,
  ) async {
    final conn = _connections[profileId];
    if (conn == null) return null;
    final agent = conn.agents.where((a) => a.id == agentId).firstOrNull;
    if (agent == null) return null;
    final token = await storage.getCredential(
      'server:${conn.profile.id}:$agentId:token',
    );
    if (token == null) return null;
    return ServerRef(
      id: agentId,
      name: agent.name,
      baseUrl: agent.baseUrl,
      token: token,
    );
  }

  Future<void> setServerToken(
    String profileId,
    String agentId,
    String token,
  ) async {
    final conn = _connections[profileId];
    if (conn == null) return;
    await storage.saveCredential(
      'server:${conn.profile.id}:$agentId:token',
      token,
    );
  }

  Future<void> forgetServer(String profileId, String agentId) async {
    final conn = _connections[profileId];
    if (conn == null) return;
    await storage.deleteCredential(
      'server:${conn.profile.id}:$agentId:token',
    );
  }

  // ─── Internals ────────────────────────────────────────────────────────

  Future<void> _persistProfiles() async {
    await storage.saveProfiles(profiles);
  }

  static String _suggestName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url.length > 24 ? '${url.substring(0, 24)}…' : url;
    }
  }
}
