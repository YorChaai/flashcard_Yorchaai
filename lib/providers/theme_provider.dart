import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_app_mode.dart';
import '../models/font_size_settings.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _legacyThemeKey = 'yorflashcard_theme_mode';
  static const String _legacyFontSizeKey = 'yorflashcard_font_size_settings';
  static SharedPreferences? _prefs;

  @visibleForTesting
  static void resetMockPrefs() => _prefs = null;

  FlashcardAppMode _currentMode = FlashcardAppMode.language;
  ThemeMode _themeMode = ThemeMode.light;
  FontSizeSettings _fontSizeSettings = FontSizeSettings();

  ThemeMode get themeMode => _themeMode;
  FlashcardAppMode get currentMode => _currentMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  FontSizeSettings get fontSizeSettings => _fontSizeSettings;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _modeThemeKey(FlashcardAppMode mode) => '${mode.storagePrefix}theme_mode';
  String _modeFontSizeKey(FlashcardAppMode mode) => '${mode.storagePrefix}font_size_settings';

  Future<void> loadTheme([FlashcardAppMode? mode]) async {
    if (mode != null) _currentMode = mode;
    try {
      final prefs = await _getPrefs();
      final modeDark = prefs.getBool(_modeThemeKey(_currentMode));
      final bool isDark;
      if (modeDark != null) {
        isDark = modeDark;
      } else {
        isDark = prefs.getBool(_legacyThemeKey) ?? false;
      }
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      // Load font size settings for active mode
      final modeFontSize = prefs.getString(_modeFontSizeKey(_currentMode));
      final fontSizeJson = modeFontSize ?? (_currentMode == FlashcardAppMode.language ? prefs.getString(_legacyFontSizeKey) : null);
      if (fontSizeJson != null) {
        _fontSizeSettings = FontSizeSettings.fromJson(
          jsonDecode(fontSizeJson) as Map<String, dynamic>,
        );
      } else {
        _fontSizeSettings = FontSizeSettings();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('WARNING: Failed to load theme: $e');
      _themeMode = ThemeMode.light;
      _fontSizeSettings = FontSizeSettings();
      notifyListeners();
    }
  }

  Future<void> setAppMode(FlashcardAppMode mode) async {
    _currentMode = mode;
    await loadTheme(mode);
  }

  Future<void> toggleTheme() async {
    try {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      final prefs = await _getPrefs();
      // Save specifically for this mode
      await prefs.setBool(_modeThemeKey(_currentMode), _themeMode == ThemeMode.dark);
      if (_currentMode == FlashcardAppMode.language) {
        await prefs.setBool(_legacyThemeKey, _themeMode == ThemeMode.dark);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to toggle theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      final prefs = await _getPrefs();
      await prefs.setBool(_modeThemeKey(_currentMode), mode == ThemeMode.dark);
      if (_currentMode == FlashcardAppMode.language) {
        await prefs.setBool(_legacyThemeKey, mode == ThemeMode.dark);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to set theme mode: $e');
    }
  }

  Future<void> setThemeModeForBothModes(ThemeMode mode) async {
    try {
      _themeMode = mode;
      final prefs = await _getPrefs();
      await prefs.setBool(_modeThemeKey(FlashcardAppMode.language), mode == ThemeMode.dark);
      await prefs.setBool(_modeThemeKey(FlashcardAppMode.all), mode == ThemeMode.dark);
      await prefs.setBool(_legacyThemeKey, mode == ThemeMode.dark);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to set theme for both modes: $e');
    }
  }

  Future<void> updateFontSizeSettings(FontSizeSettings newSettings) async {
    try {
      _fontSizeSettings = newSettings;
      final prefs = await _getPrefs();
      final jsonStr = jsonEncode(newSettings.toJson());
      await prefs.setString(_modeFontSizeKey(_currentMode), jsonStr);
      if (_currentMode == FlashcardAppMode.language) {
        await prefs.setString(_legacyFontSizeKey, jsonStr);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to update font size settings: $e');
    }
  }
}
