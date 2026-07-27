import 'package:flutter/material.dart';

/// Cyberpunk 霓虹青紫风颜色体系 — ThemeExtension
///
/// 通过 `Theme.of(context).extension<AppColors>()!` 或
/// `context.appColors`（需 `import 'theme.dart'`）访问。
class AppColors extends ThemeExtension<AppColors> {
  // ── 基础色板 ──────────────────────────────────────────────────
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderGlow;

  // ── 语义色板 ──────────────────────────────────────────────────
  final Color primary;
  final Color secondary;
  final Color purple;
  final Color success;
  final Color warning;
  final Color danger;

  // ── 文字色板 ──────────────────────────────────────────────────
  final Color text;
  final Color textSecondary;
  final Color textCode;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderGlow,
    required this.primary,
    required this.secondary,
    required this.purple,
    required this.success,
    required this.warning,
    required this.danger,
    required this.text,
    required this.textSecondary,
    required this.textCode,
  });

  // ── 语义别名（向后兼容旧代码引用，迁移完成后可删除） ────────────
  Color get accent => primary;
  Color get accentLight => primary;
  Color get backgroundElement => surface;
  Color get codeBackground => surfaceAlt;
  Color get toolBackground => surfaceAlt;

  // ── 暗色主题实例 ──────────────────────────────────────────────
  static const dark = AppColors(
    // ── 基础色板 ──────────────────────────────────────────────
    background: Color(0xFF0A0A0F), // 极黑底
    surface: Color(0xFF12121A), // 卡片/列表项
    surfaceAlt: Color(0xFF1A1A2E), // 选中态/高亮
    border: Color(0xFF2A2A4A), // 默认边框
    borderGlow: Color(0xFF3A3A6A), // 边框发光
    // ── 语义色板 ──────────────────────────────────────────────
    primary: Color(0xFF00F0FF), // 霓虹青
    secondary: Color(0xFFFF00FF), // 霓虹品红
    purple: Color(0xFF7B61FF), // 电紫
    success: Color(0xFF00FF41), // Matrix 绿
    warning: Color(0xFFFF6600), // 霓虹橙
    danger: Color(0xFFFF003C), // 霓虹红
    // ── 文字色板 ──────────────────────────────────────────────
    text: Color(0xFFE8E8F0),
    textSecondary: Color(0xFF7878A0),
    textCode: Color(0xFFB8B8C0),
  );

  // ── 亮色主题实例 ──────────────────────────────────────────────
  static const light = AppColors(
    // ── 基础色板 ──────────────────────────────────────────────
    background: Color(0xFFF0F0F5), // 浅灰紫底
    surface: Color(0xFFFFFFFF), // 纯白卡片
    surfaceAlt: Color(0xFFE8E8F0), // 浅灰高亮
    border: Color(0xFFD0D0E0), // 浅边框
    borderGlow: Color(0xFFB8B8C8), // 浅发光
    // ── 语义色板 ──────────────────────────────────────────────
    primary: Color(0xFF0098A8), // 更深青（白底可读）
    secondary: Color(0xFFCC00CC), // 更深品红
    purple: Color(0xFF6B51E0), // 更深紫
    success: Color(0xFF00AA30), // 更深绿
    warning: Color(0xFFCC5500), // 更深橙
    danger: Color(0xFFCC0030), // 更深红
    // ── 文字色板 ──────────────────────────────────────────────
    text: Color(0xFF1A1A2E), // 深色文字
    textSecondary: Color(0xFF6A6A8A), // 次级文字
    textCode: Color(0xFF2A2A3E), // 代码文字
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? borderGlow,
    Color? primary,
    Color? secondary,
    Color? purple,
    Color? success,
    Color? warning,
    Color? danger,
    Color? text,
    Color? textSecondary,
    Color? textCode,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      borderGlow: borderGlow ?? this.borderGlow,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      purple: purple ?? this.purple,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textCode: textCode ?? this.textCode,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderGlow: Color.lerp(borderGlow, other.borderGlow, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textCode: Color.lerp(textCode, other.textCode, t)!,
    );
  }
}

/// 便捷扩展：`Theme.of(context).appColors` 访问 AppColors
extension AppColorsX on ThemeData {
  AppColors get appColors => extension<AppColors>()!;
}

/// 便捷扩展：`context.appColors` 在 build 方法中直接访问
extension BuildContextAppColors on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

// ══════════════════════════════════════════════════════════════════════
//  AppSpacing
// ══════════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════════
//  Theme builders
// ══════════════════════════════════════════════════════════════════════

ThemeData buildDarkTheme() {
  final c = AppColors.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: c.primary,
      secondary: c.secondary,
      surface: c.surface,
      error: c.danger,
      onPrimary: c.text,
      onSecondary: c.text,
      onSurface: c.text,
      onError: c.text,
    ),
    scaffoldBackgroundColor: c.background,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: c.surface,
    dividerColor: c.border,
    extensions: [AppColors.dark],
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: c.text, fontSize: 16),
      bodyMedium: TextStyle(color: c.text, fontSize: 14),
      bodySmall: TextStyle(color: c.textSecondary, fontSize: 12),
      labelLarge: TextStyle(
        color: c.text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: c.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: c.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.primary, width: 1),
      ),
      hintStyle: TextStyle(color: c.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.surfaceAlt,
        foregroundColor: c.primary,
        disabledBackgroundColor: c.border,
        disabledForegroundColor: c.textSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.four,
          vertical: AppSpacing.three,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.two),
          side: BorderSide(
            color: c.primary.withAlpha(80),
            width: 0.5,
          ),
        ),
        shadowColor: c.primary.withAlpha(25),
        elevation: 1,
      ),
    ),
  );
}

ThemeData buildLightTheme() {
  final c = AppColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: c.primary,
      secondary: c.secondary,
      surface: c.surface,
      error: c.danger,
      onPrimary: c.text,
      onSecondary: c.text,
      onSurface: c.text,
      onError: c.text,
    ),
    scaffoldBackgroundColor: c.background,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: c.surface,
    dividerColor: c.border,
    extensions: [AppColors.light],
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: c.text, fontSize: 16),
      bodyMedium: TextStyle(color: c.text, fontSize: 14),
      bodySmall: TextStyle(color: c.textSecondary, fontSize: 12),
      labelLarge: TextStyle(
        color: c.text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: c.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: c.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide(color: c.primary, width: 1),
      ),
      hintStyle: TextStyle(color: c.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.surfaceAlt,
        foregroundColor: c.primary,
        disabledBackgroundColor: c.border,
        disabledForegroundColor: c.textSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.four,
          vertical: AppSpacing.three,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.two),
          side: BorderSide(
            color: c.primary.withAlpha(80),
            width: 0.5,
          ),
        ),
        shadowColor: c.primary.withAlpha(25),
        elevation: 1,
      ),
    ),
  );
}
