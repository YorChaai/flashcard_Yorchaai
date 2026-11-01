import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck.dart';
import '../models/deck_config.dart';
import '../models/flashcard_app_mode.dart';

class StorageService {
  final FlashcardAppMode mode;

  // Legacy keys (sebelum pemisahan mode)
  static const String _legacyDecksKey = 'yorflashcard_decks';
  static const String _legacyRefDeckKey = 'yorflashcard_ref_deck_id';
  static const String _legacyLastDeckKey = 'yorflashcard_last_deck_id';
  static const String _legacyDeckConfigsPrefix = 'yorflashcard_deck_config_';

  static SharedPreferences? _prefs;

  StorageService({this.mode = FlashcardAppMode.language});

  @visibleForTesting
  static void setMockPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // === Excel Column Mapping Persistence per File ===
  static String _excelMappingKey(String fileName) =>
      'yorflashcard_file_excel_mapping_${fileName.trim().toLowerCase()}';

  static Future<void> saveExcelMappingForFile(String fileName, List<int> mapping) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_excelMappingKey(fileName), jsonEncode(mapping));
    } catch (e) {
      debugPrint('ERROR: Failed to save excel mapping for $fileName: $e');
    }
  }

  static Future<List<int>?> getExcelMappingForFile(String fileName) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final str = prefs.getString(_excelMappingKey(fileName));
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded.map((e) => (e as num).toInt()).toList();
        }
      }
    } catch (e) {
      debugPrint('ERROR: Failed to get excel mapping for $fileName: $e');
    }
    return null;
  }

  @visibleForTesting
  static void clearMockPrefs() {
    _prefs = null;
  }

  String get _prefix => mode.storagePrefix;
  String get _decksKey => '${_prefix}decks';
  String get _refDeckKey => '${_prefix}ref_deck_id';
  String get _lastDeckKey => '${_prefix}last_deck_id';
  String get _deckConfigsPrefix => '${_prefix}deck_config_';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<Deck>> loadDecks() async {
    try {
      final prefs = await _getPrefs();
      String? jsonString = prefs.getString(_decksKey);

      // Migrasi aman: Jika mode language belum punya data baru, cek apakah ada data legacy
      if (jsonString == null && mode == FlashcardAppMode.language) {
        final legacyJson = prefs.getString(_legacyDecksKey);
        if (legacyJson != null && legacyJson.isNotEmpty) {
          jsonString = legacyJson;
          // Salin ke key baru untuk mode language
          await prefs.setString(_decksKey, legacyJson);
        }
      }

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Deck.fromJson(json)).toList();
    } catch (e) {
      // If JSON is corrupted, return empty list but log warning
      debugPrint('WARNING: Failed to load decks data: $e');
      debugPrint('Data may be corrupted. Clearing corrupted data...');
      await _clearCorruptedData();
      return [];
    }
  }

  Future<void> saveDecks(List<Deck> decks) async {
    try {
      final prefs = await _getPrefs();
      final jsonList = decks.map((deck) => deck.toJson()).toList();
      await prefs.setString(_decksKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('ERROR: Failed to save decks: $e');
      rethrow;
    }
  }

  Future<DeckConfig> getDeckConfig(String deckId) async {
    try {
      final prefs = await _getPrefs();
      var jsonString = prefs.getString('$_deckConfigsPrefix$deckId');

      if (jsonString == null && mode == FlashcardAppMode.language) {
        final legacyConfig = prefs.getString('$_legacyDeckConfigsPrefix$deckId');
        if (legacyConfig != null && legacyConfig.isNotEmpty) {
          jsonString = legacyConfig;
          await prefs.setString('$_deckConfigsPrefix$deckId', legacyConfig);
        }
      }

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return DeckConfig.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('WARNING: Failed to load deck config for $deckId: $e');
    }
    return DeckConfig(deckId: deckId);
  }

  Future<void> saveDeckConfig(DeckConfig config) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = jsonEncode(config.toJson());
      await prefs.setString('$_deckConfigsPrefix${config.deckId}', jsonString);
    } catch (e) {
      debugPrint('ERROR: Failed to save deck config for ${config.deckId}: $e');
    }
  }

  Future<String?> getReferenceDeckId() async {
    final prefs = await _getPrefs();
    String? id = prefs.getString(_refDeckKey);
    if (id == null && mode == FlashcardAppMode.language) {
      id = prefs.getString(_legacyRefDeckKey);
      if (id != null) {
        await prefs.setString(_refDeckKey, id);
      }
    }
    return id;
  }

  Future<void> setReferenceDeckId(String? id) async {
    final prefs = await _getPrefs();
    if (id == null) {
      await prefs.remove(_refDeckKey);
    } else {
      await prefs.setString(_refDeckKey, id);
    }
  }

  Future<String?> getLastSelectedDeckId() async {
    final prefs = await _getPrefs();
    String? id = prefs.getString(_lastDeckKey);
    if (id == null && mode == FlashcardAppMode.language) {
      id = prefs.getString(_legacyLastDeckKey);
      if (id != null) {
        await prefs.setString(_lastDeckKey, id);
      }
    }
    return id;
  }

  Future<void> setLastSelectedDeckId(String? id) async {
    final prefs = await _getPrefs();
    if (id == null) {
      await prefs.remove(_lastDeckKey);
    } else {
      await prefs.setString(_lastDeckKey, id);
    }
  }

  Future<void> addDeck(Deck deck) async {
    final decks = await loadDecks();
    decks.add(deck);
    await saveDecks(decks);
  }

  Future<void> updateDeck(Deck updatedDeck) async {
    final decks = await loadDecks();
    final index = decks.indexWhere((deck) => deck.id == updatedDeck.id);
    if (index != -1) {
      decks[index] = updatedDeck;
      await saveDecks(decks);
    }
  }

  Future<void> deleteDeck(String deckId) async {
    final decks = await loadDecks();
    decks.removeWhere((deck) => deck.id == deckId);
    await saveDecks(decks);
  }

  Future<void> _clearCorruptedData() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_decksKey);
    } catch (e) {
      debugPrint('ERROR: Failed to clear corrupted data: $e');
    }
  }
}
