import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/models/flashcard_app_mode.dart';
import 'package:yor_flashcard/providers/app_providers.dart';
import 'package:yor_flashcard/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.clearMockPrefs();
  });

  group('FlashcardAppMode & Storage Isolation Tests', () {
    test('FlashcardAppMode properties are defined correctly', () {
      expect(FlashcardAppMode.language.enableWritingPractice, isTrue);
      expect(FlashcardAppMode.all.enableWritingPractice, isFalse);

      expect(FlashcardAppMode.language.storagePrefix, 'yorflashcard_lang_');
      expect(FlashcardAppMode.all.storagePrefix, 'yorflashcard_all_');
    });

    test('StorageService isolates decks between language and all modes', () async {
      final langStorage = StorageService(mode: FlashcardAppMode.language);
      final allStorage = StorageService(mode: FlashcardAppMode.all);

      // Save a deck in language mode
      final langDeck = Deck(
        id: 'lang_deck_1',
        name: 'Japanese Vocab',
        columnCount: 2,
        columnHeaders: ['Word', 'Meaning'],
        cards: [],
      );
      await langStorage.saveDecks([langDeck]);

      // Verify language storage has 1 deck
      final loadedLangDecks = await langStorage.loadDecks();
      expect(loadedLangDecks.length, 1);
      expect(loadedLangDecks.first.id, 'lang_deck_1');
      expect(loadedLangDecks.first.name, 'Japanese Vocab');

      // Verify all storage is still completely empty (isolated!)
      final loadedAllDecksEmpty = await allStorage.loadDecks();
      expect(loadedAllDecksEmpty, isEmpty);

      // Save a deck in all mode
      final allDeck = Deck(
        id: 'all_deck_1',
        name: 'Math Formulas',
        columnCount: 2,
        columnHeaders: ['Question', 'Answer'],
        cards: [],
      );
      await allStorage.saveDecks([allDeck]);

      // Verify all storage now has its deck
      final loadedAllDecks = await allStorage.loadDecks();
      expect(loadedAllDecks.length, 1);
      expect(loadedAllDecks.first.id, 'all_deck_1');
      expect(loadedAllDecks.first.name, 'Math Formulas');

      // Verify language storage still has only its own deck
      final finalLangDecks = await langStorage.loadDecks();
      expect(finalLangDecks.length, 1);
      expect(finalLangDecks.first.id, 'lang_deck_1');
    });

    test('StorageService migrates legacy decks to language mode gracefully', () async {
      // Simulate existing user with legacy data before mode separation
      SharedPreferences.setMockInitialValues({
        'yorflashcard_decks': '[{"id":"legacy_1","name":"Existing English Deck","columnCount":2,"columnHeaders":["Word","Meaning"],"cards":[],"deletedCards":[]}]',
        'yorflashcard_last_deck_id': 'legacy_1',
      });
      StorageService.clearMockPrefs();

      final langStorage = StorageService(mode: FlashcardAppMode.language);
      final allStorage = StorageService(mode: FlashcardAppMode.all);

      // Language mode should read legacy data seamlessly
      final langDecks = await langStorage.loadDecks();
      expect(langDecks.length, 1);
      expect(langDecks.first.id, 'legacy_1');
      expect(langDecks.first.name, 'Existing English Deck');

      final lastId = await langStorage.getLastSelectedDeckId();
      expect(lastId, 'legacy_1');

      // All mode must NOT inherit legacy language decks
      final allDecks = await allStorage.loadDecks();
      expect(allDecks, isEmpty);
      expect(await allStorage.getLastSelectedDeckId(), isNull);
    });

    test('DeckProvider setMode switches databases and keeps decks isolated end-to-end', () async {
      final deckProvider = DeckProvider();

      // 1. Start in Language mode
      await deckProvider.setMode(FlashcardAppMode.language);
      expect(deckProvider.currentMode, FlashcardAppMode.language);
      expect(deckProvider.decks.length, 1); // Default Custom Mode
      expect(deckProvider.decks.first.columnHeaders.first, 'Kata');

      // Add a language-specific deck
      final frenchDeck = Deck(
        id: 'french_vocab',
        name: 'Vocabulaire Francais',
        columnCount: 2,
        columnHeaders: ['Mot', 'Sens'],
        cards: [],
      );
      await deckProvider.addDeck(frenchDeck);
      expect(deckProvider.decks.any((d) => d.id == 'french_vocab'), isTrue);

      // 2. Switch to All mode
      await deckProvider.setMode(FlashcardAppMode.all);
      expect(deckProvider.currentMode, FlashcardAppMode.all);
      // French deck MUST NOT be present in All mode!
      expect(deckProvider.decks.any((d) => d.id == 'french_vocab'), isFalse);
      expect(deckProvider.decks.first.columnHeaders.first, 'Pertanyaan');

      // Add a general deck in All mode
      final physicsDeck = Deck(
        id: 'physics_formulas',
        name: 'Physics Formulas',
        columnCount: 2,
        columnHeaders: ['Question', 'Formula'],
        cards: [],
      );
      await deckProvider.addDeck(physicsDeck);
      expect(deckProvider.decks.any((d) => d.id == 'physics_formulas'), isTrue);

      // 3. Switch back to Language mode
      await deckProvider.setMode(FlashcardAppMode.language);
      expect(deckProvider.currentMode, FlashcardAppMode.language);
      // French deck is still present in Language mode!
      expect(deckProvider.decks.any((d) => d.id == 'french_vocab'), isTrue);
      // Physics deck MUST NOT leak into Language mode!
      expect(deckProvider.decks.any((d) => d.id == 'physics_formulas'), isFalse);
    });
  });
}
