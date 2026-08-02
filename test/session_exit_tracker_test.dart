import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tired_agent_app/services/session_exit_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SessionExitTracker', () {
    const key = 'p:a:s';

    test('running→exited 判定为需通知', () async {
      final prefs = await SharedPreferences.getInstance();
      final tracker = SessionExitTracker(prefs)..load();
      tracker.trackRunning(key);
      expect(tracker.shouldNotify(key), isTrue);
    });

    test('直接观测到 exited（未先见 running）不通知', () async {
      final prefs = await SharedPreferences.getInstance();
      final tracker = SessionExitTracker(prefs)..load();
      expect(tracker.shouldNotify(key), isFalse);
    });

    test('同一会话只通知一次（去重）', () async {
      final prefs = await SharedPreferences.getInstance();
      final tracker = SessionExitTracker(prefs)..load();
      tracker.trackRunning(key);
      expect(tracker.shouldNotify(key), isTrue);
      await tracker.markNotified(key);

      // 再次 running→exited → 已通知，不再发。
      tracker.trackRunning(key);
      expect(tracker.shouldNotify(key), isFalse);
    });

    test('跨实例持久化去重（重启后不再通知）', () async {
      final prefs = await SharedPreferences.getInstance();
      final tracker = SessionExitTracker(prefs)..load();
      tracker.trackRunning(key);
      expect(tracker.shouldNotify(key), isTrue);
      await tracker.markNotified(key);

      // 模拟重启：同一 prefs 新建 tracker。
      final tracker2 = SessionExitTracker(prefs)..load();
      tracker2.trackRunning(key);
      expect(tracker2.shouldNotify(key), isFalse);
    });

    test('keyFor 拼接 profileId/agentId/sessionId', () {
      expect(
        SessionExitTracker.keyFor('prof', 'agent', 'sess'),
        'prof:agent:sess',
      );
    });
  });

  group('SessionRef payload', () {
    test('toPayload/fromPayload 往返一致', () {
      const ref = SessionRef(
        profileId: 'p1',
        agentId: 'a1',
        sessionId: 's1',
        label: 'label',
        cmd: 'bash',
      );
      final decoded = SessionRef.fromPayload(ref.toPayload());
      expect(decoded, isNotNull);
      expect(decoded!.profileId, 'p1');
      expect(decoded.agentId, 'a1');
      expect(decoded.sessionId, 's1');
    });

    test('非法 payload 返回 null', () {
      expect(SessionRef.fromPayload('not-json'), isNull);
      expect(SessionRef.fromPayload('{"x":1}'), isNull);
    });
  });
}
