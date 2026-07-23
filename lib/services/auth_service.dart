import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/services/storage_service.dart';

/// Manages the authentication lifecycle: login, session refresh, logout,
/// and agent list caching.
class AuthService {
  final Transport transport;
  final StorageService storage;
  String? _sessionToken;
  String? _baseUrl;
  String? _refreshToken;
  int _sessionExpiresAtMs = 0;
  List<AgentInfo> _agents = [];
  Future<void>? _inflightRefresh;

  AuthService({Transport? transport, StorageService? storage})
      : transport = transport ?? HttpSseTransport(),
        storage = storage ?? StorageService();

  // ─── Getters ──────────────────────────────────────────────────────────

  String? get sessionToken => _sessionToken;
  String? get baseUrl => _baseUrl;
  String? get refreshToken => _refreshToken;
  List<AgentInfo> get agents => _agents;

  // ─── Session lifecycle ────────────────────────────────────────────────

  /// Ensure the session token is fresh.  Auto-refreshes when fewer than
  /// 5 minutes remain before expiry.
  Future<void> ensureFreshSession() async {
    const refreshWindowMs = 5 * 60 * 1000;
    final remaining =
        _sessionExpiresAtMs - DateTime.now().millisecondsSinceEpoch;
    if (_sessionToken != null && remaining > refreshWindowMs) return;
    if (_refreshToken == null || _baseUrl == null) {
      throw Exception('unauthorized');
    }

    _inflightRefresh ??= _doRefresh().whenComplete(
        () => _inflightRefresh = null);
    await _inflightRefresh;
  }

  Future<void> _doRefresh() async {
    final ref = ServerRef(
        id: '__manager__',
        name: 'manager',
        baseUrl: _baseUrl!,
        token: _refreshToken!);
    final result = await transport.refreshSession(ref, _refreshToken!);
    _sessionToken = result.sessionToken;
    _sessionExpiresAtMs =
        DateTime.now().millisecondsSinceEpoch + result.sessionExpiresIn * 1000;
    _refreshToken = result.refreshToken;
    await storage.saveRefreshToken(result.refreshToken);
  }

  // ─── Login ────────────────────────────────────────────────────────────

  /// Log in to the manager at [url] using [token] (API key).
  Future<({String baseUrl, String sessionToken, List<AgentInfo> agents})> login(
    String url,
    String token,
  ) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    final ref = ServerRef(
        id: '__manager__',
        name: 'manager',
        baseUrl: normalized,
        token: token);
    final result = await transport.login(ref, token);

    _baseUrl = normalized;
    _sessionToken = result.sessionToken;
    _refreshToken = result.refreshToken;
    _sessionExpiresAtMs =
        DateTime.now().millisecondsSinceEpoch + result.sessionExpiresIn * 1000;

    await storage.saveManagerConfig({'baseUrl': normalized});
    await storage.saveRefreshToken(result.refreshToken);

    // Fetch agent list right after login.
    final mgrRef = ServerRef(
        id: '__manager__',
        name: 'manager',
        baseUrl: normalized,
        token: result.sessionToken);
    _agents = await transport.listAgents(mgrRef);

    return (
      baseUrl: normalized,
      sessionToken: result.sessionToken,
      agents: _agents.toList(),
    );
  }

  // ─── Boot (auto-restore from persisted refresh token) ─────────────────

  /// Try to restore a previous session from stored credentials.
  /// Returns `null` fields when no saved session exists or refresh fails.
  Future<({String? baseUrl, String? sessionToken, List<AgentInfo>? agents})>
      boot() async {
    final cfg = await storage.loadManagerConfig();
    final rt = await storage.loadRefreshToken();
    if (cfg == null || rt == null || cfg['baseUrl'] == null) {
      return (baseUrl: null, sessionToken: null, agents: null);
    }

    _baseUrl = cfg['baseUrl']!;
    _refreshToken = rt;

    try {
      await ensureFreshSession();
      if (_sessionToken == null) throw Exception('session not established');

      final mgrRef = ServerRef(
          id: '__manager__',
          name: 'manager',
          baseUrl: _baseUrl!,
          token: _sessionToken!);
      _agents = await transport.listAgents(mgrRef);

      return (
        baseUrl: _baseUrl,
        sessionToken: _sessionToken,
        agents: _agents.toList(),
      );
    } catch (_) {
      // Refresh failed – clear everything.
      await storage.clearRefreshToken();
      await storage.clearManagerConfig();
      _refreshToken = null;
      _sessionToken = null;
      return (baseUrl: null, sessionToken: null, agents: null);
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────

  /// Clear all in-memory state and persisted credentials.
  Future<void> logout() async {
    _baseUrl = null;
    _sessionToken = null;
    _refreshToken = null;
    _sessionExpiresAtMs = 0;
    _agents = [];
    await storage.clearRefreshToken();
    await storage.clearManagerConfig();
  }

  // ─── Agent list ───────────────────────────────────────────────────────

  /// Fetch a fresh agent list from the manager.
  Future<List<AgentInfo>> refreshAgents() async {
    if (_sessionToken == null || _baseUrl == null) return [];
    await ensureFreshSession();
    final mgrRef = ServerRef(
        id: '__manager__',
        name: 'manager',
        baseUrl: _baseUrl!,
        token: _sessionToken!);
    _agents = await transport.listAgents(mgrRef);
    return List.from(_agents);
  }

  /// Build a [ServerRef] for the given [agentId] using the stored token.
  Future<ServerRef?> getServerRef(String agentId) async {
    final agent = _agents.where((a) => a.id == agentId).firstOrNull;
    if (agent == null) return null;
    final token = await storage.getCredential('server:$agentId:token');
    if (token == null) return null;
    return ServerRef(
        id: agentId, name: agent.name, baseUrl: agent.baseUrl, token: token);
  }

  /// Persist a server (agent) token so [getServerRef] can retrieve it later.
  Future<void> setServerToken(String agentId, String token) =>
      storage.saveCredential('server:$agentId:token', token);

  /// Remove a persisted server token.
  Future<void> forgetServer(String agentId) =>
      storage.deleteCredential('server:$agentId:token');
}
