import 'package:flutter/foundation.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/services/auth_service.dart';

/// Provider for adding/managing agent backends on a specific manager.
///
/// Obsolete in the multi-connection model — use
/// [AuthService.connectionFor] directly instead.  Kept for backward
/// compatibility during the migration.
@deprecated
class ServerProvider extends ChangeNotifier {
  final AuthService _authService;

  ServerProvider(this._authService);

  /// Add an agent backend to the manager identified by [profileId].
  Future<void> addServer(
    String profileId,
    String name,
    String baseUrl,
    String token,
  ) async {
    final conn = _authService.connectionFor(profileId);
    if (conn == null) throw Exception('Manager not connected: $profileId');
    await conn.ensureFreshSession();

    final ref = ServerRef(
      id: '__manager__',
      name: conn.profile.name,
      baseUrl: conn.profile.baseUrl,
      token: conn.profile.sessionToken!,
    );
    final result = await conn.transport.addAgent(
      ref,
      name: name,
      baseUrl: baseUrl,
      token: token,
    );
    final agentId = result['id'] as String;
    await _authService.setServerToken(profileId, agentId, token);
    notifyListeners();
  }

  Future<ServerRef?> getServerRef(String profileId, String agentId) =>
      _authService.getServerRef(profileId, agentId);

  Future<void> forgetServer(String profileId, String agentId) async {
    await _authService.forgetServer(profileId, agentId);
    notifyListeners();
  }
}
