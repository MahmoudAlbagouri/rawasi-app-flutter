// lib/core/themes/app_theme.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

class AppTheme {
  // ✅ Theme فاتح
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.brandPrimary,
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.gray800,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.brandSecondary,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.gray800),
      bodyMedium: TextStyle(color: AppColors.gray700),
      bodySmall: TextStyle(color: AppColors.gray600),
      titleLarge: TextStyle(
        color: AppColors.brandSecondary,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.brandPrimary,
      secondary: AppColors.brandSecondary,
      background: AppColors.white,
      surface: AppColors.white,
      error: AppColors.brandError,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onBackground: AppColors.gray900,
      onSurface: AppColors.gray800,
      onError: AppColors.white,
    ),
  );

  // ⚫️ Theme داكن (اختياري - يمكنك تفعيله لاحقًا)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.brandPrimary,
    scaffoldBackgroundColor: AppColors.gray900,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.gray900,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColors.gray200),
      bodyMedium: TextStyle(color: AppColors.gray300),
      bodySmall: TextStyle(color: AppColors.gray400),
      titleLarge: TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColors.brandPrimary,
      secondary: AppColors.brandSecondary,
      background: AppColors.gray900,
      surface: AppColors.gray800,
      error: AppColors.brandError,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onBackground: AppColors.gray100,
      onSurface: AppColors.gray200,
      onError: AppColors.white,
    ),
  );
}
