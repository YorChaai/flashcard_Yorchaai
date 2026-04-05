import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/font_size_settings.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'yorflashcard_theme_mode';
  static const String _fontSizeKey = 'yorflashcard_font_size_settings';
  static SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.light;
  FontSizeSettings _fontSizeSettings = FontSizeSettings();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  FontSizeSettings get fontSizeSettings => _fontSizeSettings;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> loadTheme() async {
    try {
      final prefs = await _getPrefs();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      // Load font size settings
      final fontSizeJson = prefs.getString(_fontSizeKey);
      if (fontSizeJson != null) {
        _fontSizeSettings = FontSizeSettings.fromJson(
          jsonDecode(fontSizeJson) as Map<String, dynamic>,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('WARNING: Failed to load theme: $e');
      _themeMode = ThemeMode.light;
      _fontSizeSettings = FontSizeSettings();
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

  Future<void> updateFontSizeSettings(FontSizeSettings newSettings) async {
    try {
      _fontSizeSettings = newSettings;
      final prefs = await _getPrefs();
      await prefs.setString(_fontSizeKey, jsonEncode(newSettings.toJson()));
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to update font size settings: $e');
    }
  }
}
