# Cyberpunk 霓虹风 — App 样式改造设计文档

**日期**: 2026-07-24
**状态**: 已批准
**项目**: tired_agent_app (Flutter)

---

## 1. 设计目标

将 App 整体视觉风格从 iOS 原生深色主题改造为 **Cyberpunk 青紫霓虹风**，同时封装可复用的通用组件体系。

### 核心原则

- **Geek 感** — 终端运维工具的视觉辨识度
- **克制** — 发光效果恰到好处，不牺牲性能和使用效率
- **组件复用** — 关键 UI 模式抽象为通用组件（NeonCard、GlowBadge 等）
- **零额外字体依赖** — 只使用系统 `monospace`，不增加 APK 体积

---

## 2. 色板系统

### 2.1 基础色板

| Token | 值 | 用途 |
|---|---|---|
| `background` | `#0A0A0F` | Scaffold / 页面背景 |
| `surface` | `#12121A` | 卡片 / 列表项 / 弹窗背景 |
| `surfaceAlt` | `#1A1A2E` | 选中态高亮 / 输入框背景 |
| `border` | `#2A2A4A` | 默认边框 / 分割线（非活跃态） |
| `borderGlow` | `#3A3A6A` | 边框发光（hover/focus） |

### 2.2 语义色板

| Token | 值 | 用途 |
|---|---|---|
| `primary` (霓虹青) | `#00F0FF` | 主色、按钮、Switch、选中态 |
| `secondary` (霓虹品红) | `#FF00FF` | 辅助强调、罕见操作 |
| `purple` (电紫) | `#7B61FF` | 信息提示、链接 |
| `success` (Matrix 绿) | `#00FF41` | 运行中、状态绿灯 |
| `warning` (橙) | `#FF6600` | 警告、Starting 状态 |
| `danger` (霓虹红) | `#FF003C` | 错误、危险操作 |

### 2.3 文字色板

| Token | 值 | 用途 |
|---|---|---|
| `text` | `#E8E8F0` | 主文字 |
| `textSecondary` | `#7878A0` | 辅助文字、时间戳 |
| `textMono` | `#B8B8D0` | 等宽数据文字 |

### 2.4 发光等级

每个语义色提供 3 级发光强度，通过 `withAlpha` 和自定义装饰实现：

| 级别 | 用法 | 示例 |
|---|---|---|
| Level 1 (微弱) | `withAlpha(15)` | 背景填充 |
| Level 2 (柔和) | `withAlpha(40)` + 1px border | 卡片边框发光 |
| Level 3 (强光) | `withAlpha(80)` + `GlowDecoration` | 选中态、聚焦输入框 |

---

## 3. 排版

不引入第三方字体。使用系统默认字体 + `monospace`：

| 角色 | FontFamily | FontSize | Weight | 使用场景 |
|---|---|---|---|---|
| 页面标题 | 系统默认 | 18 | w600 | AppBar title |
| 卡片标题 / 列表 | 系统默认 | 14 | w500 | Server/Session 卡片标题 |
| 正文 | 系统默认 | 14 | normal | 普通文本 |
| 辅助文字 | 系统默认 | 12 | normal | 说明、时间 |
| **等宽数据** | **monospace** | **12** | normal | Session cmd、URL、PID、exit code |
| **等宽标签** | **monospace** | **10** | w500 | 状态标签、Badge |

---

## 4. 通用组件

### 4.1 NeonCard (`widgets/neon_card.dart`)

暗色容器卡片，取代 `Card(color: AppColors.backgroundElement)`。

**Props**:
- `child` — 内容 widget
- `borderColor` — 默认无色；传入 `AppColors.primary` 等显示发光边框
- `glow` — bool，边框发光效果（`borderColor` 不为空时启用）
- `onTap` — 可选点击
- `padding` / `margin`

**状态**:
- 默认: `surface` 背景，`border` 颜色 1px 边框（极淡）
- 激活 (Active): `surfaceAlt` 背景，`primary` 颜色边框 + glow
- Hover/Press: 边框亮度微增

### 4.2 GlowBadge (`widgets/glow_badge.dart`)

状态标签，绿色/红色/黄色圆点 + 文字，带发光效果。

**Props**:
- `status` — `running` / `starting` / `exited` / `error` / `connected` / `disconnected`
- `label` — 自定义文字（也可 auto-generate）
- `glow` — 默认 true

**样式**:
```
[● Running]    — #00FF41 + glow
[● Starting]   — #FF6600 + glow
[● Exited]     — #7878A0 无发光
[✕ Error]      — #FF003C + glow
```

### 4.3 NeonDivider (`widgets/neon_divider.dart`)

分割线，可选带节标题，左右霓虹发光横条。

**Props**:
- `label` — 可选节标题文字
- `color` — 默认 `primary`

### 4.4 SectionHeader (`widgets/section_header.dart`)

节标题，左侧 3px 霓虹发光竖条 + 等宽 uppercase 文字。

**Props**:
- `label` — 标题文字
- `color` — 默认 `primary`

### 4.5 NeonLoading (`widgets/neon_loading.dart`)

加载指示器，三种模式可切换：

- **spinner** — 圆环旋转，边框渐变色 `primary` → `secondary`
- **pulse** — 三点脉冲（`● ● ●` 依次亮灭）
- **dots** — 水平等宽文字行走点阵

**Props**:
- `mode` — `spinner` (default) / `pulse` / `dots`
- `size` — 尺寸
- `color` — 默认 `primary`

### 4.6 ScanLines (`widgets/scan_lines.dart`)

CRT 扫描线 overlay，极淡效果，通过 `AnimatedBuilder` 实现。

**Props**:
- `opacity` — 默认 0.03，可配置
- `enabled` — 默认 true

**注意**: 默认全局关闭，只作为可选装饰。用户可在 Settings 中开启。

---

## 5. 页面/组件改造

### 5.1 theme.dart

- 全部颜色常量替换为新色板
- 原有 `AppColors` 中保留不变的：`background` 类名重构，移除 iOS 风格色值
- `buildDarkTheme()` 更新：
  - `colorScheme` 指向新色板
  - `inputDecorationTheme` 聚焦边框发光
  - `elevatedButtonTheme` 霓虹青背景 + 发光阴影
  - `appBarTheme` 底部增加 1px 霓虹发光分割线

### 5.2 themed_text.dart

增加 factory `ThemedText.mono()` — 等宽体辅助文字：

```dart
factory ThemedText.mono(String data, {Color? color, int? maxLines}) =>
    ThemedText(data, fontSize: 12, fontFamily: 'monospace', color: color ?? AppColors.textSecondary, maxLines: maxLines);
```

### 5.3 main_shell.dart (Bottom Tab Bar)

- 选中 Tab 图标改用 `primary` 霓虹青
- 非选中白色（低不透明度）
- Tab Bar 顶部增加 1px `primary` 发光分割线
- 选中图标背后可选微型发光点

### 5.4 server_card.dart

- 替换 `Card` 为 `NeonCard`
- 名称用等宽体 `ThemedText.mono`
- URL 用 `ThemedText.mono` secondary 色
- 可选 `onDelete` 保留但改为霓虹红边框

### 5.5 session_card.dart

- 替换容器为 `NeonCard`
- Session cmd/args 全部等宽显示
- 状态替换为 `GlowBadge`
- Kill/Delete 按钮改霓虹风格
- 时间戳等宽文字

### 5.6 chat_timeline.dart

- 用户气泡：`primary` 背景 → 霓虹青
- 助手气泡：`surface` 背景 + `border` 边框
- Code block：`surfaceAlt` 背景 + `primary` 发光边框 + 等宽字体
- Status 行：左侧 `GlowBadge`
- Tool use 卡片：`surfaceAlt` 背景 + `border` 边框
- Divider：改用 `NeonDivider`

### 5.7 其他 screens

- **settings_screen.dart**：Section header 改用 `SectionHeader`，Manager 卡片 `NeonCard`
- **server_list_screen.dart**：Manager switcher 样式更新
- **login_screen.dart**：输入框聚焦发光，Connect 按钮霓虹青
- **server_sessions_screen.dart**：Filter pills 霓虹风格，skeleton 加载用 `NeonLoading`
- **session_detail_screen.dart**：AppBar 底部发光分割线

---

## 6. 动画规范

| 场景 | 效果 | 时长 | 说明 |
|---|---|---|---|
| 加载中 (整体) | `NeonLoading.spinner` | 持续 | 环状旋转，无停止 |
| 加载中 (局部) | `NeonLoading.pulse` | 持续 | 三脉冲点 |
| 输入框聚焦 | 边框呼吸发光 | 1.5s 循环 | `0.6 → 1.0 → 0.6` opacity |
| 状态变化 | 闪烁 → 稳定 | 300ms | 状态变更项短暂 `glow` 高亮后消退 |
| Card 点击 | 轻微缩放 | 100ms | `scale 1.0 → 0.97 → 1.0` |
| 刷新指示 | 旋转图标 | 持续 | 标准 Material RefreshIndicator 不变 |

所有动画遵循 `animation: 1` 无障碍设置，用户关闭动效时降级为无动画。

---

## 7. 性能考虑

- 发光效果使用 `Decoration` + `boxShadow` 实现，避免 `BackdropFilter`（GPU 开销大）
- `ScanLines` 默认禁用（`enabled: false`），用户手动在设置页开启
- 所有组件是 `StatelessWidget` 优先，动画组件使用 `AnimatedBuilder` 而非 `setState` 循环
- 不引入任何新图片资源或字体文件

---

## 8. 文件结构变更

```
lib/
  theme.dart                          # 修改：颜色常量+主题
  widgets/
    themed_text.dart                  # 修改：增加 mono factory
    neon_card.dart                    # 新增
    glow_badge.dart                   # 新增
    neon_divider.dart                 # 新增
    section_header.dart               # 新增
    neon_loading.dart                 # 新增
    scan_lines.dart                   # 新增
    main_shell.dart                   # 修改：底部 Tab 新样式
    server_card.dart                  # 修改：NeonCard + 等宽
    session_card.dart                 # 修改：NeonCard + GlowBadge + 等宽
    chat_timeline.dart                # 修改：新颜色 + 边框发光
    claude_chat_view.dart             # 修改：输入框聚焦发光
  screens/
    login_screen.dart                 # 微调：颜色引用
    server_list_screen.dart           # 微调：Manager switcher
    server_sessions_screen.dart       # 微调：Filter pills + 加载
    settings_screen.dart              # 微调：SectionHeader 替换
    session_detail_screen.dart        # 微调：AppBar
    server_add_screen.dart            # 微调：输入框
    create_session_screen.dart        # 微调：输入框
```
