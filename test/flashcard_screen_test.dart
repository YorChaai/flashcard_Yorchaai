import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';
import 'package:yor_flashcard/models/order_mode.dart';
import 'package:yor_flashcard/providers/app_providers.dart';
import 'package:yor_flashcard/providers/theme_provider.dart';
import 'package:yor_flashcard/screens/flashcard_screen.dart';

void main() {
  testWidgets('FlashcardScreen Next to Finish behavior on last card with Back navigation', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
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
    expect(find.text('Prompt berhasil disalin ke clipboard!'), findsOneWidget);

    // Tap Finish -> Navigates to ResultScreen
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Session Complete!'), findsOneWidget);
  });
}
