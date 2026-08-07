import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme/app_colors.dart';
import 'package:tired_agent_app/theme/app_components.dart';

/// Material Design 3 主题 — 完全按 MD3 标准。
///
/// 用 [ColorScheme.fromSeed]（seed #6750A4 官方紫）生成完整 tonal palette，
/// 组件主题全部走 MD3 默认（Card/FilledButton/TextButton/IconButton/Dialog 等），
/// 不套用 neon 的组件主题覆盖。
ThemeData buildMd3DarkTheme() => _buildMd3(Brightness.dark);

ThemeData buildMd3LightTheme() => _buildMd3(Brightness.light);

ThemeData _buildMd3(Brightness b) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4), // MD3 官方紫
    brightness: b,
  );
  final c = AppColors.md3(scheme); // 与 colorScheme 同一份，token 一致
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    // 与 neon/geek 保持相近视觉尺度，避免切 material 后整 UI 放大
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textTheme: TextTheme(
      bodyLarge: const TextStyle(fontSize: 16),
      bodyMedium: const TextStyle(fontSize: 14),
      bodySmall: const TextStyle(fontSize: 12),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 48,
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    dialogTheme: DialogThemeData(
      contentTextStyle: const TextStyle(fontSize: 14),
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    extensions: [c, AppComponents.material],
  );
}
