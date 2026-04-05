import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/deck.dart';
import '../models/flashcard_card.dart';
import '../models/order_mode.dart';
import '../services/storage_service.dart';
import '../services/excel_service.dart';

class DeckProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Deck> _decks = [];
  Deck? _selectedDeck;

  List<Deck> get decks => _decks;
  Deck? get selectedDeck => _selectedDeck;

  Future<void> loadDecks() async {
    _decks = await _storageService.loadDecks();
    notifyListeners();
  }

  Future<Deck?> importDeckFromFile(String filePath, String customName) async {
    try {
      final fileName = filePath.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.xlsx?$'), '');
      final deckName = customName.isEmpty ? fileName : customName;

      final deck = await ExcelService.parseExcelFile(filePath, deckName);
      return deck;
    } catch (e) {
      debugPrint('Error importing deck: $e');
      rethrow;
    }
  }

  Future<Deck?> importDeckFromFileBytes(
    List<int> bytes,
    String customName, {
    String? fileName,
  }) async {
    try {
      final sanitizedFileName = (fileName ?? 'Imported Deck').replaceAll(
        RegExp(r'\.xlsx?$', caseSensitive: false),
        '',
      );
      final deckName = customName.isEmpty ? sanitizedFileName : customName;

      final deck = await ExcelService.parseExcelFileFromBytes(
        bytes,
        deckName,
        fileName: fileName,
      );
      return deck;
    } catch (e) {
      debugPrint('Error importing deck from bytes: $e');
      rethrow;
    }
  }

  Future<void> addDeck(Deck deck) async {
    final existingIndex = _decks.indexWhere((d) => d.name == deck.name);
    if (existingIndex != -1) {
      deck = deck.copyWith(name: _generateUniqueName(deck.name));
    }

    _decks.add(deck);
    await _storageService.saveDecks(_decks);
    notifyListeners();
  }

  String _generateUniqueName(String baseName) {
    var counter = 2;
    String newName = '$baseName ($counter)';
    while (_decks.any((d) => d.name == newName)) {
      counter++;
      newName = '$baseName ($counter)';
    }
    return newName;
  }

  Future<void> deleteDeck(String deckId) async {
    await _storageService.deleteDeck(deckId);
    _decks.removeWhere((deck) => deck.id == deckId);

    if (_selectedDeck?.id == deckId) {
      _selectedDeck = null;
    }

    notifyListeners();
  }

  Future<void> renameDeck(String deckId, String newName) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index != -1) {
      _decks[index] = _decks[index].copyWith(name: newName);
      await _storageService.saveDecks(_decks);

      if (_selectedDeck?.id == deckId) {
        _selectedDeck = _decks[index];
      }

      notifyListeners();
    }
  }

  void selectDeck(Deck deck) {
    _selectedDeck = deck;
    notifyListeners();
  }
}

class LearningSessionProvider extends ChangeNotifier {
  List<FlashcardCard> _sessionCards = [];
  int _currentIndex = 0;
  OrderMode _orderMode = OrderMode.normal;
  bool _isFlipped = false;

  int get currentIndex => _currentIndex;
  int get totalCards => _sessionCards.length;
  FlashcardCard? get currentCard =>
      _sessionCards.isNotEmpty ? _sessionCards[_currentIndex] : null;
  OrderMode get orderMode => _orderMode;
  bool get isFlipped => _isFlipped;
  List<FlashcardCard> get sessionCards => _sessionCards;

  int get knownCount => _sessionCards.where((card) => card.known).length;
  int get unknownCount => _sessionCards.length - knownCount;
  double get progressPercent =>
      totalCards > 0 ? (knownCount / totalCards) * 100 : 0;

  void startSession(List<FlashcardCard> cards, OrderMode mode) {
    if (cards.isEmpty) {
      _sessionCards = [];
      _currentIndex = 0;
      _orderMode = mode;
      _isFlipped = false;
      notifyListeners();
      return;
    }

    var filtered = List<FlashcardCard>.from(cards);

    // Apply order mode
    switch (mode) {
      case OrderMode.normal:
        // Original order (as in Excel)
        break;
      case OrderMode.reverse:
        filtered = filtered.reversed.toList();
        break;
      case OrderMode.random:
        filtered.shuffle();
        break;
    }

    _sessionCards = filtered;
    _currentIndex = 0;
    _orderMode = mode;
    _isFlipped = false;
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void unflipCard() {
    _isFlipped = false;
    notifyListeners();
  }

  void nextCard() {
    if (_currentIndex < _sessionCards.length - 1) {
      _currentIndex++;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void previousCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void markKnown(bool known) {
    if (currentCard != null) {
      _sessionCards[_currentIndex] =
          _sessionCards[_currentIndex].copyWith(known: known);
      notifyListeners();
    }
  }

  void resetSession() {
    _sessionCards = [];
    _currentIndex = 0;
    _isFlipped = false;
    notifyListeners();
  }
}
