import 'package:flutter/material.dart';

/// Dark theme for tiredAgentMobile.
/// Matches the original Expo app's `Colors.dark` palette.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF1C1C1E);
  static const Color backgroundElement = Color(0xFF2C2C2E);
  static const Color text = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color accent = Color(0xFF208AEF);
  static const Color accentLight = Color(0xFF64B5F6);
  static const Color danger = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightText = Color(0xFF1C1C1E);
  static const Color lightBackgroundSelected = Color(0xFF007AFF);
  static const Color codeBackground = Color(0xFF212225);
  static const Color toolBackground = Color(0xFF1C2330);
  static const Color bubbleUser = Color(0xFF007AFF);
  static const Color bubbleAssistant = Color(0xFF2C2C2E);
}

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
      primary: AppColors.accent,
      secondary: AppColors.accentLight,
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
    cardColor: AppColors.backgroundElement,
    dividerColor: AppColors.backgroundElement,
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
      fillColor: AppColors.backgroundElement,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.two),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.three,
        vertical: AppSpacing.two,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.text,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.four,
          vertical: AppSpacing.three,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.two),
        ),
      ),
    ),
  );
}
