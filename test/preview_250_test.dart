import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/providers/app_providers.dart';
import 'package:yor_flashcard/providers/language_provider.dart';
import 'package:yor_flashcard/providers/theme_provider.dart';
import 'package:yor_flashcard/screens/learning_preview_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Test 100 rows per page in LearningPreviewScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final List<FlashcardCard> cards = List.generate(
      300,
      (index) => FlashcardCard(
        id: 'card_$index',
        columns: ['Word $index', 'Arti $index', 'Pron $index', 'NOUN', 'A1', '$index'],
        score: 0,
      ),
    );

    final deck = Deck(
      id: 'deck_test',
      name: 'Test Deck 300',
      columnHeaders: ['Word', 'Arti', 'Pron', 'Type', 'CEFR', 'No'],
      cards: cards,
    );

    final langProvider = LanguageProvider();
    await langProvider.setLanguage('id');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DeckProvider()),
          ChangeNotifierProvider.value(value: langProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          home: LearningPreviewScreen(
            previewCards: cards,
            columnHeaders: deck.columnHeaders,
            deck: deck,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find Dropdown
    final dropdownFinder = find.byType(DropdownButton<int>);
    expect(dropdownFinder, findsOneWidget);

    // Scroll until dropdown is visible if needed
    await tester.ensureVisible(dropdownFinder);
    await tester.pumpAndSettle();

    // Tap dropdown
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Tap 100
    final item100 = find.text('100 baris/hal').last;
    await tester.tap(item100);
    await tester.pumpAndSettle();

    // Check showing text
    expect(find.text('Menampilkan 1 - 100 dari 300 data'), findsOneWidget);
    expect(find.text('Halaman 1 dari 3'), findsOneWidget);

    final dataTable = tester.widget<DataTable>(find.byType(DataTable));
    expect(dataTable.rows.length, 100);
  });

  testWidgets('Selecting 100 rows per page removes previous 50 limit constraint', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final List<FlashcardCard> cards = List.generate(
      300,
      (index) => FlashcardCard(
        id: 'card_$index',
        columns: ['Word $index', 'Arti $index', 'Pron $index', 'NOUN', 'A1', '$index'],
        score: 0,
      ),
    );

    final deck = Deck(
      id: 'deck_capped_50',
      name: 'Test Deck 300 Capped 50',
      columnHeaders: ['Word', 'Arti', 'Pron', 'Type', 'CEFR', 'No'],
      cards: cards,
    );

    final langProvider = LanguageProvider();
    await langProvider.setLanguage('id');

    final deckProvider = DeckProvider();
    // Simulate previous deck config capped at rangeEnd: 50
    final config = deckProvider.getDeckConfig(deck.id).copyWith(
      rangeStart: 1,
      rangeEnd: 50,
    );
    await deckProvider.updateDeckConfig(config);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: deckProvider),
          ChangeNotifierProvider.value(value: langProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          home: LearningPreviewScreen(
            previewCards: cards,
            columnHeaders: deck.columnHeaders,
            deck: deck,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially capped at 50
    expect(find.text('50 / 300'), findsOneWidget);

    // Find Dropdown
    final dropdownFinder = find.byType(DropdownButton<int>);
    expect(dropdownFinder, findsOneWidget);
    await tester.ensureVisible(dropdownFinder);
    await tester.pumpAndSettle();

    // Tap dropdown
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Select 100
    final item100 = find.text('100 baris/hal').last;
    await tester.tap(item100);
    await tester.pumpAndSettle();

    // Range limit is now cleared, genuinely showing 100 of 300
    expect(find.text('Menampilkan 1 - 100 dari 300 data'), findsOneWidget);
    expect(find.text('Halaman 1 dari 3'), findsOneWidget);

    final dataTable = tester.widget<DataTable>(find.byType(DataTable));
    expect(dataTable.rows.length, 100);
  });
}
