/// A session pinned by the user for quick access in the Sessions tab.
class PinnedSession {
  final String id;
  final String profileId;
  final String profileName;
  final String agentId;
  final String agentName;
  final String sessionId;
  final String sessionLabel; // display label (from label ?? cmd)
  final String sessionType; // "pty" | "claude"
  final int pinnedAtMs;

  PinnedSession({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.agentId,
    required this.agentName,
    required this.sessionId,
    required this.sessionLabel,
    this.sessionType = 'pty',
    required this.pinnedAtMs,
  });

  factory PinnedSession.fromJson(Map<String, dynamic> json) {
    return PinnedSession(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      profileName: json['profileName'] as String? ?? '',
      agentId: json['agentId'] as String,
      agentName: json['agentName'] as String? ?? '',
      sessionId: json['sessionId'] as String,
      sessionLabel: json['sessionLabel'] as String? ?? '',
      sessionType: json['sessionType'] as String? ?? 'pty',
      pinnedAtMs: json['pinnedAtMs'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'profileName': profileName,
    'agentId': agentId,
    'agentName': agentName,
    'sessionId': sessionId,
    'sessionLabel': sessionLabel,
    'sessionType': sessionType,
    'pinnedAtMs': pinnedAtMs,
  };

  /// Unique key for de-duplication: same profile + agent + session = same pin.
  String get uniqueKey => '$profileId:$agentId:$sessionId';

  PinnedSession copyWith({String? sessionLabel}) => PinnedSession(
    id: id,
    profileId: profileId,
    profileName: profileName,
    agentId: agentId,
    agentName: agentName,
    sessionId: sessionId,
    sessionLabel: sessionLabel ?? this.sessionLabel,
    sessionType: sessionType,
    pinnedAtMs: pinnedAtMs,
  );
}
