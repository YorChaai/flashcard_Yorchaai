import 'package:flutter_test/flutter_test.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';

void main() {
  group('Library Preview Filter & Sort Comprehensive Logic Tests', () {
    final List<FlashcardCard> mockCards = [
      FlashcardCard(
        id: '1',
        columns: ['new', 'baru', '/nu/', 'ADJ, ADV', 'A1', '27'],
        score: 0,
      ),
      FlashcardCard(
        id: '2',
        columns: ['more', 'lagi', '/mɔr/', 'ADJ, ADV, NOUN', 'A1', '28'],
        score: 2,
      ),
      FlashcardCard(
        id: '3',
        columns: ['home', 'rumah', '/hoʊm/', 'ADJ, ADV, NOUN, VERB', 'A1', '33'],
        score: -1,
      ),
      FlashcardCard(
        id: '4',
        columns: ['page', 'halaman', '/peɪdʒ/', 'NOUN (Tech)', 'A1', '38'],
        score: 5,
      ),
      FlashcardCard(
        id: '5',
        columns: ['search', 'mencari', '/sɜrtʃ/', 'NOUN, VERB', 'B1', '41'],
        score: -3,
      ),
    ];

    test('Search filter matches column content and score', () {
      final query = 'rumah';
      final match = mockCards.where((c) => c.columns.any((col) => col.toLowerCase().contains(query))).toList();
      expect(match.length, 1);
      expect(match.first.columns[0], 'home');

      final scoreQuery = '-3';
      final scoreMatch = mockCards.where((c) => c.score.toString() == scoreQuery).toList();
      expect(scoreMatch.length, 1);
      expect(scoreMatch.first.columns[0], 'search');
    });

    test('Type token cleaning handles parenthesized types', () {
      String cleanType(String token) {
        final withoutParen = token.replaceAll(RegExp(r'\(.*?\)'), '').trim();
        return withoutParen.isNotEmpty ? withoutParen : token.trim();
      }

      expect(cleanType('NOUN (Tech)'), 'NOUN');
      expect(cleanType('NOUN (Brand/Name)'), 'NOUN');
      expect(cleanType('ADJ'), 'ADJ');
    });

    test('Score filter categories work independently', () {
      final negative = mockCards.where((c) => c.score < 0).toList();
      final zero = mockCards.where((c) => c.score == 0).toList();
      final positive = mockCards.where((c) => c.score > 0).toList();

      expect(negative.map((c) => c.columns[0]), ['home', 'search']);
      expect(zero.map((c) => c.columns[0]), ['new']);
      expect(positive.map((c) => c.columns[0]), ['more', 'page']);
    });

    test('Numeric sorting sorts values by magnitude', () {
      final sortedAsc = List<FlashcardCard>.from(mockCards)
        ..sort((a, b) {
          final numA = num.tryParse(a.columns[5]) ?? double.infinity;
          final numB = num.tryParse(b.columns[5]) ?? double.infinity;
          return numA.compareTo(numB);
        });

      expect(sortedAsc.first.columns[0], 'new'); // 27
      expect(sortedAsc.last.columns[0], 'search'); // 41
    });

    test('CEFR Level hierarchy sorting works accurately', () {
      const cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
      final sortedCefr = List<FlashcardCard>.from(mockCards)
        ..sort((a, b) {
          final rankA = cefrLevels.indexOf(a.columns[4]);
          final rankB = cefrLevels.indexOf(b.columns[4]);
          return rankA.compareTo(rankB);
        });

      expect(sortedCefr.last.columns[0], 'search'); // B1 rank 2
    });

    test('No. column sorting (0->9 Ascending and 9->0 Descending)', () {
      final originalNumbers = {
        '1': 1,
        '2': 2,
        '3': 3,
        '4': 4,
        '5': 5,
      };

      // 0 -> 9 (Ascending: 1 -> 5)
      final sortedAsc = List<FlashcardCard>.from(mockCards)
        ..sort((a, b) {
          final noA = originalNumbers[a.id] ?? 0;
          final noB = originalNumbers[b.id] ?? 0;
          return noA.compareTo(noB);
        });
      expect(sortedAsc.map((c) => originalNumbers[c.id]), [1, 2, 3, 4, 5]);
      expect(sortedAsc.first.columns[0], 'new');
      expect(sortedAsc.last.columns[0], 'search');

      // 9 -> 0 (Descending: 5 -> 1)
      final sortedDesc = List<FlashcardCard>.from(mockCards)
        ..sort((a, b) {
          final noA = originalNumbers[a.id] ?? 0;
          final noB = originalNumbers[b.id] ?? 0;
          return noB.compareTo(noA);
        });
      expect(sortedDesc.map((c) => originalNumbers[c.id]), [5, 4, 3, 2, 1]);
      expect(sortedDesc.first.columns[0], 'search');
      expect(sortedDesc.last.columns[0], 'new');
    });

    test('Range filter by original row numbers combined with 9->0 sort', () {
      final originalNumbers = {
        '1': 1,
        '2': 2,
        '3': 3,
        '4': 4,
        '5': 5,
      };

      // Range From 2 To 4 (Original rows 2, 3, 4)
      final inRange = mockCards.where((c) {
        final no = originalNumbers[c.id]!;
        return no >= 2 && no <= 4;
      }).toList();

      expect(inRange.map((c) => originalNumbers[c.id]), [2, 3, 4]);

      // Sorted 9 -> 0 (Descending)
      final sortedDesc = List<FlashcardCard>.from(inRange)
        ..sort((a, b) {
          final noA = originalNumbers[a.id]!;
          final noB = originalNumbers[b.id]!;
          return noB.compareTo(noA);
        });

      // Output must be: [4, 3, 2] ('page', 'home', 'more')
      expect(sortedDesc.map((c) => originalNumbers[c.id]), [4, 3, 2]);
      expect(sortedDesc.first.columns[0], 'page');
      expect(sortedDesc.last.columns[0], 'more');
    });
  });
}
