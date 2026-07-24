import 'package:flutter/foundation.dart';

import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/services/auth_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.idle;
  String? _error;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  // ─── Core getters (delegate to AuthService's active profile) ────────

  AuthStatus get status => _status;
  String? get error => _error;
  AuthService get authService => _authService;

  String? get baseUrl => _authService.baseUrl;
  String? get sessionToken => _authService.sessionToken;
  List<AgentInfo> get agents => _authService.agents;
  List<ManagerProfile> get profiles => _authService.profiles;
  String? get activeProfileId => _authService.activeProfileId;

  /// Manager-level [ServerRef] for proxied API calls.
  /// Returns `null` when not authenticated.
  ServerRef? get managerRef => _authService.managerRef;

  // ═══════════════════════════════════════════════════════════════════
  //  Boot / load profiles
  // ═══════════════════════════════════════════════════════════════════

  /// Load profiles from storage and try to restore the active session.
  Future<void> boot() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _authService.loadProfiles();
      final ap = _authService.activeProfileId;
      if (ap != null && _authService.sessionToken != null) {
        _status = AuthStatus.authenticated;
      } else if (ap != null && _authService.sessionToken == null) {
        // Profile exists but needs re-authentication — try restore.
        if (_authService.managerRef == null &&
            _authService.profiles.any((p) => p.refreshToken != null)) {
          try {
            await _authService.switchTo(ap);
          } catch (_) {}
        }
        _status = _authService.sessionToken != null
            ? AuthStatus.authenticated
            : AuthStatus.idle;
      } else {
        _status = AuthStatus.idle;
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.idle;
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Login
  // ═══════════════════════════════════════════════════════════════════

  /// Log in to a manager, creating or re-authenticating a profile.
  Future<void> login(String url, String token, {String? name}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    debugPrint('[AuthProvider] login: $url');
    try {
      await _authService.login(url, token, name: name);
      _status = _authService.sessionToken != null
          ? AuthStatus.authenticated
          : AuthStatus.error;
      debugPrint('[AuthProvider] login OK, agents: ${_authService.agents.length}');
    } catch (e) {
      debugPrint('[AuthProvider] login FAILED: $e');
      _error = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Profile management
  // ═══════════════════════════════════════════════════════════════════

  /// Switch active profile.
  Future<void> switchTo(String id) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _authService.switchTo(id);
      _status = _authService.sessionToken != null
          ? AuthStatus.authenticated
          : AuthStatus.idle;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  /// Remove a manager profile entirely.
  Future<void> removeManager(String id) async {
    await _authService.removeManager(id);
    _status = _authService.sessionToken != null
        ? AuthStatus.authenticated
        : AuthStatus.idle;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Logout
  // ═══════════════════════════════════════════════════════════════════

  /// Log out of the active profile (keeps the profile for later).
  Future<void> logout() async {
    await _authService.logoutActiveSession();
    _status = AuthStatus.idle;
    _error = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Agents
  // ═══════════════════════════════════════════════════════════════════

  Future<List<AgentInfo>> refreshAgents() async {
    final agents = await _authService.refreshAgents();
    notifyListeners();
    return agents;
  }

  Future<ServerRef?> getServerRef(String agentId) =>
      _authService.getServerRef(agentId);
  Future<void> setServerToken(String agentId, String token) =>
      _authService.setServerToken(agentId, token);
  Future<void> forgetServer(String agentId) =>
      _authService.forgetServer(agentId);
  Future<void> ensureFreshSession() =>
      _authService.ensureFreshSession();
}
