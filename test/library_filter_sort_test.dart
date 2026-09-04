import 'package:flutter_test/flutter_test.dart';
import 'package:yor_flashcard/models/flashcard_card.dart';
import 'package:yor_flashcard/utils/app_strings.dart';

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

test('Dynamic Column Filtering works for arbitrary columns (e.g. Category & Status)', () {
      final customCards = [
        FlashcardCard(id: '1', columns: ['Word1', 'Verb', 'Active']),
        FlashcardCard(id: '2', columns: ['Word2', 'Noun', 'Pending']),
        FlashcardCard(id: '3', columns: ['Word3', 'Verb', 'Pending']),
        FlashcardCard(id: '4', columns: ['Word4', 'Adj', 'Active']),
      ];

      // Filter Category (col 1) = {'Verb'}
      final allowedCategory = {'Verb'};
      final verbOnly = customCards.where((c) => allowedCategory.contains(c.columns[1])).toList();
      expect(verbOnly.length, 2);
      expect(verbOnly.map((c) => c.columns[0]), ['Word1', 'Word3']);

      // Filter Status (col 2) = {'Pending'}
      final allowedStatus = {'Pending'};
      final pendingOnly = customCards.where((c) => allowedStatus.contains(c.columns[2])).toList();
      expect(pendingOnly.length, 2);
      expect(pendingOnly.map((c) => c.columns[0]), ['Word2', 'Word3']);
    });

    test('Type-agnostic sorting handles column converted from Integer to String cleanly', () {
      // Column index 1 contains String representations that are mixed or non-pure integer
      final stringCards = [
        FlashcardCard(id: '1', columns: ['A', 'Beta']),
        FlashcardCard(id: '2', columns: ['B', 'Alpha']),
        FlashcardCard(id: '3', columns: ['C', 'Gamma']),
      ];

      // Sort alphabetically (Ascending)
      final sortedAsc = List<FlashcardCard>.from(stringCards)
        ..sort((a, b) => a.columns[1].toLowerCase().compareTo(b.columns[1].toLowerCase()));
      expect(sortedAsc.map((c) => c.columns[1]), ['Alpha', 'Beta', 'Gamma']);

      // Sort alphabetically (Descending)
      final sortedDesc = List<FlashcardCard>.from(stringCards)
        ..sort((a, b) => b.columns[1].toLowerCase().compareTo(a.columns[1].toLowerCase()));
      expect(sortedDesc.map((c) => c.columns[1]), ['Gamma', 'Beta', 'Alpha']);
    });

    test('formatColumnHeader preserves raw Excel headers verbatim in all languages', () {
      // Import AppStrings helper
      expect(yorFlashcardTestHeader('Word', 'id'), 'Word');
      expect(yorFlashcardTestHeader('Word', 'en'), 'Word');
      expect(yorFlashcardTestHeader('Meaning', 'id'), 'Meaning');
      expect(yorFlashcardTestHeader('Meaning', 'en'), 'Meaning');
      expect(yorFlashcardTestHeader('Known', 'id'), 'Known');
      expect(yorFlashcardTestHeader('Category', 'id'), 'Category');
      expect(yorFlashcardTestHeader('Score', 'id'), 'Score');
      expect(yorFlashcardTestHeader('Status', 'id'), 'Status');
      expect(yorFlashcardTestHeader('Kata', 'en'), 'Kata');
      expect(yorFlashcardTestHeader('Arti', 'en'), 'Arti');
    });
    test('formatCardType reorders multi-type tokens according to Type Priority', () {
      final typePriority = ['NOUN', 'ADJ', 'ADV', 'UNKNOWN', 'VERB'];
      final priorityMap = <String, int>{};
      for (int i = 0; i < typePriority.length; i++) {
        priorityMap[typePriority[i]] = i;
      }

      String formatCardType(String rawType) {
        if (rawType.trim().isEmpty) return rawType;
        final tokens = rawType.split(',');
        if (tokens.length <= 1) return rawType.trim();

        final parsedTokens = <Map<String, dynamic>>[];
        for (final tok in tokens) {
          final trimmed = tok.trim();
          if (trimmed.isEmpty) continue;
          final clean = trimmed.replaceAll(RegExp(r'\(.*?\)'), '').trim().toUpperCase();
          final p = priorityMap[clean] ?? 999999;
          parsedTokens.add({
            'original': trimmed,
            'priority': p,
          });
        }

        parsedTokens.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));
        return parsedTokens.map((e) => e['original'] as String).join(', ');
      }

      // Exact examples from user request
      expect(formatCardType('ADJ, ADV, NOUN'), 'NOUN, ADJ, ADV');
      expect(formatCardType('VERB, NOUN, ADJ'), 'NOUN, ADJ, VERB');
      expect(formatCardType('ADJ, ADV, NOUN, VERB'), 'NOUN, ADJ, ADV, VERB');
      expect(formatCardType('ADJ, NOUN'), 'NOUN, ADJ');
    });

    test('Hierarchical Type Priority sorting keeps NOUN on top and preserves secondary No. order', () {
      final typePriority = ['NOUN', 'ADJ', 'ADV', 'UNKNOWN', 'VERB'];
      final priorityMap = <String, int>{};
      for (int i = 0; i < typePriority.length; i++) {
        priorityMap[typePriority[i]] = i;
      }

      final cards = [
        FlashcardCard(id: '1', columns: ['new', 'ADJ, ADV']),
        FlashcardCard(id: '2', columns: ['more', 'ADJ, ADV, NOUN']),
        FlashcardCard(id: '3', columns: ['home', 'ADJ, ADV, NOUN, VERB']),
        FlashcardCard(id: '5', columns: ['page', 'NOUN, VERB']),
        FlashcardCard(id: '6', columns: ['search', 'NOUN, VERB']),
        FlashcardCard(id: '8', columns: ['one', 'ADJ, NOUN']),
        FlashcardCard(id: '10', columns: ['no', 'ADJ, ADV, NOUN']),
        FlashcardCard(id: '12', columns: ['info', 'NOUN']),
        FlashcardCard(id: '20', columns: ['go', 'VERB']),
      ];

      final cardNos = {
        '1': 1, '2': 2, '3': 3, '5': 5, '6': 6, '8': 8, '10': 10, '12': 12, '20': 20
      };

      List<int> getCardKeys(FlashcardCard card) {
        final raw = card.columns[1];
        final tokens = raw
            .split(',')
            .map((e) => e.replaceAll(RegExp(r'\(.*?\)'), '').trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList();
        final keys = tokens.map((t) => priorityMap[t] ?? 999999).toList()..sort();
        return keys.isEmpty ? [999999] : keys;
      }

      int compareKeys(List<int> a, List<int> b) {
        final minLen = a.length < b.length ? a.length : b.length;
        for (int i = 0; i < minLen; i++) {
          final c = a[i].compareTo(b[i]);
          if (c != 0) return c;
        }
        return a.length.compareTo(b.length);
      }

      final sorted = List<FlashcardCard>.from(cards)
        ..sort((a, b) {
          final comp = compareKeys(getCardKeys(a), getCardKeys(b));
          if (comp != 0) return comp;
          return cardNos[a.id]!.compareTo(cardNos[b.id]!);
        });

      // Verification:
      // 1. All NOUN-bearing cards come before pure ADJ ('new') and pure VERB ('go')
      final wordOrder = sorted.map((c) => c.columns[0]).toList();
      expect(wordOrder.contains('info'), isTrue);

      // 'info' (pure NOUN [0]) is first!
      expect(wordOrder[0], 'info');

      // 'one' (NOUN, ADJ [0, 1]) is before 'more'/'no' (NOUN, ADJ, ADV [0, 1, 2])
      expect(wordOrder[1], 'one');

      // 'more' (No. 2) and 'no' (No. 10) are both [0, 1, 2], so No. 2 comes before No. 10!
      expect(wordOrder[2], 'more');
      expect(wordOrder[3], 'no');

      // 'home' [0, 1, 2, 4] comes next
      expect(wordOrder[4], 'home');

      // 'page' (No. 5) and 'search' (No. 6) are both [0, 4], so No. 5 comes before No. 6!
      expect(wordOrder[5], 'page');
      expect(wordOrder[6], 'search');

      // 'new' [1, 2] (ADJ, ADV) comes after all NOUN items
      expect(wordOrder[7], 'new');

      // 'go' [4] (VERB) comes last
      expect(wordOrder[8], 'go');
    });

    test('Exact User Scenario: Priority ADV, VERB, ADJ, NOUN correctly groups and orders multi-type cards by original row', () {
      final userPriority = ['ADV', 'VERB', 'ADJ', 'NOUN'];
      final priorityMap = <String, int>{};
      for (int i = 0; i < userPriority.length; i++) {
        priorityMap[userPriority[i]] = i;
      }

      int getCardTopPriority(String raw) {
        if (raw.trim().isEmpty) return 999999;
        final tokens = raw.split(RegExp(r'[,/]'));
        int minP = 999999;
        for (final t in tokens) {
          final clean = t.replaceAll(RegExp(r'\(.*?\)'), '').trim().toUpperCase();
          final p = priorityMap[clean] ?? 999999;
          if (p < minP) minP = p;
        }
        return minP;
      }

      String formatCardType(String raw) {
        if (raw.trim().isEmpty) return raw;
        final tokens = raw.split(RegExp(r'[,/]'));
        if (tokens.length <= 1) return raw.trim();
        final list = <Map<String, dynamic>>[];
        for (final t in tokens) {
          final clean = t.replaceAll(RegExp(r'\(.*?\)'), '').trim().toUpperCase();
          list.add({'original': t.trim(), 'p': priorityMap[clean] ?? 999999});
        }
        list.sort((a, b) => (a['p'] as int).compareTo(b['p'] as int));
        return list.map((e) => e['original'] as String).join(', ');
      }

      // Test formatting of multi-types
      expect(formatCardType('ADJ, ADV, NOUN, VERB'), 'ADV, VERB, ADJ, NOUN');
      expect(formatCardType('ADJ, NOUN, VERB'), 'VERB, ADJ, NOUN');
      expect(formatCardType('ADJ, ADV'), 'ADV, ADJ');

      // Cards from user's Excel rows
      final excelCards = [
        FlashcardCard(id: 'r2', columns: ['new', 'ADJ, ADV']), // No 2
        FlashcardCard(id: 'r3', columns: ['more', 'ADJ, ADV, NOUN']), // No 3
        FlashcardCard(id: 'r4', columns: ['home', 'ADJ, ADV, NOUN, VERB']), // No 4
        FlashcardCard(id: 'r5', columns: ['about', 'ADJ, ADV']), // No 5
        FlashcardCard(id: 'r6', columns: ['page', 'NOUN, VERB']), // No 6
        FlashcardCard(id: 'r7', columns: ['search', 'NOUN, VERB']), // No 7
        FlashcardCard(id: 'r8', columns: ['free', 'ADJ, ADV, NOUN, VERB']), // No 8
        FlashcardCard(id: 'r9', columns: ['one', 'ADJ, NOUN']), // No 9
        FlashcardCard(id: 'r10', columns: ['other', 'ADJ']), // No 10
      ];

      final rowNumbers = {
        'r2': 2, 'r3': 3, 'r4': 4, 'r5': 5, 'r6': 6, 'r7': 7, 'r8': 8, 'r9': 9, 'r10': 10,
      };

      final sorted = List<FlashcardCard>.from(excelCards)
        ..sort((a, b) {
          final pA = getCardTopPriority(a.columns[1]);
          final pB = getCardTopPriority(b.columns[1]);
          final comp = pA.compareTo(pB);
          if (comp != 0) return comp;
          return rowNumbers[a.id]!.compareTo(rowNumbers[b.id]!);
        });

      // Group 0: all cards containing ADV (in order of row number 2, 3, 4, 5, 8)
      expect(sorted[0].columns[0], 'new'); // Row 2
      expect(sorted[1].columns[0], 'more'); // Row 3
      expect(sorted[2].columns[0], 'home'); // Row 4
      expect(sorted[3].columns[0], 'about'); // Row 5
      expect(sorted[4].columns[0], 'free'); // Row 8

      // Group 1: cards without ADV but containing VERB (rows 6, 7)
      expect(sorted[5].columns[0], 'page'); // Row 6
      expect(sorted[6].columns[0], 'search'); // Row 7

      // Group 2: cards without ADV or VERB but containing ADJ (rows 9, 10)
      expect(sorted[7].columns[0], 'one'); // Row 9 (ADJ, NOUN)
      expect(sorted[8].columns[0], 'other'); // Row 10 (pure ADJ)
    });

    test('Exact User Scenario: Parentheses in type like "noun (brand/name)" and "noun (tech/modern)" are stripped before slash split and parsed strictly as NOUN without "modern)" or "name)"', () {
      final bracketRegExp = RegExp(r'[\(\[\{].*?[\)\]\}]');

      String cleanTypeString(String raw) {
        var s = raw;
        if (s.contains('(') || s.contains('[') || s.contains('{')) {
          s = s.replaceAll(bracketRegExp, ' ');
        }
        if (s.contains(')') || s.contains(']') || s.contains('}') || s.contains('(') || s.contains('[') || s.contains('{')) {
          s = s.replaceAll(RegExp(r'[\(\)\[\]\{\}]'), ' ');
        }
        return s.trim();
      }

      List<String> getCardBaseTypes(String raw) {
        final clean = cleanTypeString(raw);
        if (clean.isEmpty) return [];
        final tokens = clean.split(RegExp(r'[,/]'));
        final result = <String>[];
        for (final t in tokens) {
          final trimmed = t.trim().toUpperCase();
          if (trimmed.isNotEmpty && !result.contains(trimmed)) {
            result.add(trimmed);
          }
        }
        return result;
      }

      // Test raw types from user's dataset
      final brandNameTypes = getCardBaseTypes('noun (brand/name)');
      final techModernTypes = getCardBaseTypes('noun (tech/modern)');
      final multiWithParen = getCardBaseTypes('noun (brand/name), verb');

      expect(brandNameTypes, ['NOUN']);
      expect(brandNameTypes.contains('NAME)'), isFalse);
      expect(brandNameTypes.contains('brand/name'), isFalse);

      expect(techModernTypes, ['NOUN']);
      expect(techModernTypes.contains('MODERN)'), isFalse);
      expect(techModernTypes.contains('tech/modern'), isFalse);

      expect(multiWithParen, ['NOUN', 'VERB']);

      // Priority sort test with these cards
      final cards = [
        FlashcardCard(id: 'c1', columns: ['Apple', 'noun (brand/name)']),
        FlashcardCard(id: 'c2', columns: ['Internet', 'noun (tech/modern)']),
      ];

      final priorityMap = {'NOUN': 0, 'VERB': 1};
      int getTopPriority(FlashcardCard card) {
        final types = getCardBaseTypes(card.columns[1]);
        int minP = 999999;
        for (final t in types) {
          final p = priorityMap[t] ?? 999999;
          if (p < minP) minP = p;
        }
        return minP;
      }

      expect(getTopPriority(cards[0]), 0);
      expect(getTopPriority(cards[1]), 0);
    });

    test('Dropdown rowsPerPage (25, 50, 100, 250) accurately calculates sublists and totalPages for datasets', () {
      final largeCardList = List.generate(
        300,
        (i) => FlashcardCard(id: '$i', columns: ['Word $i', 'Arti $i']),
      );

      for (final rpp in [25, 50, 100, 250]) {
        int currentPage = 0;
        final startIdx = currentPage * rpp;
        final endIdx = ((startIdx + rpp) < largeCardList.length)
            ? (startIdx + rpp)
            : largeCardList.length;
        final pageCards = largeCardList.sublist(startIdx, endIdx);
        final totalPages = (largeCardList.length + rpp - 1) ~/ rpp;

        expect(pageCards.length, rpp);
        if (rpp == 25) expect(totalPages, 12);
        if (rpp == 50) expect(totalPages, 6);
        if (rpp == 100) expect(totalPages, 3);
        if (rpp == 250) expect(totalPages, 2);
      }
    });
  });
}

String yorFlashcardTestHeader(String h, String l) {
  return AppStrings.formatColumnHeader(h, l);
}

