# tired_agent_app

[English](README.md) · [中文](README.zh-CN.md)

[![Flutter](https://img.shields.io/badge/Flutter-3.41.6-blue?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux-green)](https://github.com/clssw1004/tired-agent-app)
[![Backend](https://img.shields.io/badge/backend-tired--agent-orange)](https://github.com/clssw1004/tired-agent)

tiredAgentMobile — tired-agent 的 Flutter 客户端（Android / Windows / Linux）。

连接 tired-agent Manager 服务，管理 Agent、会话与终端。

## 后端

本项目是 [tired-agent](https://github.com/clssw1004/tired-agent) 的前端客户端。后端以 TypeScript 实现 Manager / Agent 服务，协议定义见 [@tired-agent/protocol](https://www.npmjs.com/package/@tired-agent/protocol)，Dart 端镜像位于 `lib/protocol/`。

## 快速开始

```bash
flutter pub get
flutter run          # 连接设备/模拟器启动
flutter test         # 运行测试
```

## 界面预览

### 管理器与 Agent

| | |
|---|---|
| ![添加 Manager](screenshots/add-manager.png) 添加 Manager | ![管理器列表](screenshots/manager-list.png) 管理器与 Agent 列表 |

### 会话与终端

| | |
|---|---|
| ![新建会话](screenshots/session-create.png) 新建会话 | ![会话列表](screenshots/session-list.png) 会话列表 |

### 设置

| | |
|---|---|
| ![设置页](screenshots/settings.png) 设置 | ![主题设置](screenshots/theme.png) 主题设置 |

## 目录结构

| 模块 | 说明 |
|---|---|
| `screens/` | 页面层（go_router 路由） |
| `providers/` | 状态管理层（Provider + ChangeNotifier） |
| `protocol/` | 协议层 Dart 镜像（手写自 TypeScript） |
| `widgets/pty_session_view.dart` | xterm2 终端视图 + 自定义键盘 bridge |
