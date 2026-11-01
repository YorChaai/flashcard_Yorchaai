import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yor_flashcard/models/flashcard_app_mode.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';
import 'package:yor_flashcard/providers/language_provider.dart';
import 'package:yor_flashcard/providers/theme_provider.dart';
import 'package:yor_flashcard/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.clearMockPrefs();
    LanguageProvider.resetMockPrefs();
    ThemeProvider.resetMockPrefs();
  });

  group('Mode Isolation Tests (Language vs All)', () {
    test('LanguageProvider isolates language setting between language and all modes', () async {
      SharedPreferences.setMockInitialValues({
        '${FlashcardAppMode.language.storagePrefix}language': 'en',
        '${FlashcardAppMode.all.storagePrefix}language': 'id',
      });

      final langProv = LanguageProvider();
      await langProv.loadLanguage();

      // Default is language mode -> 'en'
      expect(langProv.currentMode, FlashcardAppMode.language);
      expect(langProv.currentLanguage, 'en');

      // Switch to All mode -> loads 'yorflashcard_all_language' which is 'id'
      await langProv.setAppMode(FlashcardAppMode.all);
      expect(langProv.currentMode, FlashcardAppMode.all);
      expect(langProv.currentLanguage, 'id');

      // Change in All mode should not affect Language mode
      await langProv.setLanguage('en');
      expect(langProv.currentLanguage, 'en');

      // Switch back to Language mode -> should still be 'en'
      await langProv.setAppMode(FlashcardAppMode.language);
      expect(langProv.currentLanguage, 'en');
    });

    test('ThemeProvider isolates ThemeMode and FontSizeSettings between modes', () async {
      final themeProv = ThemeProvider();
      await themeProv.loadTheme();

      // Set language mode to Dark
      await themeProv.setAppMode(FlashcardAppMode.language);
      await themeProv.setThemeMode(ThemeMode.dark);
      expect(themeProv.themeMode, ThemeMode.dark);

      // Set all mode to Light explicitly
      await themeProv.setAppMode(FlashcardAppMode.all);
      await themeProv.setThemeMode(ThemeMode.light);
      expect(themeProv.themeMode, ThemeMode.light);

      // Switch back to language mode -> still dark!
      await themeProv.setAppMode(FlashcardAppMode.language);
      expect(themeProv.themeMode, ThemeMode.dark);

      // Switch back to all mode -> still light!
      await themeProv.setAppMode(FlashcardAppMode.all);
      expect(themeProv.themeMode, ThemeMode.light);
    });

    test('MainHub toggles synchronize theme and language to both modes', () async {
      final langProv = LanguageProvider();
      final themeProv = ThemeProvider();

      // Hub sets ID and Dark for both modes
      await langProv.setLanguageForBothModes('id');
      await themeProv.setThemeModeForBothModes(ThemeMode.dark);

      // Check Language mode
      await langProv.setAppMode(FlashcardAppMode.language);
      await themeProv.setAppMode(FlashcardAppMode.language);
      expect(langProv.currentLanguage, 'id');
      expect(themeProv.themeMode, ThemeMode.dark);

      // Check All mode
      await langProv.setAppMode(FlashcardAppMode.all);
      await themeProv.setAppMode(FlashcardAppMode.all);
      expect(langProv.currentLanguage, 'id');
      expect(themeProv.themeMode, ThemeMode.dark);
    });
  });

  group('Per-File Excel Mapping and Column Independence Tests', () {
    test('StorageService persists and isolates Excel mapping per file name', () async {
      final file1 = 'vocab_japanese_n5.xlsx';
      final file2 = 'physics_formulas.xlsx';

      final mapping1 = [0, 2, 4]; // Map col A, C, E
      final mapping2 = [1, 3, 5, 7]; // Map col B, D, F, H

      await StorageService.saveExcelMappingForFile(file1, mapping1);
      await StorageService.saveExcelMappingForFile(file2, mapping2);

      final loaded1 = await StorageService.getExcelMappingForFile(file1);
      final loaded2 = await StorageService.getExcelMappingForFile(file2);

      expect(loaded1, equals(mapping1));
      expect(loaded2, equals(mapping2));
      expect(loaded1, isNot(equals(loaded2)));
    });

    test('Each Deck retains completely independent column headers and structure', () {
      final deck1 = Deck(
        id: 'deck_japanese',
        name: 'Japanese N5',
        columnCount: 3,
        visibleColumnCount: 3,
        columnHeaders: ['Kanji', 'Hiragana', 'Arti'],
        cards: [
          FlashcardCard(columns: ['食べる', 'たべる', 'Makan']),
        ],
        sourceFileName: 'japanese.xlsx',
        excelMapping: [0, 1, 2],
      );

      final deck2 = Deck(
        id: 'deck_python',
        name: 'Python Tips',
        columnCount: 4,
        visibleColumnCount: 2,
        columnHeaders: ['Concept', 'Syntax', 'Example', 'Notes'],
        cards: [
          FlashcardCard(columns: ['List Comprehension', '[x for x in list]', '[i*2 for i in range(5)]', 'Fast']),
        ],
        sourceFileName: 'python.xlsx',
        excelMapping: [0, 1, 3, 4],
      );

      // Verify deck1 is independent of deck2
      expect(deck1.columnCount, 3);
      expect(deck1.columnHeaders, ['Kanji', 'Hiragana', 'Arti']);
      expect(deck1.sourceFileName, 'japanese.xlsx');

      expect(deck2.columnCount, 4);
      expect(deck2.visibleColumnCount, 2);
      expect(deck2.columnHeaders, ['Concept', 'Syntax', 'Example', 'Notes']);
      expect(deck2.sourceFileName, 'python.xlsx');

      // Modifying deck1 does not change deck2
      final updatedDeck1 = deck1.copyWith(
        columnHeaders: ['Hanzi', 'Pinyin', 'Meaning'],
      );
      expect(updatedDeck1.columnHeaders, ['Hanzi', 'Pinyin', 'Meaning']);
      expect(deck2.columnHeaders, ['Concept', 'Syntax', 'Example', 'Notes']);
    });
  });
}
