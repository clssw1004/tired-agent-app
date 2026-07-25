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
  bool get hasAnyConnection =>
      _authService.connections.any((c) => c.status == ConnectionStatus.connected);

  // ═══════════════════════════════════════════════════════════════════
  //  Boot
  // ═══════════════════════════════════════════════════════════════════

  /// Load profiles from storage and connect all.
  Future<void> boot() async {
    try {
      await _authService.loadProfiles();
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
    notifyListeners();
    return conn;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Remove manager
  // ═══════════════════════════════════════════════════════════════════

  /// Remove a manager profile and its connection entirely.
  Future<void> removeManager(String profileId) async {
    await _authService.removeManager(profileId);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Server ref helpers
  // ═══════════════════════════════════════════════════════════════════

  Future<ServerRef?> getServerRef(String profileId, String agentId) =>
      _authService.getServerRef(profileId, agentId);
  Future<void> setServerToken(
    String profileId,
    String agentId,
    String token,
  ) => _authService.setServerToken(profileId, agentId, token);
  Future<void> forgetServer(String profileId, String agentId) =>
      _authService.forgetServer(profileId, agentId);
}
