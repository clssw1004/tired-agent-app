# F1 — 会话退出本地通知 设计

> 2026-08-02 设计。候选功能清单 F1（`docs/superpowers/plans/2026-08-02-cool-features-backlog.md`）。

## 目标

跑长任务（编译、build、claude 会话）时无需盯终端——会话从 running 转 exited，锁屏/通知栏提醒用户。

**限制说明**：本地通知只能在 app 存活时触发（移动端后台会被 OS 挂起）。app 被彻底杀死后无法提醒，那是远程推送（F1 明确不涉及，另见 plan）。

## 现状与挂点

- ChatView 生态已删（#62），所有会话统一走 `PtySessionView` + `SseClient`
- 退出信号已有两处：
  1. `SseClient._onState`（`lib/protocol/sse_client.dart:130`）— 仅会话页打开时存在 SSE 流
  2. `SseClient.start()` 历史拉取抛 `SessionNotFoundException`（:78）— 会话已退出
- 会话列表 `listSessions` 可随时拿到全量状态（`session_api_service.dart`）
- `main.dart` 已有 `WidgetsBindingObserver`，可感知前后台切换

## 方案

双触发 + 持久化去重：

```
触发 A（快路径）：SSE 实时 onState=exited（正在看会话页时，即时提醒）
触发 B（慢路径）：全局轮询器，app 前台每 30s 拉取各 agent 会话列表，
                  检测 running→exited 转移（不在会话页也能提醒）
去重：通知 key = profileId:agentId:sessionId，SharedPreferences 持久化，
      已通知过的会话不再重复发（跨触发 A/B、重连、重启均只一次）
```

### 为什么不做"只在后台才通知"

判"当前是否正看该会话"需要路由感知耦合，收益低。统一提醒 + 去重即可，通知本身也是"任务完成"的确认信号。

### 前台 tap 处理

`onDidReceiveNotificationResponse` 回调 → go_router push 到 `/session/:profileId/:agentId/:sessionId`。app 被杀后从通知冷启动：启动时查 `getNotificationAppLaunchDetails`，首帧后跳转。

## 组件划分

### 1. `lib/services/session_exit_notifier.dart`

| 类 | 职责 |
|---|---|
| `SessionExitTracker`（纯 Dart，可单测） | 去重逻辑：`shouldNotify(key)` / `markNotified(key)` / 持久化读写 |
| `SessionExitNotifier` | 插件封装：init、权限请求、发通知、tap 回调、轮询定时器 |

```dart
class SessionExitTracker {
  // 内部维护已通知 key 集合，load/save 走 SharedPreferences
  bool shouldNotify(String key) => !_notified.contains(key);
  Future<void> markNotified(String key);
  static String keyFor(String profileId, String agentId, String sessionId);
}
```

```dart
class SessionExitNotifier {
  Future<void> init({required void Function(SessionRef) onTap});
  void startWatching();               // 起 30s 轮询定时器
  void pauseWatching();               // 切后台暂停
  void resumeCheck();                 // 回前台立即查一次
  void stopWatching();
  Future<void> handleExited(SessionRef ref, Session session); // 快路径
}
```

轮询器迭代 `AuthService.connections` → 各 `agents` → `SessionApiService.listSessions()` → 对每个 session 调 `handleState(ref, session)`。网络失败静默跳过。

### 2. `lib/providers/app_settings_provider.dart`

新增开关 `sessionExitNotifications`（默认开），持久化 key `session_exit_notifications`，settings 页联动。

### 3. `lib/widgets/shell/pty_session_view.dart`

`_initialize()` 的 `_sseClient.onState` 回调里，`status == exited` 分支追加 `notifier.handleExited(...)`（快路径）。经 `context.read` 取 notifier。

### 4. `lib/screens/settings/settings_screen.dart`

新增一行设置开关（复用 settings_tile 组件）。

### 5. `lib/main.dart`

- `MultiProvider` 注册 `SessionExitNotifier`（Provider）
- boot 后 `startWatching()`；`didChangeAppLifecycleState` 挂 `pauseWatching`/`resumeCheck`
- 通知 tap → 路由跳转；启动时处理冷启动跳转

## 依赖与平台配置

- **依赖**: `flutter_local_notifications`（pub add 最新兼容版）
- **Android**: 无需 manifest 改动（本地通知）；Android 13+ 运行时请求 `POST_NOTIFICATIONS`（`requestNotificationsPermission`）；通知渠道 `session_events`
- **iOS**: `DarwinInitializationSettings` 请求 alert/badge/sound 权限；`IPHONEOS_DEPLOYMENT_TARGET=13.0` 已满足（要求 ≥11）
- **权限弹窗时机**：app 首次进入会话退出流程且开关开启时请求（避免启动即打扰）——初版简化为 app 启动时静默请求（iOS 首次弹窗），开关默认开

## 文件变更清单

### 新建（2）

| 文件 | 职责 |
|---|---|
| `lib/services/session_exit_notifier.dart` | tracker + notifier |
| `test/session_exit_tracker_test.dart` | 去重/持久化单测 |

### 修改（5）

| 文件 | 改动 |
|---|---|
| `pubspec.yaml` | 加 `flutter_local_notifications` |
| `lib/providers/app_settings_provider.dart` | 开关 + 持久化 |
| `lib/screens/settings/settings_screen.dart` | 设置项 UI |
| `lib/widgets/shell/pty_session_view.dart` | 快路径挂接 |
| `lib/main.dart` | 注册服务 + 轮询生命周期 + tap 路由 |

## 不走的设计

- ❌ **远程推送（APNs/FCM）**：需要开发者账号/后端，超 F1 范围
- ❌ **后台隔离（Android background isolate）**：冷启动 tap 导航用 launch-details 即可，暂不引入 `@pragma('vm:entry-point')` 后台回调复杂度（初版不做 killed 后点击跳转的后台回调，只做冷启动 launch-details 跳转）
- ❌ **只通知"未在看的会话"**：需路由感知，耦合高，收益低
- ❌ **每 5s 高频轮询**：30s 足够，省电

## 验收标准

1. 会话页内跑任务退出 → 立即弹通知（快路径）
2. 非会话页（列表/设置/其他 tab）app 前台时任务退出 → ≤30s 内弹通知（慢路径）
3. 同一会话退出只通知一次（跨路径/重连/重启去重）
4. 通知 tap → 跳转对应会话详情页
5. settings 开关可关，关闭后不再通知
6. `flutter analyze` 无错 + tracker 单测通过
