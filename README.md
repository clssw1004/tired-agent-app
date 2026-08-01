# tired_agent_app

tiredAgentMobile — tired-agent 的 Flutter 客户端（Android / Windows / Linux）。

连接 tired-agent Manager 服务，管理 Agent、会话与终端，并提供 Claude 聊天界面。

## 后端

本项目是 [tired-agent](https://github.com/clssw1004/tired-agent) 的前端客户端。后端以 TypeScript 实现 Manager / Agent 服务，协议定义见 [@tired-agent/protocol](https://www.npmjs.com/package/@tired-agent/protocol)，Dart 端镜像位于 `lib/protocol/`。

## 快速开始

```bash
flutter pub get
flutter run          # 连接设备/模拟器启动
flutter test         # 运行测试
```

## 目录结构

| 模块 | 说明 |
|---|---|
| `screens/` | 页面层（go_router 路由） |
| `providers/` | 状态管理层（Provider + ChangeNotifier） |
| `protocol/` | 协议层 Dart 镜像（手写自 TypeScript） |
| `renderer/` | ClaudeRenderer NDJSON 解析引擎 |
| `widgets/pty_session_view.dart` | WebView + xterm.js + 自定义键盘 bridge |
