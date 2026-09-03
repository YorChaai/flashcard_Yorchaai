import 'package:flutter_test/flutter_test.dart';

bool verifyWritingPracticeAnswer(String input, String expected) {
  // Normalisasi ringan: trim spasi awal dan akhir tanpa mengubah karakter Unicode
  final trimmedInput = input.trim();
  final trimmedExpected = expected.trim();
  return trimmedInput == trimmedExpected;
}

void main() {
  group('Fitur 2: Writing Practice Answer Verification (Unicode & Text)', () {
    test('Verifikasi jawaban teks Latin biasa (English / Indonesia)', () {
      expect(verifyWritingPracticeAnswer('car', 'car'), isTrue);
      expect(verifyWritingPracticeAnswer(' car ', 'car'), isTrue);
      expect(verifyWritingPracticeAnswer('car', ' car '), isTrue);
      expect(verifyWritingPracticeAnswer('cat', 'car'), isFalse);
    });

    test('Verifikasi karakter Jepang (Hiragana & Katakana)', () {
      // Hiragana: kuruma (mobil)
      expect(verifyWritingPracticeAnswer('くるま', 'くるま'), isTrue);
      expect(verifyWritingPracticeAnswer(' くるま ', 'くるま'), isTrue);
      expect(verifyWritingPracticeAnswer('くる', 'くるま'), isFalse);

      // Katakana: koohii (kopi)
      expect(verifyWritingPracticeAnswer('コーヒー', 'コーヒー'), isTrue);
      expect(verifyWritingPracticeAnswer('コーヒ', 'コーヒー'), isFalse);
    });

    test('Verifikasi karakter Kanji & Hanzi', () {
      // Kanji: 車 (mobil)
      expect(verifyWritingPracticeAnswer('車', '車'), isTrue);
      expect(verifyWritingPracticeAnswer(' 車 ', '車'), isTrue);
      expect(verifyWritingPracticeAnswer('水', '車'), isFalse);
    });

    test('Verifikasi karakter Korea (Hangul)', () {
      // Hangul: 차 (mobil)
      expect(verifyWritingPracticeAnswer('차', '차'), isTrue);
      expect(verifyWritingPracticeAnswer(' 차 ', '차'), isTrue);
      expect(verifyWritingPracticeAnswer('물', '차'), isFalse);
    });

    test('Verifikasi karakter Jerman dengan umlaut', () {
      // German: Äpfel / Straße
      expect(verifyWritingPracticeAnswer('Äpfel', 'Äpfel'), isTrue);
      expect(verifyWritingPracticeAnswer('Straße', 'Straße'), isTrue);
      expect(verifyWritingPracticeAnswer('Strasse', 'Straße'), isFalse);
    });
  });
}
