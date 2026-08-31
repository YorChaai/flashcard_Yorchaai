import 'package:flutter_test/flutter_test.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';
import 'package:yor_flashcard/services/prompt_service.dart';

void main() {
  group('PromptService Tests', () {
    test('Scenario 1: Single verb "ask" generates single-type prompt without "terbagi dalam:"', () {
      final cards = [
        FlashcardCard(columns: ['ask', 'verb', 'meminta']),
      ];
      final deck = Deck(
        name: 'Test Deck',
        columnHeaders: ['kata', 'type', 'meaning'],
        cards: cards,
      );

      final prompt = PromptService.generatePrompt(cards: cards, deck: deck);

      expect(prompt.contains('Di sini saya ingin belajar 1 kata bahasa Inggris.'), isTrue);
      expect(prompt.contains('terbagi dalam:'), isFalse);
      expect(prompt.contains('* 1 verb (kata kerja): ask'), isTrue);
      expect(prompt.contains('3. berarti terdapat 1 kata 2 dialog jadi kalo ada 1 verb berarti ada 2 dialog, dan total ada 2 dialog'), isTrue);
      expect(prompt.contains('<aside>'), isTrue);
      expect(prompt.contains('</aside>'), isTrue);
    });

    test('Scenario 2: 15 mixed words (5 nouns, 5 verbs, 5 adjectives)', () {
      final nouns = ['area', 'book', 'business', 'case', 'child']
          .map((w) => FlashcardCard(columns: [w, 'noun']))
          .toList();
      final verbs = ['ask', 'be', 'become', 'begin', 'call']
          .map((w) => FlashcardCard(columns: [w, 'verb']))
          .toList();
      final adjectives = ['able', 'bad', 'best', 'better', 'big']
          .map((w) => FlashcardCard(columns: [w, 'adj']))
          .toList();

      final cards = [...nouns, ...verbs, ...adjectives];
      final deck = Deck(
        name: 'Test Deck 15',
        columnHeaders: ['kata', 'tipe'],
        cards: cards,
      );

      final prompt = PromptService.generatePrompt(cards: cards, deck: deck);

      expect(prompt.contains('Di sini saya ingin belajar 15 kata bahasa Inggris, terbagi dalam:'), isTrue);
      expect(prompt.contains('* 5 nouns (kata benda): area, book, business, case, child'), isTrue);
      expect(prompt.contains('* 5 verbs (kata kerja): ask, be, become, begin, call'), isTrue);
      expect(prompt.contains('* 5 adjectives (kata sifat): able, bad, best, better, big'), isTrue);
      expect(
        prompt.contains(
          '3. berarti terdapat 1 kata 2 dialog jadi kalo ada 5 nouns berarti ada 10 dialog, di tambah ada verbs 10 dialog, adjectives 10 dialog, dan total ada 30 dialog',
        ),
        isTrue,
      );
    });

    test('Scenario 3: Single type with multiple words (e.g. 3 verbs)', () {
      final cards = [
        FlashcardCard(columns: ['run', 'verb']),
        FlashcardCard(columns: ['jump', 'verb']),
        FlashcardCard(columns: ['eat', 'verb']),
      ];
      final deck = Deck(
        name: 'Verbs Only',
        columnHeaders: ['kata', 'type'],
        cards: cards,
      );

      final prompt = PromptService.generatePrompt(cards: cards, deck: deck);

      expect(prompt.contains('Di sini saya ingin belajar 3 kata bahasa Inggris.'), isTrue);
      expect(prompt.contains('terbagi dalam:'), isFalse);
      expect(prompt.contains('* 3 verbs (kata kerja): run, jump, eat'), isTrue);
      expect(
        prompt.contains('3. berarti terdapat 1 kata 2 dialog jadi kalo ada 3 verbs berarti ada 6 dialog, dan total ada 6 dialog'),
        isTrue,
      );
    });

    test('Scenario 4: Grammar tokens and specialized tags from Excel dataset', () {
      final cards = [
        FlashcardCard(columns: ['can', 'GRAMMAR (AUX)']),
        FlashcardCard(columns: ['in', 'GRAMMAR (ADP)']),
        FlashcardCard(columns: ['apple', 'NOUN (Tech/Modern)']),
        FlashcardCard(columns: ['fast', 'ADJ, ADV']),
      ];
      final deck = Deck(
        name: 'Grammar and Special',
        columnHeaders: ['kata', 'type'],
        cards: cards,
      );

      final prompt = PromptService.generatePrompt(cards: cards, deck: deck);

      expect(prompt.contains('Di sini saya ingin belajar 4 kata bahasa Inggris, terbagi dalam:'), isTrue);
      expect(prompt.contains('* 1 noun (kata benda): apple'), isTrue);
      expect(prompt.contains('* 1 adjective (kata sifat): fast'), isTrue);
      expect(prompt.contains('* 1 preposition (kata depan): in'), isTrue);
      expect(prompt.contains('* 1 auxiliary verb (kata kerja bantu): can'), isTrue);
    });

    test('Scenario 5: Single word with multiple types (home with ADJ, ADV, NOUN, VERB)', () {
      final cards = [
        FlashcardCard(columns: ['home', 'ADJ, ADV, NOUN, VERB']),
      ];
      final deck = Deck(
        name: 'Single Word Multi Type',
        columnHeaders: ['kata', 'type'],
        cards: cards,
      );

      final prompt = PromptService.generatePrompt(cards: cards, deck: deck);

      expect(prompt.contains('Di sini saya ingin belajar 1 kata bahasa Inggris, terbagi dalam:'), isTrue);
      expect(prompt.contains('* 1 noun (kata benda): home'), isTrue);
      expect(prompt.contains('* 1 verb (kata kerja): home'), isTrue);
      expect(prompt.contains('* 1 adjective (kata sifat): home'), isTrue);
      expect(prompt.contains('* 1 adverb (kata keterangan): home'), isTrue);
      expect(
        prompt.contains(
          '3. berarti terdapat 1 kata 2 dialog jadi kalo ada 1 noun berarti ada 2 dialog, di tambah ada verb 2 dialog, adjective 2 dialog, adverb 2 dialog, dan total ada 8 dialog',
        ),
        isTrue,
      );
    });
  });
}
