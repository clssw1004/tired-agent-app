# Cyberpunk 霓虹风 — App 样式改造 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 App 整体视觉风格从 iOS 深色主题改造为 Cyberpunk 青紫霓虹风，封装 6 个可复用通用组件

**Architecture:** 从主题层（色板）→ 组件层（新 Widgets）→ 集成层（更新现有 Widgets/Screens），分层推进，每层完成后 `dart analyze` 验证

**Tech Stack:** Flutter (Dart), Material3, provider, go_router

**分支:** `feat/cyberpunk-redesign-20260724`

---

## 文件变更清单

### 新建文件（6）

| 文件 | 职责 |
|---|---|
| `lib/widgets/neon_card.dart` | 暗色卡片容器，可选发光边框 |
| `lib/widgets/glow_badge.dart` | 状态标签（绿/黄/红 发光圆点 + 文字） |
| `lib/widgets/neon_divider.dart` | 分割线 + 可选标题 + 两侧发光装饰条 |
| `lib/widgets/section_header.dart` | 节标题，左侧 3px 霓虹发光竖条 |
| `lib/widgets/neon_loading.dart` | 霓虹风格加载器（旋转环/脉冲点阵/行走点） |
| `lib/widgets/scan_lines.dart` | CRT 扫描线 overlay（极淡，默认关闭） |

### 修改文件（13）

| 文件 | 改动 |
|---|---|
| `lib/theme.dart` | 替换全部颜色常量 + 更新 buildDarkTheme |
| `lib/widgets/themed_text.dart` | 增加 `mono` factory |
| `lib/widgets/main_shell.dart` | TabBar 霓虹风格 |
| `lib/widgets/server_card.dart` | NeonCard + GlowBadge + 等宽 |
| `lib/widgets/session_card.dart` | NeonCard + GlowBadge + 等宽 |
| `lib/widgets/chat_timeline.dart` | 新色板 + 发光边框 |
| `lib/widgets/claude_chat_view.dart` | 输入框聚焦发光 |
| `lib/screens/login_screen.dart` | 颜色引用更新 |
| `lib/screens/server_list_screen.dart` | Manager 选择器样式更新 |
| `lib/screens/server_sessions_screen.dart` | Filter pills + SectionHeader |
| `lib/screens/settings_screen.dart` | SectionHeader 替换 |
| `lib/screens/server_add_screen.dart` | 输入框样式更新 |
| `lib/screens/create_session_screen.dart` | 输入框 + 预设按钮样式更新 |

---

## Task 分组与提交策略

4 次提交（每次独立可编译 + `dart analyze` 无错）：

| # | 提交信息 | 内容 |
|---|---|---|
| 1 | `feat: Cyberpunk 色板 + ThemedText.mono` | theme.dart + themed_text.dart |
| 2 | `feat: 新增 6 个通用 Neon 组件` | neon_card, glow_badge, neon_divider, section_header, neon_loading, scan_lines |
| 3 | `feat: 更新现有 Widgets — 卡片/TabBar/聊天/输入框` | main_shell, server_card, session_card, chat_timeline, claude_chat_view |
| 4 | `feat: 更新所有页面样式引用` | 全部 screens + toast_overlay |

---

### Task 1: Cyberpunk 色板 + ThemedText.mono

**Files:**
- Modify: `lib/theme.dart`
- Modify: `lib/widgets/themed_text.dart`

- [ ] **Step 1: 替换 theme.dart 颜色常量**

将全部颜色替换为新 Cyberpunk 色板。保留 `AppSpacing` 不变。

```dart
// lib/theme.dart — 完整替换内容

import 'package:flutter/material.dart';

/// Cyberpunk 霓虹青紫风颜色体系
class AppColors {
  AppColors._();

  // ── 基础色板 ──────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0F);     // 极黑底
  static const Color surface = Color(0xFF12121A);         // 卡片/列表项
  static const Color surfaceAlt = Color(0xFF1A1A2E);      // 选中态/高亮
  static const Color border = Color(0xFF2A2A4A);          // 默认边框
  static const Color borderGlow = Color(0xFF3A3A6A);      // 边框发光

  // ── 语义色板 ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF00F0FF);          // 霓虹青
  static const Color secondary = Color(0xFFFF00FF);        // 霓虹品红
  static const Color purple = Color(0xFF7B61FF);           // 电紫
  static const Color success = Color(0xFF00FF41);          // Matrix 绿
  static const Color warning = Color(0xFFFF6600);          // 霓虹橙
  static const Color danger = Color(0xFFFF003C);           // 霓虹红

  // ── 文字色板 ──────────────────────────────────────────────────
  static const Color text = Color(0xFFE8E8F0);
  static const Color textSecondary = Color(0xFF7878A0);
  static const Color textCode = Color(0xFFB8B8C0);

  // ── 语义别名（向后兼容旧代码引用） ─────────────────────────────
  /// 旧 AppColors.accent → 新 AppColors.primary
  static const Color accent = primary;
  /// 旧 AppColors.accentLight → 新 AppColors.primary（无 light 变体）
  static const Color accentLight = primary;
  /// 旧 AppColors.backgroundElement → 新 AppColors.surface
  static const Color backgroundElement = surface;
  /// 旧 AppColors.codeBackground → 新 AppColors.surfaceAlt
  static const Color codeBackground = surfaceAlt;
  /// 旧 AppColors.toolBackground → 新 AppColors.surfaceAlt
  static const Color toolBackground = surfaceAlt;
  /// 旧 AppColors.lightBackground / lightText / lightBackgroundSelected — 移除（不用亮色模式）
}

// AppSpacing 不变
class AppSpacing {
  AppSpacing._();
  static const double one = 4.0;
  static const double two = 8.0;
  static const double three = 12.0;
  static const double four = 16.0;
  static const double five = 20.0;
  static const double six = 24.0;
  static const double seven = 28.0;
  static const double eight = 32.0;
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.background,
      error: AppColors.danger,
      onPrimary: AppColors.text,
      onSecondary: AppColors.text,
      onSurface: AppColors.text,
      onError: AppColors.text,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.primary, thickness: 0.5),
      ),
    ),
    cardColor: AppColors.surface,
    dividerColor: AppColors.border,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.text, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.text, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      labelLarge: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.four,
          vertical: AppSpacing.three,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.two),
        ),
        shadowColor: AppColors.primary.withAlpha(60),
        elevation: 2,
      ),
    ),
  );
}
```

- [ ] **Step 2: dart analyze 验证**

```bash
cd C:\wspec\tired_agent_app && dart analyze lib/theme.dart
```
预期：0 errors, 0 warnings（旧颜色别名兼容性良好）

- [ ] **Step 3: 修改 themed_text.dart** — 增加 `mono` factory

在 `class ThemedText` 中，`title` factory 之后增加：

```dart
factory ThemedText.mono(String data, {Key? key, Color? color, int? maxLines, TextOverflow? overflow}) =>
    ThemedText(data, key: key, color: color ?? AppColors.textCode, fontSize: 12, fontFamily: 'monospace', maxLines: maxLines, overflow: overflow);

factory ThemedText.label(String data, {Key? key, Color? color}) =>
    ThemedText(data, key: key, color: color ?? AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w500);
```

- [ ] **Step 4: dart analyze 验证**

```bash
cd C:\wspec\tired_agent_app && dart analyze lib/widgets/themed_text.dart
```
预期：0 errors, 0 warnings

- [ ] **Step 5: 提交**

```bash
cd C:\wspec\tired_agent_app && git add lib/theme.dart lib/widgets/themed_text.dart && git commit -m "feat: Cyberpunk 色板 + ThemedText.mono/label"
```

---

### Task 2: 新增 6 个通用 Neon 组件

**Files:**
- Create: `lib/widgets/neon_card.dart`
- Create: `lib/widgets/glow_badge.dart`
- Create: `lib/widgets/neon_divider.dart`
- Create: `lib/widgets/section_header.dart`
- Create: `lib/widgets/neon_loading.dart`
- Create: `lib/widgets/scan_lines.dart`

#### 2a: neon_card.dart

```dart
import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';

/// Cyberpunk 风格暗色卡片容器。
/// 默认无边框（surface 背景），传入 [borderColor] 显示霓虹边框。
/// [glow] 为 true 时启用 boxShadow 发光效果。
class NeonCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final bool glow;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const NeonCard({
    super.key,
    required this.child,
    this.borderColor,
    this.glow = false,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = AppSpacing.two,
  });

  @override
  Widget build(BuildContext context) {
    final hasBorder = borderColor != null;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.three),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: hasBorder
                  ? Border.all(color: borderColor!, width: 1)
                  : Border.all(color: AppColors.border.withAlpha(60), width: 0.5),
              boxShadow: glow && hasBorder
                  ? [BoxShadow(color: borderColor!.withAlpha(40), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

#### 2b: glow_badge.dart

```dart
import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';

/// 状态发光指示器：圆点 + 文字。
/// 自动匹配 running→绿色, starting→橙色, exited→灰色, connected→绿色, disconnected→灰色。
enum BadgeStatus { running, starting, exited, error, connected, disconnected }

class GlowBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? label;
  final bool glow;

  const GlowBadge({
    super.key,
    required this.status,
    this.label,
    this.glow = true,
  });

  Color get _color => switch (status) {
    BadgeStatus.running => AppColors.success,
    BadgeStatus.connected => AppColors.success,
    BadgeStatus.starting => AppColors.warning,
    BadgeStatus.error => AppColors.danger,
    BadgeStatus.exited => AppColors.textSecondary,
    BadgeStatus.disconnected => AppColors.textSecondary,
  };

  String get _defaultLabel => switch (status) {
    BadgeStatus.running => 'Running',
    BadgeStatus.connected => 'Connected',
    BadgeStatus.starting => 'Starting',
    BadgeStatus.error => 'Error',
    BadgeStatus.exited => 'Exited',
    BadgeStatus.disconnected => 'Disconnected',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppSpacing.one),
        border: Border.all(color: _color.withAlpha(60), width: 0.5),
        boxShadow: glow
            ? [BoxShadow(color: _color.withAlpha(30), blurRadius: 6, spreadRadius: 0)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              boxShadow: glow
                  ? [BoxShadow(color: _color.withAlpha(80), blurRadius: 4, spreadRadius: 1)]
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.one + 2),
          ThemedText.label(label ?? _defaultLabel, color: _color),
        ],
      ),
    );
  }
}
```

#### 2c: neon_divider.dart

```dart
import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// 霓虹风格分割线。可选 [label] 显示居中标段文字。
class NeonDivider extends StatelessWidget {
  final String? label;
  final Color color;

  const NeonDivider({super.key, this.label, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.two),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(0), color.withAlpha(80), color.withAlpha(0)],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(0), color.withAlpha(60)],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two),
          child: ThemedText.label(label!, color: color.withAlpha(180)),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(60), color.withAlpha(0)],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

#### 2d: section_header.dart

```dart
import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// 节标题：左侧 3px 霓虹竖条 + 等宽大写文字。
class SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const SectionHeader({super.key, required this.label, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
            boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 4, spreadRadius: 0)],
          ),
        ),
        const SizedBox(width: AppSpacing.two),
        ThemedText.label(label.toUpperCase(), color: color),
      ],
    );
  }
}
```

#### 2e: neon_loading.dart

```dart
import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';

enum NeonLoadingMode { spinner, pulse, dots }

/// 霓虹风格加载指示器。
class NeonLoading extends StatefulWidget {
  final NeonLoadingMode mode;
  final double size;
  final Color color;

  const NeonLoading({
    super.key,
    this.mode = NeonLoadingMode.spinner,
    this.size = 24,
    this.color = AppColors.primary,
  });

  @override
  State<NeonLoading> createState() => _NeonLoadingState();
}

class _NeonLoadingState extends State<NeonLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.mode) {
      NeonLoadingMode.spinner => _buildSpinner(),
      NeonLoadingMode.pulse => _buildPulse(),
      NeonLoadingMode.dots => _buildDots(),
    };
  }

  Widget _buildSpinner() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 2 * pi,
        child: child,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(widget.color),
        ),
      ),
    );
  }

  Widget _buildPulse() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_controller.value * 3 + i) % 3;
          final opacity = sin(phase * pi).clamp(0.3, 1.0);
          return Padding(
            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
            child: Container(
              width: widget.size * 0.35,
              height: widget.size * 0.35,
              decoration: BoxDecoration(
                color: widget.color.withAlpha((opacity * 255).toInt()),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: widget.color.withAlpha(60), blurRadius: 4, spreadRadius: 0),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final count = (_controller.value * 8).floor() % 4 + 1;
        return ThemedText.mono(
          '${'·' * count}${' ' * (4 - count)}',
          color: widget.color,
        );
      },
    );
  }
}
```

#### 2f: scan_lines.dart

```dart
import 'package:flutter/material.dart';

/// CRT 扫描线效果 overlay。
/// 默认 [enabled] = false，需要在 Settings 中手动开启。
/// 使用 CustomPainter 绘制，无性能开销。
class ScanLines extends StatelessWidget {
  final double opacity;
  final bool enabled;

  const ScanLines({super.key, this.opacity = 0.03, this.enabled = false});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return IgnorePointer(
      child: Positioned.fill(
        child: CustomPaint(
          painter: _ScanLinePainter(opacity: opacity),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double opacity;

  _ScanLinePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha((opacity * 255).toInt())
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) => old.opacity != opacity;
}
```

- [ ] **Step: dart analyze 全部新文件**

```bash
cd C:\wspec\tired_agent_app && dart analyze lib/widgets/neon_card.dart lib/widgets/glow_badge.dart lib/widgets/neon_divider.dart lib/widgets/section_header.dart lib/widgets/neon_loading.dart lib/widgets/scan_lines.dart
```
预期：0 errors, 0 warnings

- [ ] **Step: 提交**

```bash
cd C:\wspec\tired_agent_app && git add lib/widgets/neon_card.dart lib/widgets/glow_badge.dart lib/widgets/neon_divider.dart lib/widgets/section_header.dart lib/widgets/neon_loading.dart lib/widgets/scan_lines.dart && git commit -m "feat: 新增 6 个通用 Neon 组件"
```

---

### Task 3: 更新现有 Widgets

- [ ] **Step 1: 更新 main_shell.dart** — TabBar 霓虹风格

修改 `BottomNavigationBar` 部分：

```dart
// 替换 Container decoration 和 BottomNavigationBar 的内容
// 主要变更：
// 1. Border top 改为 primary 发光
// 2. selectedItemColor = AppColors.primary
// 3. unselectedItemColor = AppColors.textSecondary

child: BottomNavigationBar(
  backgroundColor: AppColors.background,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textSecondary,
  type: BottomNavigationBarType.fixed,
  currentIndex: navigationShell.currentIndex,
  onTap: (index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dns_outlined),
      activeIcon: Icon(Icons.dns),
      label: 'Servers',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ],
),
```

同时更新顶部 border：

```dart
decoration: const BoxDecoration(
  border: Border(
    top: BorderSide(color: AppColors.primary, width: 0.5),
  ),
),
```

- [ ] **Step 2: 更新 server_card.dart**

```dart
// 完整替换文件
import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/neon_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class ServerCard extends StatelessWidget {
  final AgentInfo agent;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ServerCard({
    super.key,
    required this.agent,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.one),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedText.mono(agent.name),
                const SizedBox(height: 2),
                ThemedText.mono(agent.baseUrl, color: AppColors.textSecondary),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 更新 session_card.dart**

将 `Card` + 手动样式替换为 `NeonCard` + `GlowBadge` + 等宽文字。

关键修改点：
- 替换外层 `Card(color: AppColors.backgroundElement, ...)` 为 `NeonCard`
- 状态 badge 替换为 `GlowBadge`
- cmd/args/pid/exit 使用 `ThemedText.mono`
- Kill/Delete 按钮保持原有风格，但文字用 `ThemedText.mono`
- 移除 `_statusColor` / `_statusLabel` 方法（由 GlowBadge 替代）

代码变更（主 build 方法关键部分）：

```dart
// 替换 _statusColor / _statusLabel 为 GlowBadge
// Row 中状态 badge 替换为：
GlowBadge(
  status: switch (session.status) {
    SessionStatus.running => BadgeStatus.running,
    SessionStatus.starting => BadgeStatus.starting,
    SessionStatus.exited => BadgeStatus.exited,
  },
)

// 替换 ThemedText.body(cmd) 为 ThemedText.mono(cmd)
// 替换 ThemedText.small(time) 为 ThemedText.mono(time, color: AppColors.textSecondary)
// 模式名称用 ThemedText.mono(mode.name)
```

完整文件替换（保持 _ActionButton 辅助类，仅修改 build 和类型引用）：

```dart
// lib/widgets/session_card.dart 完整替换
import 'package:flutter/material.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/glow_badge.dart';
import 'package:tired_agent_app/widgets/neon_card.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback? onKill;
  final VoidCallback? onDelete;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onKill,
    this.onDelete,
  });

  String _timeSince(int ts) {
    final s = DateTime.now().millisecondsSinceEpoch - ts;
    if (s < 60000) return '${s ~/ 1000}s ago';
    if (s < 3600000) return '${s ~/ 60000}m ago';
    if (s < 86400000) return '${s ~/ 3600000}h ago';
    return '${s ~/ 86400000}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.one),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + status badge
          Row(
            children: [
              Expanded(
                child: ThemedText.mono(session.label ?? session.cmd),
              ),
              GlowBadge(
                status: switch (session.status) {
                  SessionStatus.running => BadgeStatus.running,
                  SessionStatus.starting => BadgeStatus.starting,
                  SessionStatus.exited => BadgeStatus.exited,
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.one),
          // Subtitle: cmd args · pid/exit
          ThemedText.mono(
            () {
              final cmd = [session.cmd, ...session.args].join(' ');
              if (session.status == SessionStatus.exited) {
                final exitInfo = 'exit ${session.exitCode ?? '?'}';
                final ago = session.exitedAt != null ? ' · ${_timeSince(session.exitedAt!)}' : '';
                return '$cmd · $exitInfo$ago';
              }
              return '$cmd · pid ${session.pid ?? '?'}';
            }(),
            color: AppColors.textSecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Mode badge + action buttons
          if (session.mode != null) ...[
            const SizedBox(height: AppSpacing.two),
            Row(
              children: [
                _ModeBadge(mode: session.mode!),
                const Spacer(),
                if (session.mode == SessionMode.persistent && onKill != null)
                  _ActionButton(icon: '⏹', label: 'Kill', color: AppColors.danger, onTap: onKill!),
                if (session.status == SessionStatus.exited && onDelete != null)
                  _ActionButton(icon: '🗑', label: 'Delete', color: AppColors.textSecondary, onTap: onDelete!),
              ],
            ),
          ],
          if (session.mode == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.two),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (session.status != SessionStatus.exited && onKill != null)
                    _ActionButton(icon: '⏹', label: 'Kill', color: AppColors.danger, onTap: onKill!),
                  if (session.status == SessionStatus.exited && onDelete != null)
                    _ActionButton(icon: '🗑', label: 'Delete', color: AppColors.textSecondary, onTap: onDelete!),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final SessionMode mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(AppSpacing.one),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: ThemedText.mono(mode.name, color: AppColors.primary),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.two, vertical: AppSpacing.one),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(70)),
          borderRadius: BorderRadius.circular(AppSpacing.one),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedText(icon, fontSize: 12),
            const SizedBox(width: 4),
            ThemedText.mono(label, color: color),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 更新 chat_timeline.dart**

关键修改：
- 用户气泡背景：`AppColors.accent` → `AppColors.primary`
- 助手气泡：`AppColors.backgroundElement` → `AppColors.surface` + 添加 `border: Border.all(color: AppColors.border.withAlpha(60), width: 0.5)`
- Code block：添加 `border: Border.all(color: AppColors.primary.withAlpha(30))`
- Status Divider：改用 `NeonDivider`

注意：`_MessageBubble` 中代码块原有的 `Container` 增加边框：

```dart
ContentCode(:final code) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(AppSpacing.three),
  decoration: BoxDecoration(
    color: AppColors.surfaceAlt,
    borderRadius: BorderRadius.circular(AppSpacing.two),
    border: Border.all(color: AppColors.primary.withAlpha(25)),
  ),
  child: SelectableText(
    code,
    style: const TextStyle(color: AppColors.textCode, fontSize: 12, fontFamily: 'monospace'),
  ),
),
```

更多变更：
- `ContentText` 气泡（助手）：增加灰色边框
- `ContentToolUse` 背景色改为 `AppColors.surfaceAlt` + 边框
- Divider 行改用 `NeonDivider(label: label)`
- 文字颜色 `textSecondary` 保持不变（已映射）
- status icon 颜色改用新色板

- [ ] **Step 5: 更新 claude_chat_view.dart**

主要修改输入框底部区域：
- Border top 改为 `AppColors.border`
- Send 按钮的 disabled 样式更新

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.background,
    border: Border(top: BorderSide(color: AppColors.border)),
  ),
  padding: const EdgeInsets.fromLTRB(AppSpacing.three, AppSpacing.two, AppSpacing.three, AppSpacing.two),
  child: SafeArea(
    top: false,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            maxLines: 4,
            minLines: 1,
            enabled: !_sending,
            decoration: const InputDecoration(
              hintText: 'Type a message…',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.three,
                vertical: AppSpacing.two,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.two),
        ElevatedButton(
          onPressed: (_inputController.text.trim().isEmpty || _sending) ? null : _send,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.three,
              vertical: AppSpacing.two,
            ),
          ),
          child: ThemedText.mono('Send'),
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 6: `dart analyze` 全部修改过的 widgets**

```bash
cd C:\wspec\tired_agent_app && dart analyze lib/widgets/main_shell.dart lib/widgets/server_card.dart lib/widgets/session_card.dart lib/widgets/chat_timeline.dart lib/widgets/claude_chat_view.dart
```

预期：0 errors, 0 warnings

- [ ] **Step 7: 提交**

```bash
cd C:\wspec\tired_agent_app && git add lib/widgets/main_shell.dart lib/widgets/server_card.dart lib/widgets/session_card.dart lib/widgets/chat_timeline.dart lib/widgets/claude_chat_view.dart && git commit -m "feat: 更新现有 Widgets — 卡片/TabBar/聊天/输入框"
```

---

### Task 4: 更新所有页面样式引用

所有 screens 文件中的颜色引用通过 `AppColors` 语义别名自动兼容。需要手动检查的修改：

- [ ] **Step 1: 检查 login_screen.dart**

`AppColors.accent` → `AppColors.primary`（别名已兼容，无需修改）。
`AppColors.backgroundElement` → `AppColors.surface`（别名兼容）。
`CircularProgressIndicator` 可替换为 `NeonLoading.spinner`：

```dart
// 替换 loading spinner
// 原：
const SizedBox(
  width: 20,
  height: 20,
  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.text),
)
// 改：
const NeonLoading(size: 20),
```

- [ ] **Step 2: 检查 server_list_screen.dart**

Manager 选择器底部 sheet 颜色和图标保持不变（使用别名）。切换器 active dot 颜色使用 `AppColors.primary`。

- [ ] **Step 3: 更新 server_sessions_screen.dart**

- Filter pills 选中色：`AppColors.accent` → `AppColors.primary`（别名兼容）
- 加载 skeleton → 改用 `NeonLoading`
- 确认对话框背景色：`AppColors.backgroundElement` → 别名兼容
- "Clean zombies" 按钮：border 颜色更新
- Skeleton 占位符颜色从 `Color(0xFF3A3A3C)` 改为 `AppColors.surfaceAlt`

- [ ] **Step 4: 更新 settings_screen.dart**

- 使用 `SectionHeader` 替换手动 _SectionHeader widget（直接删除现有 _SectionHeader 类，全局引用替换）
- ManagerCard 选中边框颜色 `AppColors.accent` → `AppColors.primary`（别名兼容）
- 确认对话框背景色别名兼容

操作：

```dart
// 1. 导入 SectionHeader
import 'package:tired_agent_app/widgets/section_header.dart';

// 2. 替换 _SectionHeader 使用处
// 原：_SectionHeader(label: 'Managers (${auth.profiles.length})')
// 改：SectionHeader(label: 'Managers (${auth.profiles.length})')

// 3. 删除 _SectionHeader class 定义
```

- [ ] **Step 5: 更新 session_detail_screen.dart**

AppBar 底部发光分割线由 theme.dart 中 `AppBarTheme.bottom` 自动提供，无需手动修改。

Loading spinner 可替换为 `NeonLoading`：

```dart
// 改前：
const Center(child: CircularProgressIndicator())
// 改后：
const Center(child: NeonLoading())
```

- [ ] **Step 6: 更新 server_add_screen.dart**

输入框样式由 theme.dart 的 `inputDecorationTheme` 自动应用新颜色。
Loading spinner 替换：

```dart
// 原：
const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
// 改为：
const NeonLoading(size: 20),
```

- [ ] **Step 7: 更新 create_session_screen.dart**

- 预设按钮选中色：`AppColors.accent` → `AppColors.primary`（别名兼容，但 better to use primary directly）
- 输入框等宽字体内联 `const TextStyle(fontFamily: 'monospace', color: AppColors.text)` 改为 `const TextStyle(fontFamily: 'monospace', color: AppColors.textCode)`
- Lifecycle mode 选中边框色保持 `AppColors.accent` → 别名兼容
- 加载 spinner 替换
- "Quick start" / "Lifecycle" 等节标题改为使用 `SectionHeader` 或保持原样（原用 `ThemedText.small`）
- 预设 emoji 按钮默认色 `AppColors.backgroundElement` → 别名兼容

- [ ] **Step 8: 更新 toast_overlay.dart**

Toast 背景色：info 类型的 `AppColors.backgroundElement` → 别名兼容。

- [ ] **Step 9: `dart analyze` 全面验证**

```bash
cd C:\wspec\tired_agent_app && dart analyze lib/
```

预期：0 errors, 0 warnings（旧颜色别名确保兼容性，新 API 使用正确）

- [ ] **Step 10: 最终提交**

```bash
cd C:\wspec\tired_agent_app && git add -A && git commit -m "feat: 更新所有页面样式引用"
```

---

## 验证清单

| 检查项 | 命令 | 预期 |
|---|---|---|
| Dart 静态分析 | `dart analyze lib/` | 0 errors, 0 warnings |
| 格式化 | `dart format --set-exit-if-changed lib/` | 无变更 |
| 构建 | `flutter build apk --debug` | 编译成功 |
| 分支状态 | `git log --oneline` | 4 次提交 |

## 回退方案

如构建失败或视觉效果不满意：

```bash
git checkout main
git branch -D feat/cyberpunk-redesign-20260724
```

Back to square one from clean main.
