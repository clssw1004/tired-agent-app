import 'package:uuid/uuid.dart';

import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/services/storage_service.dart';

/// Manages the authentication lifecycle across multiple manager profiles:
/// login, session refresh, logout, profile CRUD, and agent list caching.
class AuthService {
  late final Transport transport;
  final StorageService storage;
  List<ManagerProfile> _profiles = [];
  ManagerProfile? _activeProfile;
  Future<void>? _inflightRefresh;

  AuthService({Transport? transport, StorageService? storage})
      : storage = storage ?? StorageService() {
    this.transport = transport ??
        HttpSseTransport(
          tokenProvider: () async {
            await ensureFreshSession();
            return _activeProfile?.sessionToken;
          },
        );
  }

  // ─── Getters (delegated to active profile) ──────────────────────────

  String? get sessionToken => _activeProfile?.sessionToken;
  String? get baseUrl => _activeProfile?.baseUrl;
  List<AgentInfo> get agents => _activeProfile?.agents ?? [];
  List<ManagerProfile> get profiles => List.unmodifiable(_profiles);
  String? get activeProfileId => _activeProfile?.id;

  /// The [ServerRef] for the active manager (for proxied API calls).
  /// Returns `null` when no active profile or no session token.
  ServerRef? get managerRef {
    final p = _activeProfile;
    if (p == null || p.sessionToken == null) return null;
    return ServerRef(
      id: '__manager__',
      name: p.name,
      baseUrl: p.baseUrl,
      token: p.sessionToken!,
    );
  }

  /// Whether any profile has a saved session / refresh token.
  bool get hasAnySession =>
      _profiles.any((p) => p.refreshToken != null || p.sessionToken != null);

  // ═══════════════════════════════════════════════════════════════════
  //  Profile CRUD
  // ═══════════════════════════════════════════════════════════════════

  /// Load persisted profiles from storage and restore the active one.
  Future<void> loadProfiles() async {
    _profiles = await storage.loadProfiles();
    final activeId = await storage.loadActiveProfileId();
    if (activeId != null) {
      _activeProfile = _profiles.where((p) => p.id == activeId).firstOrNull;
    }
    // Fall back to the first profile if the saved active was deleted.
    if (_activeProfile == null && _profiles.isNotEmpty) {
      _activeProfile = _profiles.first;
    }
  }

  /// Log in to a manager at [url] with [apiToken].
  ///
  /// If a profile with the same URL already exists, re-authenticate it.
  /// Otherwise, create and persist a new profile.
  Future<ManagerProfile> login(
    String url,
    String apiToken, {
    String? name,
  }) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');

    // Check for existing profile with the same URL.
    final existing = _profiles.where((p) => p.baseUrl == normalized).firstOrNull;
    if (existing != null) {
      _activeProfile = existing;
      return _doLogin(existing, apiToken);
    }

    // Create new profile.
    final profile = ManagerProfile(
      id: const Uuid().v4(),
      name: name ?? _suggestName(normalized),
      baseUrl: normalized,
    );
    _profiles = [profile, ..._profiles];
    _activeProfile = profile;
    return _doLogin(profile, apiToken);
  }

  /// Authenticate [profile] and populate session fields.
  Future<ManagerProfile> _doLogin(ManagerProfile profile, String apiToken) async {
    final ref = ServerRef(
        id: '__manager__',
        name: 'manager',
        baseUrl: profile.baseUrl,
        token: apiToken);
    final result = await transport.login(ref, apiToken);

    profile.refreshToken = result.refreshToken;
    profile.sessionToken = result.sessionToken;
    profile.sessionExpiresAtMs =
        DateTime.now().millisecondsSinceEpoch + result.sessionExpiresIn * 1000;
    profile.lastUsedMs = DateTime.now().millisecondsSinceEpoch;

    await storage.saveManagerRefreshToken(profile.id, result.refreshToken);

    // Fetch agents.
    final mgrRef = ServerRef(
        id: '__manager__',
        name: 'manager',
        baseUrl: profile.baseUrl,
        token: result.sessionToken);
    profile.agents = await transport.listAgents(mgrRef);

    await _persistProfiles();
    return profile;
  }

  /// Switch active profile by [id].
  Future<void> switchTo(String id) async {
    final profile = _profiles.where((p) => p.id == id).firstOrNull;
    if (profile == null) throw Exception('Profile not found: $id');

    profile.lastUsedMs = DateTime.now().millisecondsSinceEpoch;
    _activeProfile = profile;
    await _persistProfiles();

    // Try to restore session via refresh token (if not already active).
    if (profile.refreshToken != null && profile.sessionToken == null) {
      try {
        await _restoreSession(profile);
      } catch (_) {
        // Refresh failed — user re-authenticates on next action.
      }
    }
  }

  /// Remove a manager profile entirely.
  Future<void> removeManager(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await storage.clearManagerRefreshToken(id);
    if (_activeProfile?.id == id) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
      if (_activeProfile != null) {
        // Try to restore this fallback profile's session.
        try {
          if (_activeProfile!.refreshToken != null) {
            await _restoreSession(_activeProfile!);
          }
        } catch (_) {}
      }
    }
    await _persistProfiles();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Session lifecycle
  // ═══════════════════════════════════════════════════════════════════

  /// Ensure the active profile's session token is fresh.
  Future<void> ensureFreshSession() async {
    if (_activeProfile == null) throw Exception('No active manager');

    const refreshWindowMs = 5 * 60 * 1000;
    final remaining =
        _activeProfile!.sessionExpiresAtMs - DateTime.now().millisecondsSinceEpoch;
    if (_activeProfile!.sessionToken != null && remaining > refreshWindowMs) {
      return;
    }
    if (_activeProfile!.refreshToken == null) {
      throw Exception('unauthorized');
    }

    _inflightRefresh ??= _doRefresh().whenComplete(
        () => _inflightRefresh = null);
    await _inflightRefresh;
  }

  Future<void> _doRefresh() async {
    final p = _activeProfile;
    if (p == null || p.refreshToken == null) return;

    final ref = ServerRef(
        id: '__manager__',
        name: p.name,
        baseUrl: p.baseUrl,
        token: p.refreshToken!);
    final result = await transport.refreshSession(ref, p.refreshToken!);

    p.sessionToken = result.sessionToken;
    p.sessionExpiresAtMs =
        DateTime.now().millisecondsSinceEpoch + result.sessionExpiresIn * 1000;
    p.refreshToken = result.refreshToken;

    await storage.saveManagerRefreshToken(p.id, result.refreshToken);
  }

  Future<void> _restoreSession(ManagerProfile profile) async {
    if (profile.refreshToken == null) return;

    final ref = ServerRef(
        id: '__manager__',
        name: profile.name,
        baseUrl: profile.baseUrl,
        token: profile.refreshToken!);
    final result = await transport.refreshSession(ref, profile.refreshToken!);

    profile.sessionToken = result.sessionToken;
    profile.sessionExpiresAtMs =
        DateTime.now().millisecondsSinceEpoch + result.sessionExpiresIn * 1000;
    profile.refreshToken = result.refreshToken;

    await storage.saveManagerRefreshToken(profile.id, result.refreshToken);

    // Fetch agents.
    final mgrRef = ServerRef(
        id: '__manager__',
        name: profile.name,
        baseUrl: profile.baseUrl,
        token: result.sessionToken);
    profile.agents = await transport.listAgents(mgrRef);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Logout
  // ═══════════════════════════════════════════════════════════════════

  /// Log out of the active profile: clear session token (keeps profile).
  Future<void> logoutActiveSession() async {
    if (_activeProfile == null) return;
    _activeProfile!.sessionToken = null;
    _activeProfile!.sessionExpiresAtMs = 0;
    _activeProfile!.agents = [];
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Agent list
  // ═══════════════════════════════════════════════════════════════════

  /// Fetch a fresh agent list for the active profile.
  Future<List<AgentInfo>> refreshAgents() async {
    final p = _activeProfile;
    if (p == null || p.sessionToken == null) return [];
    await ensureFreshSession();

    final mgrRef = ServerRef(
        id: '__manager__',
        name: p.name,
        baseUrl: p.baseUrl,
        token: p.sessionToken!);
    p.agents = await transport.listAgents(mgrRef);
    return List.from(p.agents);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Server ref helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Build a [ServerRef] for the given [agentId] under the active profile.
  Future<ServerRef?> getServerRef(String agentId) async {
    final p = _activeProfile;
    if (p == null) return null;
    final agent = p.agents.where((a) => a.id == agentId).firstOrNull;
    if (agent == null) return null;
    final token = await storage.getCredential('server:${p.id}:$agentId:token');
    if (token == null) return null;
    return ServerRef(
        id: agentId, name: agent.name, baseUrl: agent.baseUrl, token: token);
  }

  Future<void> setServerToken(String agentId, String token) async {
    final p = _activeProfile;
    if (p == null) return;
    await storage.saveCredential('server:${p.id}:$agentId:token', token);
  }

  Future<void> forgetServer(String agentId) async {
    final p = _activeProfile;
    if (p == null) return;
    await storage.deleteCredential('server:${p.id}:$agentId:token');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Internals
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _persistProfiles() async {
    await storage.saveProfiles(_profiles);
    if (_activeProfile != null) {
      await storage.saveActiveProfileId(_activeProfile!.id);
    }
  }

  /// Suggest a human-friendly name from a URL.
  static String _suggestName(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url.length > 24 ? '${url.substring(0, 24)}…' : url;
    }
  }
}
