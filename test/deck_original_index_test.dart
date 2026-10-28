import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/models/deck_config.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';
import 'package:yor_flashcard/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Stable card numbers after deletion and restoration', () {
    late Deck deck;

    setUp(() {
      deck = Deck(
        id: 'deck-1',
        name: 'Test deck',
        cards: [
          FlashcardCard(id: 'a', columns: ['A']),
          FlashcardCard(id: 'b', columns: ['B']),
          FlashcardCard(id: 'c', columns: ['C']),
          FlashcardCard(id: 'd', columns: ['D']),
          FlashcardCard(id: 'e', columns: ['E']),
        ],
      );
    });

    test(
      'startup merges duplicate Custom Mode decks without losing cards',
      () async {
        SharedPreferences.setMockInitialValues({
          'yorflashcard_decks': jsonEncode([
            Deck(
              id: 'custom_mode_deck_default',
              name: 'My Custom Deck',
              cards: [
                FlashcardCard(id: 'custom-1', columns: ['one', 'satu']),
              ],
            ).toJson(),
            Deck(
              id: 'custom_mode_deck_default',
              name: 'Custom Mode',
              cards: [
                FlashcardCard(id: 'custom-2', columns: ['two', 'dua']),
              ],
            ).toJson(),
          ]),
        });

        final provider = DeckProvider();
        await provider.loadDecks();

        final customDecks = provider.decks
            .where((deck) => deck.id == 'custom_mode_deck_default')
            .toList();
        expect(customDecks, hasLength(1));
        expect(customDecks.single.name, 'My Custom Deck');
        expect(customDecks.single.cards.map((card) => card.id).toSet(), {
          'custom-1',
          'custom-2',
        });
      },
    );

    test(
      'restoring multiple deleted cards in reverse order keeps row order',
      () {
        deck = deck.softDeleteCard('b').softDeleteCard('d');

        expect(deck.deletedCards.map((card) => card.originalIndex), [1, 3]);
        expect(deck.maxOriginalNumber, 5);

        deck = deck.restoreCard('d').restoreCard('b');

        expect(deck.cards.map((card) => card.id), ['a', 'b', 'c', 'd', 'e']);
        expect(deck.cards.map((card) => card.originalIndex), [0, 1, 2, 3, 4]);
      },
    );

    test('learning range keeps original row numbers after deletion', () {
      deck = deck.softDeleteCard('b').softDeleteCard('d');

      final processed = DeckProvider().getProcessedCards(
        deck,
        DeckConfig(deckId: deck.id, rangeStart: 4, rangeEnd: 5),
        applyOrderMode: false,
      );

      expect(processed.map((card) => card.id), ['e']);
    });

    test('new cards append after the highest original row number', () {
      deck = deck.softDeleteCard('b');
      deck = deck.addCard(FlashcardCard(id: 'f', columns: ['F']));

      expect(deck.cards.last.originalIndex, 5);
      expect(deck.maxOriginalNumber, 6);
    });
  });
}
