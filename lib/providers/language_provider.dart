import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'yorflashcard_language';
  static SharedPreferences? _prefs;

  // Default bahasa aplikasi adalah English ('en')
  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;
  bool get isIndonesian => _currentLanguage == 'id';
  bool get isEnglish => _currentLanguage == 'en';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> loadLanguage() async {
    try {
      final prefs = await _getPrefs();
      _currentLanguage = prefs.getString(_languageKey) ?? 'en';
      notifyListeners();
    } catch (e) {
      debugPrint('WARNING: Failed to load language preference: $e');
      _currentLanguage = 'en';
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'id') return;
    if (_currentLanguage == languageCode) return;

    try {
      _currentLanguage = languageCode;
      final prefs = await _getPrefs();
      await prefs.setString(_languageKey, _currentLanguage);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to save language preference: $e');
    }
  }

  void toggleLanguage() {
    setLanguage(_currentLanguage == 'en' ? 'id' : 'en');
  }
}
