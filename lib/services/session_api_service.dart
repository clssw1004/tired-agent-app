import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';

/// Unified API service for session CRUD and SSE operations.
///
/// Wraps a [ManagerConnection] + agent ID, handling [ServerRef] construction
/// and token refresh internally. Eliminates boilerplate spread across screens.
class SessionApiService {
  final ManagerConnection conn;
  final String agentId;

  SessionApiService({required this.conn, required this.agentId});

  /// Ensure the session token is fresh and return a ready [ServerRef].
  Future<ServerRef> _ensureRef() async {
    await conn.ensureFreshSession();
    return conn.managerRef;
  }

  // ─── Session lifecycle ─────────────────────────────────────────────────

  /// List all sessions.
  Future<List<Session>> listSessions() async {
    final ref = await _ensureRef();
    return conn.transport.listSessions(ref, agentId: agentId);
  }

  /// Create a new session.
  Future<Session> createSession(SessionSpec spec) async {
    final ref = await _ensureRef();
    return conn.transport.createSession(ref, spec, agentId: agentId);
  }

  /// Get a single session by id.
  Future<Session> getSession(String sessionId) async {
    final ref = await _ensureRef();
    return conn.transport.getSession(ref, sessionId, agentId: agentId);
  }

  /// Kill a running session.
  Future<void> killSession(String sessionId) async {
    final ref = await _ensureRef();
    await conn.transport.killSession(ref, sessionId, agentId: agentId);
  }

  /// Delete an exited session.
  Future<void> deleteSession(String sessionId) async {
    final ref = await _ensureRef();
    await conn.transport.deleteSession(ref, sessionId, agentId: agentId);
  }

  /// Prune stale (exited, old) sessions.
  Future<Map<String, dynamic>> pruneSessions() async {
    final ref = await _ensureRef();
    return conn.transport.pruneSessions(ref, agentId: agentId);
  }

  /// Resize the PTY for a session.
  Future<void> resizeSession(
    String sessionId, {
    required int cols,
    required int rows,
  }) async {
    final ref = await _ensureRef();
    await conn.transport.resizeSession(
      ref,
      sessionId,
      cols,
      rows,
      agentId: agentId,
    );
  }

  // ─── Input / Output ────────────────────────────────────────────────────

  /// Fetch buffered output for a session.
  Future<FetchOutputResult> fetchOutput(
    String sessionId, {
    int fromOffset = 0,
    int? limit,
    int? tail,
  }) async {
    final ref = await _ensureRef();
    return conn.transport.fetchOutput(
      ref,
      sessionId,
      fromOffset: fromOffset,
      limit: limit,
      agentId: agentId,
      tail: tail,
    );
  }

  /// Send raw bytes (base64-encoded) as input to a session.
  Future<void> sendInput(String sessionId, List<int> data) async {
    final ref = await _ensureRef();
    await conn.transport.sendInput(ref, sessionId, data, agentId: agentId);
  }

  // ─── Directory ─────────────────────────────────────────────────────────

  /// List directory contents.
  Future<DirectoryListing> listDirectories({String? path}) async {
    final ref = await _ensureRef();
    return conn.transport.listDirectories(ref, path: path, agentId: agentId);
  }

  /// Get directory shortcuts (favorites + recent).
  Future<DirectoryShortcuts> getDirectoryShortcuts() async {
    final ref = await _ensureRef();
    return conn.transport.getDirectoryShortcuts(ref, agentId: agentId);
  }

  /// Add a directory to favorites.
  Future<DirectoryFavorite> addDirectoryFavorite({
    required String path,
    String? name,
  }) async {
    final ref = await _ensureRef();
    return conn.transport.addDirectoryFavorite(
      ref,
      path: path,
      name: name,
      agentId: agentId,
    );
  }

  /// Remove a directory from favorites by its id.
  Future<void> removeDirectoryFavorite(String id) async {
    final ref = await _ensureRef();
    await conn.transport.removeDirectoryFavorite(ref, id, agentId: agentId);
  }
}
