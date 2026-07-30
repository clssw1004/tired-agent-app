import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:tired_agent_app/models/pinned_session.dart';

/// Manages pinned sessions — persisted to [SharedPreferences] as a JSON list.
class PinnedSessionService {
  static const _kKey = 'pinned_sessions';
  List<PinnedSession> _cache = [];

  /// Load pinned sessions from storage.
  Future<List<PinnedSession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) {
      _cache = [];
      return [];
    }
    final list = json.decode(raw) as List<dynamic>;
    _cache = list
        .map((e) => PinnedSession.fromJson(e as Map<String, dynamic>))
        .toList();
    return List.unmodifiable(_cache);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      json.encode(_cache.map((p) => p.toJson()).toList()),
    );
  }

  /// Pin a session. If one with the same [uniqueKey] already exists, update
  /// its label. Returns the pinned session.
  Future<PinnedSession> pin({
    required String profileId,
    required String profileName,
    required String agentId,
    required String agentName,
    required String sessionId,
    required String sessionLabel,
    String sessionType = 'pty',
  }) async {
    // De-duplicate: remove existing pin for same (profile, agent, session).
    _cache.removeWhere(
      (p) =>
          p.profileId == profileId &&
          p.agentId == agentId &&
          p.sessionId == sessionId,
    );

    final pinned = PinnedSession(
      id: const Uuid().v4(),
      profileId: profileId,
      profileName: profileName,
      agentId: agentId,
      agentName: agentName,
      sessionId: sessionId,
      sessionLabel: sessionLabel,
      sessionType: sessionType,
      pinnedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _cache.insert(0, pinned); // newest first
    await _persist();
    return pinned;
  }

  /// Unpin a session by its pin id.
  Future<void> unpin(String pinId) async {
    _cache.removeWhere((p) => p.id == pinId);
    await _persist();
  }

  /// Unpin by session key (profileId + agentId + sessionId).
  Future<void> unpinBySession({
    required String profileId,
    required String agentId,
    required String sessionId,
  }) async {
    _cache.removeWhere(
      (p) =>
          p.profileId == profileId &&
          p.agentId == agentId &&
          p.sessionId == sessionId,
    );
    await _persist();
  }

  /// Check if a session is pinned.
  bool isPinned({
    required String profileId,
    required String agentId,
    required String sessionId,
  }) {
    return _cache.any(
      (p) =>
          p.profileId == profileId &&
          p.agentId == agentId &&
          p.sessionId == sessionId,
    );
  }

  /// Get all pinned sessions.
  List<PinnedSession> getAll() => List.unmodifiable(_cache);

  /// Get pinned sessions grouped by profile name.
  Map<String, List<PinnedSession>> getGroupedByProfile() {
    final map = <String, List<PinnedSession>>{};
    for (final p in _cache) {
      final key = p.profileName.isNotEmpty ? p.profileName : p.profileId;
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }
}
