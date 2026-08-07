import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/services/auth_service.dart';
import 'package:tired_agent_app/services/session_api_service.dart';
import 'package:tired_agent_app/utils/app_strings.dart';

/// 会话退出通知的引用信息（也作为通知 payload / 跳转参数）。
class SessionRef {
  final String profileId;
  final String agentId;
  final String sessionId;
  final String label;
  final String cmd;

  const SessionRef({
    required this.profileId,
    required this.agentId,
    required this.sessionId,
    required this.label,
    required this.cmd,
  });

  /// 通知 payload 编码。
  String toPayload() =>
      jsonEncode({'p': profileId, 'a': agentId, 's': sessionId});

  /// 从通知 payload 解码，非法输入返回 null。
  static SessionRef? fromPayload(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return SessionRef(
        profileId: map['p'] as String,
        agentId: map['a'] as String,
        sessionId: map['s'] as String,
        label: '',
        cmd: '',
      );
    } catch (_) {
      return null;
    }
  }
}

/// 退出状态追踪（纯 Dart，可单测）。
///
/// 只在「running→exited 转移」时判定为需通知，且每个会话只通知一次：
/// - [_running]：本 app 会话内观测到的 running 会话（内存）
/// - [_notified]：已通知过的会话（SharedPreferences 持久化，跨重启去重）
class SessionExitTracker {
  static const _kNotified = 'notified_session_keys';

  final SharedPreferences _prefs;
  final Set<String> _running = {};
  final Set<String> _notified = {};

  SessionExitTracker(this._prefs);

  static String keyFor(String profileId, String agentId, String sessionId) =>
      '$profileId:$agentId:$sessionId';

  /// 从持久化存储加载已通知集合。
  void load() {
    _notified
      ..clear()
      ..addAll(_prefs.getStringList(_kNotified) ?? const []);
  }

  /// 记录一个 running 会话。
  void trackRunning(String key) => _running.add(key);

  /// 判定某个 exited 会话是否该通知：必须是从 running 转移过来且从未通知过。
  bool shouldNotify(String key) =>
      _running.remove(key) && !_notified.contains(key);

  /// 标记已通知并持久化。
  Future<void> markNotified(String key) async {
    if (_notified.add(key)) {
      await _prefs.setStringList(_kNotified, _notified.toList());
    }
  }

  @visibleForTesting
  Set<String> get notified => Set.unmodifiable(_notified);
}

/// 会话退出本地通知服务。
///
/// 双触发：
/// - 快路径 [handleExited]：SSE 实时事件（会话页打开时）
/// - 慢路径 [startWatching] 轮询：app 前台每 [pollInterval] 拉取会话列表
///   （不在会话页也能提醒）
///
/// 权限（Android 13+ / iOS）在 [init] 时请求；开关由外部注入 [isEnabled]。
class SessionExitNotifier {
  static const _kChannelId = 'session_events';
  static const _kChannelName = 'Session Events';
  static const pollInterval = Duration(seconds: 30);

  final FlutterLocalNotificationsPlugin _plugin;
  SessionExitTracker? _tracker;
  AuthService? _authService;
  bool Function()? _isEnabled;
  void Function(SessionRef ref)? _onTap;
  Timer? _watchTimer;
  bool _initialized = false;

  SessionExitNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// 插件初始化 + 权限请求 + 已通知集合加载。
  ///
  /// [authService] 供轮询器枚举 manager/agent；[onTap] 通知点击回调。
  /// 非 Android/iOS 平台（如单测）安全降级。
  Future<void> init({
    required AuthService authService,
    required bool Function() isEnabled,
    required void Function(SessionRef ref) onTap,
  }) async {
    _authService = authService;
    _isEnabled = isEnabled;
    _onTap = onTap;

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
    } catch (e) {
      debugPrint('[SessionExitNotifier] initialize failed: $e');
      return;
    }

    // Android 13+ 运行时权限（旧版本 no-op）。
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('[SessionExitNotifier] request permission failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    _tracker = SessionExitTracker(prefs)..load();
    _initialized = true;
    debugPrint('[SessionExitNotifier] initialized');
  }

  /// 快路径：SSE 观测到会话退出时调用（会话需先 [trackRunning]）。
  Future<void> handleExited(SessionRef ref) => _notifyIfNeeded(ref);

  /// 记录 running 会话（会话页打开 running 会话时调用）。
  void trackRunning(SessionRef ref) {
    if (_initialized) {
      _tracker?.trackRunning(_key(ref));
    }
  }

  /// 启动轮询（app 前台）。幂等。
  void startWatching() {
    if (_watchTimer != null || !_initialized) return;
    _watchTimer = Timer.periodic(pollInterval, (_) => _poll());
  }

  /// 暂停轮询（app 切后台，省电）。
  void pauseWatching() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  /// 回前台立即查一次（比等下一个周期快）。
  Future<void> resumeCheck() async {
    startWatching();
    await _poll();
  }

  /// 从通知冷启动 app 时，取出待跳转的会话。
  ///
  /// 在 [init] 完成后可调用一次；无则返回 null。
  Future<SessionRef?> takeLaunchRef() async {
    if (!_initialized) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final payload = details?.notificationResponse?.payload;
      if (details?.didNotificationLaunchApp == true && payload != null) {
        return SessionRef.fromPayload(payload);
      }
    } catch (e) {
      debugPrint('[SessionExitNotifier] launch details failed: $e');
    }
    return null;
  }

  /// 停止监听并释放资源。
  void dispose() {
    pauseWatching();
  }

  // ── Internal ───────────────────────────────────────────────────────────

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final ref = SessionRef.fromPayload(payload);
    if (ref != null) _onTap?.call(ref);
  }

  String _key(SessionRef ref) =>
      SessionExitTracker.keyFor(ref.profileId, ref.agentId, ref.sessionId);

  Future<void> _notifyIfNeeded(SessionRef ref) async {
    final tracker = _tracker;
    if (!_initialized || tracker == null) return;
    if (_isEnabled?.call() != true) return;
    final key = _key(ref);
    if (!tracker.shouldNotify(key)) return;
    await tracker.markNotified(key);
    await _show(ref);
  }

  Future<void> _show(SessionRef ref) async {
    try {
      await _plugin.show(
        id: _notificationId(ref),
        title: AppStrings.of.sessionExitNotificationTitle(ref.label),
        body: AppStrings.of.sessionExitNotificationBody(ref.cmd),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _kChannelId,
            _kChannelName,
            channelDescription: 'Session exit notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: ref.toPayload(),
      );
    } catch (e) {
      debugPrint('[SessionExitNotifier] show failed: $e');
    }
  }

  int _notificationId(SessionRef ref) => _key(ref).hashCode & 0x7fffffff;

  Future<void> _poll() async {
    if (!_initialized || _authService == null) return;
    if (_isEnabled?.call() != true) return;

    for (final conn in _authService!.connections) {
      if (conn.status != ConnectionStatus.connected) continue;
      final profileId = conn.profile.id;
      for (final agent in conn.agents) {
        try {
          final sessions = await SessionApiService(
            conn: conn,
            agentId: agent.id,
          ).listSessions();
          for (final s in sessions) {
            if (s.status == SessionStatus.exited) {
              await _notifyIfNeeded(
                SessionRef(
                  profileId: profileId,
                  agentId: agent.id,
                  sessionId: s.id,
                  label: s.label ?? s.cmd,
                  cmd: s.cmd,
                ),
              );
            }
          }
        } catch (e) {
          // 单 agent 拉取失败静默跳过，等下一周期。
          debugPrint('[SessionExitNotifier] poll failed for ${agent.id}: $e');
        }
      }
    }
  }
}
