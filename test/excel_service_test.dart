import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yor_flashcard/services/excel_service.dart';

void main() {
  group('ExcelService Sanitize & Parse Tests', () {
    test('Reads flashcard_FINAL_WITH_PROMPT_V4.xlsx sheets and data successfully', () async {
      final file = File(r'D:\2. Organize\1. Projects\flashcard\asset\flashcard_FINAL_WITH_PROMPT_V4.xlsx');
      if (!await file.exists()) {
        return;
      }
      final bytes = await file.readAsBytes();

      // 1. Get available sheets
      final sheets = await ExcelService.getAvailableSheets(bytes);
      expect(sheets, contains('Main (Original)'));
      expect(sheets, contains('Grammar (Original)'));
      expect(sheets, contains('Main (Wuthuring)'));
      expect(sheets, contains('Grammar (Wuthuring)'));

      // 2. Get metadata for Main (Original)
      final meta = await ExcelService.getFileMetadataFromBytes(
        bytes,
        'flashcard_FINAL_WITH_PROMPT_V4.xlsx',
        targetSheetName: 'Main (Original)',
      );
      expect(meta.sheetName, 'Main (Original)');
      expect(meta.totalRows, greaterThan(10000));
      expect(meta.columnHeaders, contains('kata'));

      // 3. Parse deck for Main (Original)
      final deck = await ExcelService.parseExcelFileFromBytes(
        bytes,
        'Test Main Deck',
        targetSheetName: 'Main (Original)',
      );
      expect(deck.cards.length, greaterThan(10000));
      expect(deck.columnHeaders, contains('kata'));
    });
  });
}
