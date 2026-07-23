import 'package:flutter/foundation.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/services/auth_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.idle;
  String? _baseUrl;
  String? _sessionToken;
  String? _error;
  List<AgentInfo> _agents = [];

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  AuthStatus get status => _status;
  String? get baseUrl => _baseUrl;
  String? get sessionToken => _sessionToken;
  String? get error => _error;
  List<AgentInfo> get agents => _agents;
  AuthService get authService => _authService;

  /// Manager-level [ServerRef] for proxied API calls.
  /// Returns `null` when not authenticated.
  ServerRef? get managerRef {
    if (_baseUrl == null || _sessionToken == null) return null;
    return ServerRef(
      id: '__manager__',
      name: 'manager',
      baseUrl: _baseUrl!,
      token: _sessionToken!,
    );
  }

  Future<void> boot() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final result = await _authService.boot();
      if (result.baseUrl != null && result.agents != null) {
        _baseUrl = result.baseUrl;
        _sessionToken = result.sessionToken;
        _agents = result.agents!;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.idle;
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.idle;
    }
    notifyListeners();
  }

  Future<void> login(String url, String token) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    debugPrint('[AuthProvider] login: $url');
    try {
      final result = await _authService.login(url, token);
      _baseUrl = result.baseUrl;
      _sessionToken = result.sessionToken;
      _agents = _authService.agents;
      _status = AuthStatus.authenticated;
      debugPrint('[AuthProvider] login OK, agents: ${_agents.length}');
    } catch (e) {
      debugPrint('[AuthProvider] login FAILED: $e');
      _error = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _status = AuthStatus.idle;
    _baseUrl = null;
    _sessionToken = null;
    _agents = [];
    _error = null;
    notifyListeners();
  }

  Future<List<AgentInfo>> refreshAgents() async {
    final agents = await _authService.refreshAgents();
    _agents = agents;
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
