import 'types.dart';

// ─── Exception ──────────────────────────────────────────────────────────

/// Exception thrown by transport implementations on HTTP/network errors.
class TransportException implements Exception {
  final String message;
  final int? statusCode;

  TransportException(this.message, {this.statusCode});

  @override
  String toString() => 'TransportException($statusCode): $message';
}

// ─── Subscription ───────────────────────────────────────────────────────

/// Opaque handle that the caller uses to tear down an SSE subscription.
class Subscription {
  final void Function() close;
  Subscription({required this.close});
}

// ─── SubscribeHandlers ──────────────────────────────────────────────────

/// Callbacks dispatched by [Transport.subscribe] as SSE events arrive.
class SubscribeHandlers {
  final void Function(OutputChunk chunk) onChunk;
  final void Function(Session session) onState;
  final void Function(Object error) onError;

  SubscribeHandlers({
    required this.onChunk,
    required this.onState,
    required this.onError,
  });
}

// ─── Transport abstract interface ───────────────────────────────────────

abstract class Transport {
  /// List all sessions on the server referenced by [ref].
  Future<List<Session>> listSessions(ServerRef ref, {String? agentId});

  /// Create a new PTY session.
  Future<Session> createSession(ServerRef ref, SessionSpec spec,
      {String? agentId});

  /// List directory contents.
  Future<DirectoryListing> listDirectories(ServerRef ref,
      {String? path, String? agentId});

  /// Get directory shortcuts (favorites + recent).
  Future<DirectoryShortcuts> getDirectoryShortcuts(ServerRef ref,
      {String? agentId});

  /// Add a directory to favorites.
  Future<DirectoryFavorite> addDirectoryFavorite(ServerRef ref,
      {required String path, String? name, String? agentId});

  /// Remove a directory from favorites by its id.
  Future<void> removeDirectoryFavorite(ServerRef ref, String id,
      {String? agentId});

  /// Get a single session by id.
  Future<Session> getSession(ServerRef ref, String id, {String? agentId});

  /// Kill (send SIGTERM/SIGKILL to) a session.
  Future<void> killSession(ServerRef ref, String id, {String? agentId});

  /// Delete a session permanently.
  Future<void> deleteSession(ServerRef ref, String id, {String? agentId});

  /// Prune stale sessions, returning a summary map.
  Future<Map<String, dynamic>> pruneSessions(ServerRef ref,
      {int olderThanHours = 24, String? agentId});

  /// Resize the PTY of a session.
  Future<void> resizeSession(ServerRef ref, String id, int cols, int rows,
      {String? agentId});

  /// Fetch buffered output for a session.
  Future<FetchOutputResult> fetchOutput(ServerRef ref, String id,
      {int fromOffset = 0, int? limit, String? agentId, int? tail});

  /// Subscribe to real-time output and state changes via SSE.
  Subscription subscribe(ServerRef ref, String id,
      SubscribeHandlers handlers, {String? agentId, int fromOffset = 0});

  /// Send raw bytes (base64-encoded) as input to a session.
  Future<void> sendInput(ServerRef ref, String id, List<int> data,
      {String? agentId});

  /// List registered agent backends on the manager.
  Future<List<AgentInfo>> listAgents(ServerRef ref);

  /// Register a new agent backend on the manager.
  Future<Map<String, dynamic>> addAgent(ServerRef ref,
      {required String name,
      required String baseUrl,
      required String token});

  /// Unregister an agent backend.
  Future<void> deleteAgent(ServerRef ref, String agentId);

  /// Authenticate against the manager with a bearer token.
  Future<LoginResponse> login(ServerRef ref, String token);

  /// Refresh an expiring session.
  Future<LoginResponse> refreshSession(ServerRef ref, String refreshToken);

  /// Check whether the current session is still valid.
  Future<bool> checkSession(ServerRef ref);
}
