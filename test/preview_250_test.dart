import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/providers/app_providers.dart';
import 'package:yor_flashcard/providers/language_provider.dart';
import 'package:yor_flashcard/providers/theme_provider.dart';
import 'package:yor_flashcard/screens/learning_preview_screen.dart';

void main() {
  testWidgets('Test 250 rows per page in LearningPreviewScreen', (WidgetTester tester) async {
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

    // Tap 250
    final item250 = find.text('250 baris/hal').last;
    await tester.tap(item250);
    await tester.pumpAndSettle();

    // Check showing text
    expect(find.text('Menampilkan 1 - 250 dari 300 data'), findsOneWidget);
    expect(find.text('Halaman 1 dari 2'), findsOneWidget);
  });
}
