import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';
import 'package:yor_flashcard/models/order_mode.dart';
import 'package:yor_flashcard/providers/app_providers.dart';
import 'package:yor_flashcard/providers/language_provider.dart';
import 'package:yor_flashcard/providers/theme_provider.dart';
import 'package:yor_flashcard/screens/flashcard_screen.dart';

void main() {
  testWidgets('FlashcardScreen Next to Finish behavior on last card with Back navigation', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    final languageProvider = LanguageProvider();
    final deckProvider = DeckProvider();
    final sessionProvider = LearningSessionProvider();

    final cards = [
      FlashcardCard(columns: ['word1', 'noun']),
      FlashcardCard(columns: ['word2', 'verb']),
    ];
    final deck = Deck(
      id: 'deck-1',
      name: 'Test Deck',
      columnHeaders: ['kata', 'type'],
      cards: cards,
    );

    deckProvider.selectDeck(deck);
    sessionProvider.startSession(cards, OrderMode.normal);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: languageProvider),
          ChangeNotifierProvider.value(value: deckProvider),
          ChangeNotifierProvider.value(value: sessionProvider),
        ],
        child: const MaterialApp(
          home: FlashcardScreen(),
        ),
      ),
    );

    // Card 1 of 2: Title should be "1 / 2"
    expect(find.text('1 / 2'), findsOneWidget);
    // Button should be 'Next'
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);

    // Tap Next -> go to Card 2 of 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Card 2 of 2: Title should be "2 / 2"
    expect(find.text('2 / 2'), findsOneWidget);
    // Button should change to 'Finish'
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    // Tap Previous -> go back to Card 1 of 2
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    // Title should be "1 / 2"
    expect(find.text('1 / 2'), findsOneWidget);
    // Button must revert to 'Next'
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);

    // Tap Next again -> Card 2 of 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Button should be 'Finish' again
    expect(find.text('Finish'), findsOneWidget);

    // Tap Copy Prompt button in AppBar
    expect(find.byTooltip('Copy Prompt'), findsOneWidget);
    await tester.tap(find.byTooltip('Copy Prompt'));
    await tester.pump();

    // SnackBar should appear
    expect(find.text('Prompt copied to clipboard!'), findsOneWidget);

    // Tap Finish -> Navigates to ResultScreen
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Session Complete!'), findsOneWidget);
  });

  testWidgets('ViewMode toggle button {1} / {All} toggles and controls transition behavior', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    final languageProvider = LanguageProvider();
    final deckProvider = DeckProvider();
    final sessionProvider = LearningSessionProvider();

    final cards = [
      FlashcardCard(columns: ['Front 1', 'Back 1']),
      FlashcardCard(columns: ['Front 2', 'Back 2']),
      FlashcardCard(columns: ['Front 3', 'Back 3']),
    ];
    final deck = Deck(
      id: 'deck-viewmode',
      name: 'ViewMode Deck',
      columnHeaders: ['Front', 'Back'],
      cards: cards,
    );

    deckProvider.selectDeck(deck);
    sessionProvider.startSession(cards, OrderMode.normal);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: languageProvider),
          ChangeNotifierProvider.value(value: deckProvider),
          ChangeNotifierProvider.value(value: sessionProvider),
        ],
        child: const MaterialApp(
          home: FlashcardScreen(),
        ),
      ),
    );

    // 1. Initially, mode button shows '1' (default)
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Front 1'), findsOneWidget);

    // Flip card to reveal back
    await tester.tap(find.text('Front 1'));
    await tester.pumpAndSettle();
    expect(find.text('Back 1'), findsOneWidget);

    // In mode {1}, pressing Next resets to Front on the next card
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Front 2'), findsOneWidget);

    // 2. Tap toggle button to switch to {All}
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);

    // Flip card to reveal back
    await tester.tap(find.text('Front 2'));
    await tester.pumpAndSettle();
    expect(find.text('Back 2'), findsOneWidget);

    // In mode {All}, pressing Next preserves back on the next card
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Back 3'), findsOneWidget);

    // In mode {All}, pressing Previous preserves back on the previous card
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Back 2'), findsOneWidget);
  });
}
