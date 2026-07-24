import 'package:flutter/material.dart';

/// Cyberpunk 霓虹青紫风颜色体系
class AppColors {
  AppColors._();

  // ── 基础色板 ──────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0F); // 极黑底
  static const Color surface = Color(0xFF12121A); // 卡片/列表项
  static const Color surfaceAlt = Color(0xFF1A1A2E); // 选中态/高亮
  static const Color border = Color(0xFF2A2A4A); // 默认边框
  static const Color borderGlow = Color(0xFF3A3A6A); // 边框发光

  // ── 语义色板 ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF00F0FF); // 霓虹青
  static const Color secondary = Color(0xFFFF00FF); // 霓虹品红
  static const Color purple = Color(0xFF7B61FF); // 电紫
  static const Color success = Color(0xFF00FF41); // Matrix 绿
  static const Color warning = Color(0xFFFF6600); // 霓虹橙
  static const Color danger = Color(0xFFFF003C); // 霓虹红

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
    ),
    cardColor: AppColors.surface,
    dividerColor: AppColors.border,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.text, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.text, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      labelLarge: TextStyle(
        color: AppColors.text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
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
