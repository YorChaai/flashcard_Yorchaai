import 'package:flutter_test/flutter_test.dart';
import 'package:yor_flashcard/models/font_size_settings.dart';
import 'package:yor_flashcard/models/deck.dart';

void main() {
  group('FontSizeSettings 4-Modes Tests', () {
    test('Default values initialize correctly for 4 modes', () {
      final settings = FontSizeSettings();

      // PC Defaults
      expect(settings.pcFontSize1, 40.0);
      expect(settings.pcFontSize2_5, 16.0);
      expect(settings.pcFontSize6_9, 13.0);
      expect(settings.pcFontSize10_12, 11.0);

      // Mobile Defaults
      expect(settings.mobileFontSize1, 32.0);
      expect(settings.mobileFontSize2_5, 14.0);
      expect(settings.mobileFontSize6_9, 11.0);
      expect(settings.mobileFontSize10_12, 9.5);
    });

    test('Serializes to JSON and deserializes correctly', () {
      final settings = FontSizeSettings(
        pcFontSize1: 44.0,
        pcFontSize2_5: 18.0,
        pcFontSize6_9: 14.0,
        pcFontSize10_12: 12.0,
        mobileFontSize1: 34.0,
        mobileFontSize2_5: 15.0,
        mobileFontSize6_9: 12.0,
        mobileFontSize10_12: 10.0,
      );

      final json = settings.toJson();
      final restored = FontSizeSettings.fromJson(json);

      expect(restored.pcFontSize1, 44.0);
      expect(restored.pcFontSize2_5, 18.0);
      expect(restored.pcFontSize6_9, 14.0);
      expect(restored.pcFontSize10_12, 12.0);

      expect(restored.mobileFontSize1, 34.0);
      expect(restored.mobileFontSize2_5, 15.0);
      expect(restored.mobileFontSize6_9, 12.0);
      expect(restored.mobileFontSize10_12, 10.0);
    });

    test('Backward compatibility with legacy JSON keys', () {
      final legacyJson = {
        'pcFontSize1': 42.0,
        'pcFontSize23': 17.0,
        'pcFontSize45': 13.5,
        'pcFontSize6': 11.5,
        'mobileFontSize1': 30.0,
        'mobileFontSize23': 13.0,
        'mobileFontSize45': 10.5,
        'mobileFontSize6': 9.0,
      };

      final restored = FontSizeSettings.fromJson(legacyJson);
      expect(restored.pcFontSize1, 42.0);
      expect(restored.pcFontSize2_5, 17.0);
      expect(restored.pcFontSize6_9, 13.5);
      expect(restored.pcFontSize10_12, 11.5);

      expect(restored.mobileFontSize1, 30.0);
      expect(restored.mobileFontSize2_5, 13.0);
      expect(restored.mobileFontSize6_9, 10.5);
      expect(restored.mobileFontSize10_12, 9.0);
    });

    test('copyWith works cleanly for individual fields', () {
      final settings = FontSizeSettings();
      final modified = settings.copyWith(
        pcFontSize2_5: 20.0,
        mobileFontSize10_12: 10.5,
      );

      expect(modified.pcFontSize1, settings.pcFontSize1);
      expect(modified.pcFontSize2_5, 20.0);
      expect(modified.mobileFontSize10_12, 10.5);
      expect(modified.mobileFontSize1, settings.mobileFontSize1);
    });
  });

  group('Deck visibleColumnCount 1-12 Tests', () {
    test('Deck allows visibleColumnCount between 1 and 12', () {
      for (int count = 1; count <= 12; count++) {
        final deck = Deck(
          name: 'Test Deck $count',
          columnCount: 12,
          visibleColumnCount: count,
          cards: const [],
        );

        expect(deck.visibleColumnCount, count);

        final json = deck.toJson();
        expect(json['visibleColumnCount'], count);

        final restored = Deck.fromJson(json);
        expect(restored.visibleColumnCount, count);
      }
    });

    test('Deck safely clamps visibleColumnCount if out of range in json', () {
      final jsonUnder = {
        'id': 'd1',
        'name': 'Under Deck',
        'columnCount': 12,
        'visibleColumnCount': 0,
      };
      final restoredUnder = Deck.fromJson(jsonUnder);
      expect(restoredUnder.visibleColumnCount, 1);

      final jsonOver = {
        'id': 'd2',
        'name': 'Over Deck',
        'columnCount': 6,
        'visibleColumnCount': 20,
      };
      final restoredOver = Deck.fromJson(jsonOver);
      expect(restoredOver.visibleColumnCount, 12);
    });
  });
}
