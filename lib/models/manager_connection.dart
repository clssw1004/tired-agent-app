import 'package:flutter/foundation.dart';

import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/protocol/types.dart';

/// Per-connection status for a manager profile.
enum ConnectionStatus {
  /// Profile exists but no transport created.
  idle,

  /// Transport created, login/refresh in progress.
  connecting,

  /// Login succeeded, transport ready.
  connected,

  /// Last login/refresh failed.
  error,
}

/// Runtime state for one connected manager profile.
///
/// Each [ManagerConnection] owns its own [HttpSseTransport] with an
/// independent token provider, HTTP client, and SSE lifecycle.
///
/// Call [connect] after construction to initialize the session, or
/// [disconnect] to tear down while keeping the [profile] for later reuse.
class ManagerConnection extends ChangeNotifier {
  ManagerConnection({required this.profile, HttpSseTransport? transport})
    : _transport = transport;

  /// The underlying profile (persisted).
  final ManagerProfile profile;

  /// Agents discovered for this manager.
  List<AgentInfo> agents = [];

  /// Current connection state.
  ConnectionStatus status = ConnectionStatus.idle;

  /// Last error message, if [status] is [ConnectionStatus.error].
  String? error;

  /// Guards against concurrent [connect] calls — keeps the in-flight
  /// future so a second caller waits instead of racing.
  Future<void>? _connectFuture;

  /// Lazily-created transport.  The first call to [transportFor] or
  /// [connect] triggers the actual HTTP client construction.
  HttpSseTransport? _transport;

  /// The per-connection [HttpSseTransport].
  ///
  /// Created on first access with a [tokenProvider] that simply returns
  /// the current session token.  Token refresh is handled explicitly by
  /// [connect] / [ensureFreshSession] — the Dio 401 interceptor only
  /// retries with whatever token is available (no recursive refresh).
  HttpSseTransport get transport {
    _transport ??= HttpSseTransport(
      tokenProvider: () async => profile.sessionToken,
    );
    return _transport!;
  }

  /// Session token that auto-refreshes if close to expiry.
  ///
  /// Returns the current [sessionToken] immediately if still fresh, or
  /// performs a silent refresh via the stored [refreshToken] first.
  Future<String?> get freshToken async {
    if (!isSessionFresh && profile.refreshToken != null) {
      await ensureFreshSession();
    }
    return profile.sessionToken;
  }

  /// Build a [ServerRef] for the manager-level proxy API.
  ServerRef get managerRef => _managerRefWith(profile.sessionToken ?? '');

  ServerRef _managerRefWith(String token) {
    return ServerRef(
      id: '__manager__',
      name: profile.name,
      baseUrl: profile.baseUrl,
      token: token,
    );
  }

  /// Whether the session token exists and is not close to expiry.
  bool get isSessionFresh {
    const windowMs = 5 * 60 * 1000;
    final remaining =
        profile.sessionExpiresAtMs - DateTime.now().millisecondsSinceEpoch;
    return profile.sessionToken != null && remaining > windowMs;
  }

  /// Connect: login with [apiToken] or refresh from stored token.
  ///
  /// On success, fetches the agent list and sets [status] to [connected].
  /// On failure, sets [status] to [error] with a descriptive message.
  ///
  /// **Guards against concurrent calls:** if a connection is already in
  /// progress, subsequent calls wait for it to complete rather than
  /// starting a duplicate (which could race on the single-use refresh
  /// token).
  Future<void> connect({String? apiToken}) async {
    // Prevent concurrent connections — the single-use sliding refresh
    // token would fail if two refreshSession calls race.
    if (_connectFuture != null) {
      debugPrint('[ManagerConnection] connect already in progress, waiting…');
      await _connectFuture;
      return;
    }

    _connectFuture = _doConnect(apiToken: apiToken);
    try {
      await _connectFuture!;
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> _doConnect({String? apiToken}) async {
    status = ConnectionStatus.connecting;
    error = null;
    notifyListeners();
    debugPrint(
      '[ManagerConnection] connect(${profile.name}) apiToken=${apiToken != null}',
    );

    try {
      if (apiToken != null) {
        // Fresh login.
        debugPrint('[ManagerConnection] logging in to ${profile.baseUrl}');
        final ref = _managerRefWith(apiToken);
        final result = await transport.login(ref, apiToken);
        debugPrint(
          '[ManagerConnection] login OK, session=${result.sessionToken.substring(0, 8)}…',
        );
        profile.refreshToken = result.refreshToken;
        profile.sessionToken = result.sessionToken;
        profile.sessionExpiresAtMs =
            DateTime.now().millisecondsSinceEpoch +
            result.sessionExpiresIn * 1000;
        profile.lastUsedMs = DateTime.now().millisecondsSinceEpoch;
      } else if (profile.refreshToken != null) {
        // Session still valid → skip refresh.
        if (isSessionFresh) {
          debugPrint('[ManagerConnection] session fresh, skipping refresh');
        } else {
          // Restore via refresh token.
          final ref = _managerRefWith(profile.refreshToken!);
          final result = await transport.refreshSession(
            ref,
            profile.refreshToken!,
          );
          profile.sessionToken = result.sessionToken;
          profile.sessionExpiresAtMs =
              DateTime.now().millisecondsSinceEpoch +
              result.sessionExpiresIn * 1000;
          profile.refreshToken = result.refreshToken;
        }
      } else {
        throw Exception('No credentials available for ${profile.name}');
      }

      // Fetch agents.
      final mgrRef = _managerRefWith(profile.sessionToken!);
      agents = await transport.listAgents(mgrRef);

      status = ConnectionStatus.connected;
      debugPrint('[ManagerConnection] connected, agents=${agents.length}');
    } catch (e) {
      final msg = e.toString();
      debugPrint('[ManagerConnection] connect failed: $msg');
      // Expired or invalid refresh token → normal idle state.
      if (msg.contains('invalid_refresh') || msg.contains('token expired')) {
        profile.refreshToken = null;
        profile.sessionToken = null;
        profile.sessionExpiresAtMs = 0;
        error = msg;
        status = ConnectionStatus.idle;
      } else {
        // Network / transient error → keep tokens, show idle.
        // Next boot (or manual retry) will try again without re-auth.
        error = msg;
        status = ConnectionStatus.idle;
      }
    }
    notifyListeners();
  }

  /// Disconnect: clear session data while keeping the profile and transport.
  Future<void> disconnect() async {
    profile.sessionToken = null;
    profile.sessionExpiresAtMs = 0;
    agents = [];
    status = ConnectionStatus.idle;
    error = null;
    notifyListeners();
  }

  /// Ensure the session token is fresh; refresh if needed.
  Future<void> ensureFreshSession() async {
    if (isSessionFresh) return;
    if (profile.refreshToken == null) {
      throw Exception('Session expired for ${profile.name}');
    }

    final ref = _managerRefWith(profile.refreshToken!);
    final result = await transport.refreshSession(ref, profile.refreshToken!);

    profile.sessionToken = result.sessionToken;
    profile.sessionExpiresAtMs =
        DateTime.now().millisecondsSinceEpoch + result.sessionExpiresIn * 1000;
    profile.refreshToken = result.refreshToken;
  }

  @override
  void dispose() {
    _transport?.dispose();
    _transport = null;
    super.dispose();
  }
}
