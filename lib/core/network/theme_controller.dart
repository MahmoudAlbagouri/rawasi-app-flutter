// lib/core/services/theme_controller.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeController() {
    _loadFromPrefs(); // ⚠️ تم إزالة await لأننا لا نستطيع استخدام async في constructor
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_theme') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // ⚠️ مهم: لإعلام widget بتحديث الحالة
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await prefs.setBool('is_dark_theme', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}

// Singleton
final themeController = ThemeController();
