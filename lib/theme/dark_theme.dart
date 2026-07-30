import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme/app_colors.dart';

ThemeData buildDarkTheme() {
  final c = AppColors.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: c.primary,
      onPrimary: c.text,
      primaryContainer: c.surfaceAlt,
      onPrimaryContainer: c.primary,
      secondary: c.secondary,
      onSecondary: c.text,
      secondaryContainer: c.surfaceAlt,
      onSecondaryContainer: c.secondary,
      tertiary: c.purple,
      onTertiary: c.text,
      surface: c.surface,
      surfaceContainerHighest: c.surfaceAlt,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      error: c.danger,
      onError: c.text,
      outline: c.border,
      outlineVariant: c.borderGlow,
      inverseSurface: c.text,
      onInverseSurface: c.background,
      inversePrimary: const Color(0xFF00838F),
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
          side: BorderSide(color: c.primary.withAlpha(80), width: 0.5),
        ),
        shadowColor: c.primary.withAlpha(25),
        elevation: 1,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.surface,
      contentTextStyle: TextStyle(color: c.text, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        side: BorderSide(color: c.border.withAlpha(60), width: 0.5),
      ),
      actionTextColor: c.primary,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.one),
      ),
      textStyle: TextStyle(color: c.text, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        side: BorderSide(color: c.border, width: 0.5),
      ),
      textStyle: TextStyle(color: c.text, fontSize: 14),
    ),
  );
}
