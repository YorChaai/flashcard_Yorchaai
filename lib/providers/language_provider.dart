import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_app_mode.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'yorflashcard_language';
  static SharedPreferences? _prefs;

  @visibleForTesting
  static void resetMockPrefs() => _prefs = null;

  // Default bahasa aplikasi adalah English ('en')
  String _currentLanguage = 'en';
  FlashcardAppMode _currentMode = FlashcardAppMode.language;

  String get currentLanguage => _currentLanguage;
  FlashcardAppMode get currentMode => _currentMode;
  bool get isIndonesian => _currentLanguage == 'id';
  bool get isEnglish => _currentLanguage == 'en';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _modeKey(FlashcardAppMode mode) => '${mode.storagePrefix}language';

  Future<void> loadLanguage([FlashcardAppMode? mode]) async {
    if (mode != null) _currentMode = mode;
    try {
      final prefs = await _getPrefs();
      final modeSaved = prefs.getString(_modeKey(_currentMode));
      if (modeSaved != null && modeSaved.isNotEmpty) {
        _currentLanguage = modeSaved;
      } else {
        _currentLanguage = prefs.getString(_languageKey) ?? 'en';
      }
      notifyListeners();
    } catch (e) {
      debugPrint('WARNING: Failed to load language preference: $e');
      _currentLanguage = 'en';
      notifyListeners();
    }
  }

  Future<void> setAppMode(FlashcardAppMode mode) async {
    _currentMode = mode;
    await loadLanguage(mode);
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'id') return;
    if (_currentLanguage == languageCode) return;

    try {
      _currentLanguage = languageCode;
      final prefs = await _getPrefs();
      // Save specifically for active mode
      await prefs.setString(_modeKey(_currentMode), _currentLanguage);
      if (_currentMode == FlashcardAppMode.language) {
        await prefs.setString(_languageKey, _currentLanguage);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to save language preference: $e');
    }
  }

  Future<void> setLanguageForBothModes(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'id') return;
    try {
      _currentLanguage = languageCode;
      final prefs = await _getPrefs();
      await prefs.setString(_modeKey(FlashcardAppMode.language), languageCode);
      await prefs.setString(_modeKey(FlashcardAppMode.all), languageCode);
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to set language for both modes: $e');
    }
  }

  void toggleLanguage() {
    setLanguage(_currentLanguage == 'en' ? 'id' : 'en');
  }
}
