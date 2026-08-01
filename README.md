# tired_agent_app

[English](README.md) · [中文](README.zh-CN.md)

tiredAgentMobile — a Flutter client for tired-agent (Android / Windows / Linux).

Connect to a tired-agent Manager service to manage agents, sessions and terminals, with a built-in Claude chat interface.

## Backend

This project is the frontend client of [tired-agent](https://github.com/clssw1004/tired-agent). The backend implements the Manager / Agent services in TypeScript; the protocol is defined in [@tired-agent/protocol](https://www.npmjs.com/package/@tired-agent/protocol) and mirrored in Dart under `lib/protocol/`.

## Getting Started

```bash
flutter pub get
flutter run          # launch on device / emulator
flutter test         # run tests
```

## Screenshots

### Managers & Agents

| | |
|---|---|
| ![Add Manager](screenshots/add-manager.png) Add Manager | ![Manager list](screenshots/manager-list.png) Managers and agents |

### Sessions & Terminal

| | |
|---|---|
| ![New session](screenshots/session-create.png) New session | ![Session list](screenshots/session-list.png) Sessions |

### Claude Chat

| | |
|---|---|
| ![Claude session](screenshots/claude-session-hello.png) Claude session | ![Claude session](screenshots/claude-session-1.png) Claude session |
| ![Session resume](screenshots/claude-resume.png) Resume history | ![Extension keyboard](screenshots/claude-extension-keyboard.png) Claude extension keyboard |

### Settings

| | |
|---|---|
| ![Settings](screenshots/settings.png) Settings | ![Theme](screenshots/theme.png) Theme |

## Structure

| Module | Description |
|---|---|
| `screens/` | UI layer (go_router routes) |
| `providers/` | State management (Provider + ChangeNotifier) |
| `protocol/` | Dart mirror of the protocol (hand-written from TypeScript) |
| `renderer/` | ClaudeRenderer NDJSON parsing engine |
| `widgets/pty_session_view.dart` | WebView + xterm.js + custom keyboard bridge |
