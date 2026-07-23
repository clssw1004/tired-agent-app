import 'package:flutter/foundation.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/services/auth_service.dart';

class ServerProvider extends ChangeNotifier {
  final AuthService _authService;

  ServerProvider(this._authService);

  Future<void> addServer(String name, String baseUrl, String token) async {
    final ref = ServerRef(
      id: '__manager__',
      name: name,
      baseUrl: baseUrl,
      token: token,
    );
    final result = await _authService.transport.addAgent(
      ref,
      name: name,
      baseUrl: baseUrl,
      token: token,
    );
    final agentId = result['id'] as String;
    await _authService.setServerToken(agentId, token);
    await _authService.refreshAgents();
    notifyListeners();
  }

  Future<ServerRef?> getServerRef(String agentId) =>
      _authService.getServerRef(agentId);

  Future<void> forgetServer(String agentId) async {
    await _authService.forgetServer(agentId);
    notifyListeners();
  }
}
