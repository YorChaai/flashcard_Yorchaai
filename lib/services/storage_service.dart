import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck.dart';

class StorageService {
  static const String _decksKey = 'yorflashcard_decks';
  static const String _refDeckKey = 'yorflashcard_ref_deck_id';
  static const String _lastDeckKey = 'yorflashcard_last_deck_id';
  static SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<Deck>> loadDecks() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(_decksKey);

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

  Future<String?> getReferenceDeckId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_refDeckKey);
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
    return prefs.getString(_lastDeckKey);
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
