import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/protocol/types.dart';

void main() {
  group('Session.claudeSessionId', () {
    test('fromJson parses the top-level claudeSessionId field', () {
      final session = Session.fromJson({
        'id': 's1',
        'cmd': 'claude',
        'args': <String>[],
        'status': 'exited',
        'createdAt': 1000,
        'byteOffset': 0,
        'cols': 80,
        'rows': 24,
        'claudeSessionId': '11111111-2222-3333-4444-555555555555',
        'extra': null,
      });

      expect(session.claudeSessionId, '11111111-2222-3333-4444-555555555555');
      expect(session.extra, isNull);
    });

    test('fromJson tolerates a missing claudeSessionId field', () {
      final session = Session.fromJson({
        'id': 's1',
        'cmd': 'bash',
        'args': <String>[],
        'status': 'running',
        'createdAt': 1000,
        'byteOffset': 0,
        'cols': 80,
        'rows': 24,
      });

      expect(session.claudeSessionId, isNull);
    });

    test('toJson round-trips the claudeSessionId field', () {
      final session = Session.fromJson({
        'id': 's1',
        'cmd': 'claude',
        'args': <String>[],
        'status': 'exited',
        'createdAt': 1000,
        'byteOffset': 0,
        'cols': 80,
        'rows': 24,
        'claudeSessionId': '11111111-2222-3333-4444-555555555555',
        'extra': null,
      });

      final json = session.toJson();
      expect(json['claudeSessionId'], '11111111-2222-3333-4444-555555555555');
    });

    test('toJson omits claudeSessionId when null', () {
      final session = Session.fromJson({
        'id': 's1',
        'cmd': 'bash',
        'args': <String>[],
        'status': 'running',
        'createdAt': 1000,
        'byteOffset': 0,
        'cols': 80,
        'rows': 24,
      });

      expect(session.toJson().containsKey('claudeSessionId'), isFalse);
    });
  });
}
