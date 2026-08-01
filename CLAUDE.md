# CLAUDE.md — tired_agent_app (Flutter)

## 注意事项

- **全程使用中文对话**
- 修 BUG、开发新需求必须从最新的 main 分支切出一个新分支进行开发
- 分支名称格式：`${修改类型(feat/fix/refactor)}/${内容相关-${日期(年月日)}}`
- 任何 Dart 代码改动前，查阅 [Flutter API 文档](https://api.flutter.dev/) 确认最佳实践
- 修改 android/ios 原生配置时，优先使用 Flutter plugin 的 Dart 层配置（如 `AndroidManifest.xml` 配置在 plugin 的 `android/src/main/` 下），不直接触碰 `android/app/` 下的原生文件
- **涉及服务端交互（Transport、协议类型、Session 管理等）时，参考 `tired-agent` 仓库中对应的 TypeScript 实现**，保持 Dart 端与协议对齐

## Branch strategy

| Branch | Allowed operations |
|--------|-------------------|
| `main` | 版本升级、CI/CD 配置变更、README/CLAUDE.md/docs 等文档更新 |
| `feat/*` | 特性开发 — 从 main 签出，完成后 PR → main |
| `fix/*` | Bug 修复 — 从 main 签出，完成后 PR → main |
| `refactor/*` | 重构 — 从 main 签出，完成后 PR → main |

**规则：`main` 分支不得有特性开发、bug 修复、重构等代码变更。** 这类工作必须在各自的分支进行，通过 PR 合并回 main。版本修改只能在 main 上操作。

## Commands

```bash
# 开发服务
flutter run                    # 连设备/模拟器启动
flutter run --debug            # Debug 模式

# 检查
flutter analyze                # Dart 静态分析（替代 typecheck）
flutter test                   # 单元测试
flutter test --coverage        # 带覆盖率

# 构建
flutter build apk --debug      # Android debug APK
flutter build apk --release    # Android release APK
flutter build ios --release    # iOS release（需 macOS）

# lint
dart format --set-exit-if-changed lib/  # 格式化检查
dart analyze lib/                       # 代码分析

# 依赖
flutter pub get                # 安装/更新依赖
flutter pub upgrade            # 升级依赖
flutter pub outdated           # 检查过期依赖
```

## 架构概要

### 数据流

```
App → AuthProvider(login) → transport.login(ref) → manager /v1/manager/auth/login
    → AuthProvider.connectionFor(profileId) → transport.listAgents(ref) → manager /v1/manager/agents
    → subscribe → transport.subscribe(ref, sessionId, handlers) → agent SSE stream
    → chunk accumulation → ClaudeRenderer.processChunk → UI 渲染
```

### 关键模块

| 模块 | 说明 |
|---|---|
| `screens/` | 页面层（go_router 路由） |
| `providers/` | 状态管理层（Provider + ChangeNotifier） |
| `protocol/` | 协议层 Dart 镜像（手写自 TypeScript） |
| `renderer/` | ClaudeRenderer NDJSON 解析引擎 |
| `widgets/pty_session_view.dart` | WebView + xterm.js + 自定义键盘 bridge |

## 代码规范

### 导入顺序

```
1. Flutter / Dart SDK 核心库（flutter/material, dart:io, dart:convert, ...）
2. 第三方库（provider, go_router, http, ...）
3. package: 项目内部包（project: 开头导入）
4. 相对路径导入（'./xxx.dart', '../xxx.dart'）
```

### 文件命名

- **Widget 文件**：snake_case（`chat_timeline.dart`、`server_card.dart`）
- **纯逻辑/工具文件**：snake_case（`bytes.dart`、`keyboard.dart`、`storage_service.dart`）
- **Provider 文件**：snake_case（`auth_provider.dart`、`server_provider.dart`）
- **路由文件**：snake_case（`router.dart`）
- **类型文件**：snake_case（`types.dart`）
- **测试文件**：与被测文件同名 + `_test.dart`（`http_sse_transport_test.dart`）

### Widget 结构

每个 widget 文件内按以下顺序：

```dart
// 1. imports（按上述导入顺序）
// 2. 常量/类型定义（Props, enums）
// 3. Widget 类（StatelessWidget / StatefulWidget）
// 4. State 类（如有）
// 5. 私有辅助方法
// 6. 样式常量（const _styles = {...}）
```

示例模板：

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/auth_provider.dart';
// ...

class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(title),
    );
  }
}
```

### 样式

- **优先 `const` theme**：`Theme.of(context).colorScheme`，不内联硬编码颜色
- **间距取自 `ThemeData` 或 `EdgeInsets` 常量**：统一间距，不散用硬编码像素值
- **`build` 方法只放布局逻辑**，计算和样式提取到方法/变量
- **优先 `Flex` / `Column` / `Row` 布局**，不用 `Stack`/`Positioned`（弹层/Overlay 除外）

### Provider 模式

```dart
// auth_provider.dart
class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.idle;
  String? _sessionToken;
  String? _baseUrl;
  String? _error;
  List<AgentInfo> _agents = [];

  AuthStatus get status => _status;
  String? get sessionToken => _sessionToken;
  // ...

  Future<void> login(String url, String token) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      // ... transport.login ...
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }
}
```

- Provider 只放"全局共享"状态（auth、server list）
- 页面级状态放 `StatefulWidget` 内部
- Session 级状态（SSE 流）放 `ClaudeChatView` 的 `StatefulWidget`

## 常见陷阱

### TextEditingController + Dialog 生命周期

**错误做法**：在方法内创建 controller，弹窗关闭后同步 dispose。

```dart
// ❌ controller.dispose() 在 TextField 卸载前执行 → _dependents.isEmpty 崩溃
final ctl = TextEditingController();
final result = await showDialog<bool>(
  builder: (_) => AlertDialog(content: TextField(controller: ctl)),
);
ctl.dispose(); // ← 此时 TextField 还挂在卸载中的路由上
```

**原因**：`Navigator.pop()` 触发路由移除但 TextField 的 widget 树不会立即销毁。`showDialog` 的 `await` 返回后同步调用 `controller.dispose()` 时，`ChangeNotifier` 发现还有 listener（TextField）→ 断言失败。

**正确做法**：把 controller 放到 `StatefulWidget` 内部，`initState` 创建、`State.dispose` 释放。

```dart
class MyForm extends StatefulWidget { ... }
class MyFormState extends State<MyForm> {
  late final TextEditingController _ctl;
  @override void initState() { super.initState(); _ctl = TextEditingController(); }
  @override void dispose() { _ctl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => TextField(controller: _ctl);
}
```

框架保证 widget 树从子到父依次销毁：`TextField` 先 dispose（移除 listener），然后 parent State 的 `dispose()` 才执行 → 安全释放 controller。

相关文件：`lib/widgets/add_manager_form.dart`、`lib/screens/server_list_screen.dart:_ReconnectForm`、`lib/screens/server_sessions_screen.dart:_PinLabelForm`

### initState 中触发 notifyListeners 链

**错误做法**：`initState` 调用异步方法 → `notifyListeners()` → GoRouter/AuthProvider 在 build 阶段收到通知 → "setState() called during build" 崩溃。

```dart
// ❌ conn.connect() → ManagerConnection.notifyListeners() → AuthProvider → GoRouter rebuild
@override
void initState() {
  super.initState();
  _loadAgents(); // 内部调用 conn.connect() → notifyListeners()
}
```

**原因**：`initState` 在 widget 首次构建期间执行。`connect()` 调用 `notifyListeners()` 后通知链传到 `GoRouter`，GoRouter 尝试在 build 阶段调用 `setState()` → Flutter 抛出异常（`Router<Object>` 不允许在 build 中标记 dirty）。

**正确做法**：
1. **同步加载缓存数据** — 直接从已有状态读取（如 `conn.agents`），避免 notifyListeners
2. **异步刷新延迟到首帧后** — 用 `addPostFrameCallback` 或 `Future.microtask`

```dart
@override
void initState() {
  super.initState();
  // 第1步：同步从缓存加载（不会触发 notifyListeners）
  final conn = context.read<AuthProvider>().connectionFor(profileId);
  _agents = conn?.agents ?? [];

  // 第2步：首帧后异步刷新
  WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
}

Future<void> _refresh() async {
  await conn?.connect();  // 此时 build 阶段已过，安全
  setState(() { _agents = List.from(conn!.agents); });
}
```

**触发途径**：`ManagerConnection.connect()` → `notifyListeners()` → `AuthProvider`（监听 ManagerConnection）→ `notifyListeners()` → `GoRouter`（`refreshListenable` 监听 AuthProvider）→ 触发路由重建。

相关文件：`lib/screens/manager_detail_screen.dart`

### 与 tired-agent/web 的同步

- `lib/renderer/` 通过手工翻译自 `tired-agent/packages/web/src/renderer/`
- `lib/utils/` 通过手工翻译自 `tired-agent/web/src/` 散落文件
- 翻译后必须跑 `flutter test` 验证无回归
- 关键同步契约：`ClaudeRenderer.processChunk`、`formatBytes`、`stripAnsi`

### 关于组件的封装与页面的拆分
当一个页面/组件文件行数大于300行时，就要考虑该页面是否需要真的那么大，里面组件是否可提取出来，若判断可提取，则需要进行页面/组件重构拆分。

## Key config

| 配置 | 位置 | 说明 |
|---|---|---|
| Flutter SDK 版本 | `pubspec.yaml` → `environment.sdk` | `^3.11.4` |
| Android min SDK | `android/app/build.gradle` | minSdkVersion 26 |
| iOS deployment target | `ios/Podfile` | platform :ios, '15.0' |
| 路由 | `lib/router.dart` | GoRouter 表（类文件路由） |
| 协议引用 | `lib/protocol/` | Dart 手写镜像，对应 TS `@tired-agent/protocol` |
| 安全存储 | flutter_secure_storage | accessToken / refreshToken |
| 非敏感持久化 | shared_preferences | baseUrl / server list |

## Windows notes

- Android SDK 路径需要配置 `ANDROID_HOME` 环境变量
- Flutter 在 Windows 上开发 Android 应用工作正常；iOS 构建需 macOS
- 路径 separator：Dart 使用 `Uri` / `Platform.pathSeparator`，**不**硬编码 `/` 或 `\\`
- `webview_flutter` 在 Windows 上可用 Android 模拟器/真机测试

## Release

1. 更新版本号（`pubspec.yaml` → `version`）
2. 打 tag `v<version>`（与 GitHub Actions `.github/workflows/flutter_build.yml` 的 `tags: ["v*"]` 匹配）
3. push tag → CI 自动构建 windows / linux / android + 创建 GitHub Release
4. 本地手动构建：`flutter build apk --release`（Android）/ `flutter build ios --release`（iOS，需 macOS）

Android 版本号在 `android/app/build.gradle.kts` 的 `versionCode` / `versionName`，iOS 在 `ios/Runner/Info.plist`，版本号**独立管理**。

## CI / Android 签名

`main` 分支的 `.github/workflows/flutter_build.yml` 在 tag push 时并行构建三平台。Android release 通过 `secrets.KEYSTORE_BASE64` 注入 `android/app/tired-agent.keystore`，再把密码/别名写入 `android/key.properties`（两个文件已 `.gitignore`）。

GitHub 需配置 4 个 Secret：`KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` / `KEY_PASSWORD` / `KEY_ALIAS`。详见 `README.md` 的「GitHub Secrets 配置」章节。

build.gradle.kts 的 release buildType 会先检测 `key.properties` 是否存在，存在则用 release 签名，否则回退 debug（方便本地未配签名的调试）。

## 参考链接

- [Flutter API 文档](https://api.flutter.dev/)
- [go_router 文档](https://pub.dev/packages/go_router)
- [provider 文档](https://pub.dev/packages/provider)
- [@tired-agent/protocol](https://www.npmjs.com/package/@tired-agent/protocol) （npm 已发布，Dart 端镜像）
- [tired-agent monorepo](https://github.com/clssw1004/tired-agent)
