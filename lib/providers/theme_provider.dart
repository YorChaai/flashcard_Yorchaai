import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'yorflashcard_theme_mode';
  static SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> loadTheme() async {
    try {
      final prefs = await _getPrefs();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      debugPrint('WARNING: Failed to load theme: $e');
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    try {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      final prefs = await _getPrefs();
      await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to toggle theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      final prefs = await _getPrefs();
      await prefs.setBool(_themeKey, mode == ThemeMode.dark);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to set theme mode: $e');
    }
  }
}
