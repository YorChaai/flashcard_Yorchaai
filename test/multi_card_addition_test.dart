import 'package:flutter_test/flutter_test.dart';
import 'package:yor_flashcard/models/deck.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';

void main() {
  group('Fitur 1: Multi-card addition logic & database integrity', () {
    late Deck initialDeck;

    setUp(() {
      initialDeck = Deck(
        id: 'custom_mode_deck_default',
        name: 'Custom Cards',
        cards: [
          FlashcardCard(id: 'c1', columns: ['Apple', 'Apel']),
        ],
        columnHeaders: ['Kata', 'Arti'],
        columnCount: 2,
        visibleColumnCount: 2,
      );
    });

    test('Bisa menambahkan multiple cards sekaligus ke dalam deck', () {
      final inputRows = [
        {'kata': 'Book', 'arti': 'Buku'},
        {'kata': 'Car', 'arti': 'Mobil'},
        {'kata': 'Sun', 'arti': ''}, // Hanya kata saja tanpa arti (diperbolehkan)
      ];

      Deck currentDeck = initialDeck;

      for (final row in inputRows) {
        final kata = row['kata']!.trim();
        final arti = row['arti']!.trim();

        if (kata.isEmpty) continue; // Skip jika kata kosong

        List<String> cols = [kata, arti];
        while (cols.length < currentDeck.columnCount) {
          cols.add('');
        }

        final newCard = FlashcardCard(columns: cols);
        currentDeck = currentDeck.addCard(newCard);
      }

      expect(currentDeck.cards.length, 4);
      expect(currentDeck.cards[1].columns[0], 'Book');
      expect(currentDeck.cards[1].columns[1], 'Buku');
      expect(currentDeck.cards[2].columns[0], 'Car');
      expect(currentDeck.cards[2].columns[1], 'Mobil');
      expect(currentDeck.cards[3].columns[0], 'Sun');
      expect(currentDeck.cards[3].columns[1], '');
    });

    test('Validasi baris: arti terisi tetapi kata kosong harus diidentifikasi sebagai error', () {
      final rows = [
        {'kata': '', 'arti': 'Buku'}, // Error: kata kosong
        {'kata': 'Car', 'arti': 'Mobil'}, // Valid
        {'kata': 'Sun', 'arti': ''}, // Valid
        {'kata': '', 'arti': ''}, // Valid untuk di-skip
      ];

      final errors = <int, bool>{};
      final validToSave = <Map<String, String>>[];

      for (int i = 0; i < rows.length; i++) {
        final kata = rows[i]['kata']!.trim();
        final arti = rows[i]['arti']!.trim();

        if (arti.isNotEmpty && kata.isEmpty) {
          errors[i] = true;
        } else {
          errors[i] = false;
          if (kata.isNotEmpty) {
            validToSave.add(rows[i]);
          }
        }
      }

      expect(errors[0], isTrue);
      expect(errors[1], isFalse);
      expect(errors[2], isFalse);
      expect(errors[3], isFalse);
      expect(validToSave.length, 2);
    });
  });
}
