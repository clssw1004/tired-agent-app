import 'package:flutter/foundation.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/services/auth_service.dart';

/// Reactive provider for multi-manager connections.
///
/// No longer has a single "active profile" or global [AuthStatus].
/// All state is per-connection — access it via [connections] or
/// [connectionFor].
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  // ─── Connection access ───────────────────────────────────────────────

  /// All managed connections.
  List<ManagerConnection> get connections => _authService.connections;

  /// All stored profiles (derived from connections).
  List<ManagerProfile> get profiles => _authService.profiles;

  /// Look up a connection by [profileId].
  ManagerConnection? connectionFor(String profileId) =>
      _authService.connectionFor(profileId);

  /// Convenience helper — the transport for [profileId].
  Transport? transportFor(String profileId) =>
      _authService.transportFor(profileId);

  /// Whether there is at least one connected manager.
  bool get hasAnyConnection => _authService.connections.any(
    (c) => c.status == ConnectionStatus.connected,
  );

  // ═══════════════════════════════════════════════════════════════════
  //  Boot
  // ═══════════════════════════════════════════════════════════════════

  /// Load profiles from storage and connect all.
  Future<void> boot() async {
    try {
      await _authService.loadProfiles();
      _listenToAll();
      // Show saved profiles immediately, even if connectAll() is slow.
      notifyListeners();
      await _authService.connectAll();
    } catch (_) {
      // Individual connection errors are recorded per-connection;
      // a boot failure is not fatal.
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Login / add manager
  // ═══════════════════════════════════════════════════════════════════

  /// Add a new manager and connect it.
  ///
  /// Returns the new [ManagerConnection] on success.
  Future<ManagerConnection> login(
    String url,
    String token, {
    String? name,
  }) async {
    final conn = await _authService.login(url, token, name: name);
    conn.addListener(notifyListeners);
    notifyListeners();
    return conn;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Remove manager
  // ═══════════════════════════════════════════════════════════════════

  /// Remove a manager profile and its connection entirely.
  Future<void> removeManager(String profileId) async {
    final conn = _authService.connectionFor(profileId);
    conn?.removeListener(notifyListeners);
    await _authService.removeManager(profileId);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Reconnect (login with new API token)
  // ═══════════════════════════════════════════════════════════════════

  /// Reconnect a manager with a fresh [apiToken].
  ///
  /// Persists the new refresh token so the connection survives app restarts.
  Future<bool> reconnect(String profileId, String apiToken) async {
    final conn = _authService.connectionFor(profileId);
    if (conn == null) return false;
    await conn.connect(apiToken: apiToken);
    debugPrint(
      '[AuthProvider] reconnect status=${conn.status} error=${conn.error}',
    );
    if (conn.status == ConnectionStatus.connected) {
      await _authService.persistRefreshToken(conn);
      if (conn.profile.refreshToken == null) {
        debugPrint('[AuthProvider] WARN refreshToken is null after connect');
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Session health
  // ═══════════════════════════════════════════════════════════════════

  /// 刷新所有 manager 的 session（静默，不阻塞 UI）。
  Future<void> refreshAllSessions() => _authService.refreshAllSessions();

  // ═══════════════════════════════════════════════════════════════════
  //  Internal helpers
  // ═══════════════════════════════════════════════════════════════════

  void _listenToAll() {
    for (final conn in _authService.connections) {
      conn.addListener(notifyListeners);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Server ref helpers
  // ═══════════════════════════════════════════════════════════════════

  Future<ServerRef?> getServerRef(String profileId, String agentId) =>
      _authService.getServerRef(profileId, agentId);
  Future<void> setServerToken(String profileId, String agentId, String token) =>
      _authService.setServerToken(profileId, agentId, token);
  Future<void> forgetServer(String profileId, String agentId) =>
      _authService.forgetServer(profileId, agentId);
}
