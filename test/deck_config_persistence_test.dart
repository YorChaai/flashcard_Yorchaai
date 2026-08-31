import 'package:flutter_test/flutter_test.dart';
import 'package:yor_flashcard/models/deck_config.dart';
import 'package:yor_flashcard/models/order_mode.dart';

void main() {
  group('DeckConfig Persistence & Restoration Tests', () {
    test('DeckConfig serializes and deserializes all Sort, Filter, and Range preferences', () {
      final originalConfig = DeckConfig(
        deckId: 'deck_123',
        sortColumnIndex: 0,
        sortAscending: false, // Descending 9 -> 0
        typeSortPriority: ['NOUN', 'VERB', 'ADJ', 'ADV'],
        cefrSortAscending: false,
        scoreSortAscending: true,
        selectedFilterTypes: {'NOUN', 'VERB'},
        selectedFilterCefr: {'A1', 'A2', 'B1'},
        selectedFilterScore: {'<0', '>0'}, // Negative & Positive without Zero
        rangeStart: 40,
        rangeEnd: 60,
        orderMode: OrderMode.reverse,
      );

      final jsonMap = originalConfig.toJson();
      final restoredConfig = DeckConfig.fromJson(jsonMap);

      expect(restoredConfig.deckId, 'deck_123');
      expect(restoredConfig.sortColumnIndex, 0);
      expect(restoredConfig.sortAscending, false);
      expect(restoredConfig.typeSortPriority, ['NOUN', 'VERB', 'ADJ', 'ADV']);
      expect(restoredConfig.cefrSortAscending, false);
      expect(restoredConfig.scoreSortAscending, true);
      expect(restoredConfig.selectedFilterTypes, {'NOUN', 'VERB'});
      expect(restoredConfig.selectedFilterCefr, {'A1', 'A2', 'B1'});
      expect(restoredConfig.selectedFilterScore, {'<0', '>0'});
      expect(restoredConfig.rangeStart, 40);
      expect(restoredConfig.rangeEnd, 60);
      expect(restoredConfig.orderMode, OrderMode.reverse);
    });

    test('copyWith preserves unchanged filters and sorting', () {
      final initialConfig = DeckConfig(
        deckId: 'deck_123',
        sortColumnIndex: 2,
        sortAscending: false,
        selectedFilterTypes: {'NOUN'},
        selectedFilterCefr: {'A1'},
        selectedFilterScore: {'0'},
        rangeStart: 1,
        rangeEnd: 100,
      );

      // Update only range
      final updatedConfig = initialConfig.copyWith(
        rangeStart: 60,
        rangeEnd: 70,
      );

      // Verify Sort and Filter were NOT wiped out
      expect(updatedConfig.sortColumnIndex, 2);
      expect(updatedConfig.sortAscending, false);
      expect(updatedConfig.selectedFilterTypes, {'NOUN'});
      expect(updatedConfig.selectedFilterCefr, {'A1'});
      expect(updatedConfig.selectedFilterScore, {'0'});
      expect(updatedConfig.rangeStart, 60);
      expect(updatedConfig.rangeEnd, 70);
    });
  });
}
