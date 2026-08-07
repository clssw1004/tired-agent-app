/// 相对时间格式化：把"距某个时刻的毫秒时间戳"换算成简短相对时间。
///
/// 供 geek 卡片等终端风格 UI 复用（此前在各卡片内重复实现 `_timeSince`）。
/// 格式为纯数字+单位：`'5s'` / `'3m'` / `'2h'` / `'1d'`，与终端短横行一致。
String timeAgo(int tsMs) {
  final s = DateTime.now().millisecondsSinceEpoch - tsMs;
  if (s <= 0) return '0s';
  if (s < 60000) return '${s ~/ 1000}s';
  if (s < 3600000) return '${s ~/ 60000}m';
  if (s < 86400000) return '${s ~/ 3600000}h';
  return '${s ~/ 86400000}d';
}
