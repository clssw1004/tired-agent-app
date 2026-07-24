import 'package:tired_agent_app/protocol/types.dart';

/// A saved manager connection profile.
///
/// Only [id], [name], [baseUrl], and [lastUsedMs] are persisted to
/// SharedPreferences.  The [refreshToken] is stored separately in
/// FlutterSecureStorage (keyed by profile id).  Session-level fields
/// ([sessionToken], [sessionExpiresAtMs], [agents]) are in-memory only
/// and re-populated on each login or boot restore.
class ManagerProfile {
  final String id;
  String name;
  String baseUrl;
  int lastUsedMs;

  // ── Persisted securely (FlutterSecureStorage, keyed by profile id) ─
  String? refreshToken;

  // ── In-memory only ─────────────────────────────────────────────────
  String? sessionToken;
  int sessionExpiresAtMs = 0;
  List<AgentInfo> agents = [];

  ManagerProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    int? lastUsedMs,
    this.refreshToken,
    this.sessionToken,
    this.sessionExpiresAtMs = 0,
    List<AgentInfo>? agents,
  }) : lastUsedMs = lastUsedMs ?? DateTime.now().millisecondsSinceEpoch;

  /// Portion persisted to SharedPreferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'lastUsedMs': lastUsedMs,
      };

  factory ManagerProfile.fromJson(Map<String, dynamic> json) => ManagerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        baseUrl: json['baseUrl'] as String,
        lastUsedMs: json['lastUsedMs'] as int?,
      );

  ManagerProfile copyWith({
    String? id,
    String? name,
    String? baseUrl,
    int? lastUsedMs,
    String? refreshToken,
    String? sessionToken,
    int? sessionExpiresAtMs,
    List<AgentInfo>? agents,
  }) =>
      ManagerProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        lastUsedMs: lastUsedMs ?? this.lastUsedMs,
        refreshToken: refreshToken ?? this.refreshToken,
        sessionToken: sessionToken ?? this.sessionToken,
        sessionExpiresAtMs: sessionExpiresAtMs ?? this.sessionExpiresAtMs,
        agents: agents ?? this.agents,
      );
}
