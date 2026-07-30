import 'package:flutter/foundation.dart';

import 'package:tired_agent_app/models/pinned_session.dart';
import 'package:tired_agent_app/services/pinned_session_service.dart';

/// Reactive wrapper over [PinnedSessionService].
///
/// Call [load] once at boot. Every pin/unpin notifies listeners so pinned
/// session screens and pin buttons stay in sync.
class PinnedSessionProvider extends ChangeNotifier {
  final PinnedSessionService _service;
  bool _loaded = false;

  PinnedSessionProvider({PinnedSessionService? service})
    : _service = service ?? PinnedSessionService();

  PinnedSessionService get service => _service;

  /// Load from storage (call once at boot).
  Future<void> load() async {
    if (_loaded) return;
    await _service.load();
    _loaded = true;
    notifyListeners();
  }

  List<PinnedSession> getAll() => _service.getAll();

  Map<String, List<PinnedSession>> getGroupedByProfile() =>
      _service.getGroupedByProfile();

  bool isPinned({
    required String profileId,
    required String agentId,
    required String sessionId,
  }) => _service.isPinned(
    profileId: profileId,
    agentId: agentId,
    sessionId: sessionId,
  );

  Future<PinnedSession> pin({
    required String profileId,
    required String profileName,
    required String agentId,
    required String agentName,
    required String sessionId,
    required String sessionLabel,
    String sessionType = 'pty',
  }) async {
    final result = await _service.pin(
      profileId: profileId,
      profileName: profileName,
      agentId: agentId,
      agentName: agentName,
      sessionId: sessionId,
      sessionLabel: sessionLabel,
      sessionType: sessionType,
    );
    notifyListeners();
    return result;
  }

  Future<void> unpin(String pinId) async {
    await _service.unpin(pinId);
    notifyListeners();
  }

  Future<void> unpinBySession({
    required String profileId,
    required String agentId,
    required String sessionId,
  }) async {
    await _service.unpinBySession(
      profileId: profileId,
      agentId: agentId,
      sessionId: sessionId,
    );
    notifyListeners();
  }
}
