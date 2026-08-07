import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/utils/time_ago.dart';

/// [timeAgo] 边界用例：秒/分/时/天档位与 0s/负数保护。
void main() {
  final now = DateTime.now().millisecondsSinceEpoch;

  String at(int msAgo) => timeAgo(now - msAgo);

  group('timeAgo', () {
    test('s<=0 → 0s（含未来/刚刚）', () {
      expect(timeAgo(now), '0s');
      expect(timeAgo(now + 5000), '0s');
      expect(at(0), '0s');
    });

    test('秒档 <1m', () {
      expect(at(0), '0s');
      expect(at(1000), '1s');
      expect(at(59000), '59s');
    });

    test('分档 <1h', () {
      expect(at(60000), '1m');
      expect(at(599 * 1000), '9m');
      expect(at(59 * 60000), '59m');
    });

    test('时档 <1d', () {
      expect(at(3600000), '1h');
      expect(at(23 * 3600000), '23h');
    });

    test('天档 >=1d', () {
      expect(at(86400000), '1d');
      expect(at(10 * 86400000), '10d');
    });

    test('向下取整', () {
      expect(at(1500), '1s'); // 1.5s → 1s
      expect(at(61000), '1m'); // 61s → 1m
      expect(at(3601000), '1h'); // 1h+1s → 1h
    });
  });
}
