# 炫酷功能候选清单 — 2026-08-02

> **For agentic workers:** 候选功能池，按需挑选实现。实现时参照既有 plan 结构（文件变更清单 + Task 分组 + 提交策略）。每条标注工作量（S/M/L）与依赖。

**Goal:** 为 tired-agent 移动客户端扩充功能，覆盖刚需实用 + 炫酷 + 生态联动三个层级，按性价比选择实施。

**现有能力基线（避免重复建议）：**
- xterm2 终端 + SSE 实时流（`http_sse_transport` / `sse_client`，`onChunk`/`onState`/`onHeartbeat` 已齐）
- 多 manager 连接 + refresh token 轮换（`manager_connection`）
- enhancement 插件系统（`EnhancementRegistry`，`directorySelected` / `beforeSubmit` 两个挂点）
- 3 主题风格（neon/geek/material）+ 终端主题 + 深浅色
- 会话 pin、preset 预设、目录浏览、claude 会话 resume
- i18n（zh/en）、CI 构建 windows/linux/android

---

## 一、高频实用（刚需）

### F1. 会话退出本地通知 (S) ✅ 已完成
- **价值:** 长任务无需盯终端，session exited 即锁屏通知
- **技术:** `flutter_local_notifications`；双触发（SSE `onState` 快路径 + 30s 轮询慢路径）+ SharedPreferences 持久化去重
- **涉及:** `lib/services/session_exit_notifier.dart`（新）、`lib/widgets/shell/pty_session_view.dart`、`lib/providers/app_settings_provider.dart`、`lib/screens/settings/settings_screen.dart`、`lib/main.dart`、`android/app/build.gradle.kts`（desugaring）
- **依赖:** 无
- **设计:** `docs/superpowers/specs/2026-08-02-session-exit-notification.md`
- **分支:** `feat/session-exit-notification`（2026-08-02）

### F2. 终端文本选择 / 复制 (S)
- **价值:** 手机端终端刚需，长按选词复制
- **技术:** xterm2 selection API + `Clipboard.setData`；长按/双击触发选择模式，浮层复制按钮
- **涉及:** `lib/widgets/shell/pty_session_view.dart`、新增选择浮层 widget
- **依赖:** 无

### F3. 命令历史 + 快捷命令库 (M)
- **价值:** 复用的命令一键插入，补全手动输入
- **技术:** 服务端 `listSessions` 已返回 cmd/args，本地建索引；`session_presets` 骨架扩展为可编辑 snippets（本地存储）
- **涉及:** `lib/utils/session_presets.dart`、`lib/screens/session/create_session_screen.dart`、新增 snippets 管理页
- **依赖:** 无

### F4. 会话列表搜索 / 过滤 (S)
- **价值:** 会话多了找起来费劲
- **技术:** 现有 `_statusFilter` 旁加 text filter（label/cmd/cwd 匹配）
- **涉及:** `lib/screens/session/server_sessions_screen.dart`
- **依赖:** 无

### F5. 指纹 / 面容解锁 (S)
- **价值:** token 全在 secure storage，加本地锁更安全
- **技术:** `local_auth`；App 启动/回前台验证，失败回登录界面
- **涉及:** `lib/main.dart`、`lib/screens/` 新增锁屏页、`app_settings_provider` 加开关
- **依赖:** 无

### F6. 下拉刷新会话列表 (S)
- **价值:** 现在靠 5s 轮询，手动刷新更即时
- **技术:** `RefreshIndicator` 包 `ListView.builder`，触发 `_load()`
- **涉及:** `lib/screens/session/server_sessions_screen.dart`
- **依赖:** 无

## 二、炫酷

### F7. 会话录制 / asciinema 回放 (M)
- **价值:** 终端动画录制回放，演示/复盘利器
- **技术:** `onChunk` 已带 offset，本地累加输出为 cast 格式（含 timing），回放用 xterm2 逐帧写
- **涉及:** 新增 recorder + player widget，复用 `pty_session_view` 的终端渲染
- **依赖:** 无

### F8. AMOLED 纯黑主题 (S)
- **价值:** OLED 屏省电 + 视觉统一
- **技术:** `ThemeFlavor` 加 `oled`，新增 `buildOledLight/DarkTheme()`，纯黑底 `#000`
- **涉及:** `lib/providers/app_settings_provider.dart`、`lib/theme/md3_theme.dart`（或新文件）、`lib/main.dart`、`lib/theme/app_colors.dart`
- **依赖:** 无

### F9. 主题色自定义 (M)
- **价值:** 3 风格 × N 主色，个性化
- **技术:** `AppSettingsProvider` 加 accent 覆盖层，`ColorPicker` 选主色，持久化
- **涉及:** `lib/providers/app_settings_provider.dart`、`lib/theme/app_colors.dart`、新增设置项 + 拾色器
- **依赖:** 无

### F10. 扫二维码添加 manager (M)
- **价值:** 免手打长 URL+token
- **技术:** 后端生成 QR（url+token 编码）；客户端 `mobile_scanner` 扫码 → 预填 `login` 表单
- **涉及:** `lib/services/auth_service.dart`（login 已有）、新增扫码页
- **依赖:** 后端配合出 QR 接口

### F11. AI 会话总结 (L)
- **价值:** claude 长会话退出后一键摘要
- **技术:** 拉取会话输出 → 调后端 LLM 接口（或复用 claude backend）→ 展示摘要卡片
- **涉及:** 新增总结服务 + UI，`protocol/types.dart` 可能扩展类型
- **依赖:** 后端有 LLM 接口

## 三、生态联动

### F12. 桌面 Widget / Live Activity (L)
- **价值:** 锁屏/桌面看运行中 session 状态
- **技术:** Android App Widget（原生）+ iOS Live Activity（灵动岛）；`flutter_apple_widget` / 原生 bridge 共享 `session status`
- **涉及:** android/、ios/ 原生代码 + 数据同步（共享 prefs/通知）
- **依赖:** 原生开发
- **2026-08-07 评估：暂缓（价值不高）** — 灵动岛只能展示「状态 + 运行时长」，协议层无进度概念（`SessionStatus` 仅 starting/running/exited），信息增量有限；受众需 iPhone 14 Pro+ × iOS 16.1+；需 macOS 原生开发（Widget Extension + App Group），当前 Linux 环境无法编译验证。优先级低于 F2/F4/F5 等高频实用项。若未来做，最小版本 = 运行中状态显示（复用 F1 的双触发骨架：SSE `onState` 快路径 + 轮询慢路径）。

### F13. 深链 + 分享 (S)
- **价值:** `tiredagent://session/{id}` 直达页面；分享/导入 manager 配置
- **技术:** 自定义 URL scheme，`go_router` 解析深链；manager 配置加密导出/导入（JSON + AES）
- **涉及:** `lib/main.dart`（路由）、android/ios 原生 scheme、`storage_service` 加导入导出
- **依赖:** 无

### F14. 文件双向传输 (M)
- **价值:** 手机 ↔ agent 传文件，配合终端闭环
- **技术:** 现有 `listDirectories` 基础上加 upload/download 接口；文件选择用 `file_picker`
- **涉及:** `protocol/transport.dart` + `http_sse_transport.dart` 加接口、`directory_picker` 扩展
- **依赖:** 后端加文件接口

## 四、低成本小爽点

- F15. 双击 = 呼出键盘（已有），**三击全选**终端文本 (S)
- F16. 触觉反馈：kill/delete/prune 操作 `HapticFeedback.mediumImpact()` (S)
- F17. 会话 pin 分组 / 打标签，扩展 `pinned_session` 为 folders (M)
- F18. 暗色跟随系统亮度自动切换 (S)

---

## 优先级建议

| 批次 | 功能 | 理由 |
|---|---|---|
| 第一批（刚需，1-2 天） | ~~F1 通知~~ ✅, F2 复制, F5 生物锁, F6 下拉刷新 | 使用频次最高、纯 Flutter、不依赖后端 |
| 第二批（炫酷） | F8 OLED, F7 录制, F9 主题色, F4 搜索 | 纯 Flutter 可独立交付，视觉/演示价值高 |
| 第三批（生态） | F13 深链, F14 文件传输, F10 扫码 | 需要原生/后端配合，按排期推进 |
| 按需 | F3, F11, F12, F15-F18 | 看用户反馈再定 |

## 实施记录

- **2026-08-02 F1 完成**（分支 `feat/session-exit-notification`）：双触发 + 持久化去重 + 设置开关 + 通知点击跳转；`flutter analyze` 无错、105 测试通过、Android debug 构建通过

## 实施建议

- 每个功能独立分支 `feat/<name>-<date>`，独立 PR
- 涉及后端接口的（F10/F14/F11）先出接口约定再动客户端
- 每功能完成跑 `flutter analyze` + 相关 widget test
