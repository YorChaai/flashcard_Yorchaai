import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import '../models/flashcard_card.dart';
import '../models/deck.dart';

class FileMetadata {
  final String fileName;
  final String sheetName;
  final int columnCount;
  final int totalRows;
  final List<String> columnHeaders;
  final List<Map<String, dynamic>> previewData;

  FileMetadata({
    required this.fileName,
    required this.sheetName,
    required this.columnCount,
    required this.totalRows,
    required this.columnHeaders,
    required this.previewData,
  });
}

class ExcelService {
  static String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'\.xlsx?$', caseSensitive: false), '');
  }

  static Future<Deck> parseExcelFile(
    String filePath,
    String deckName,
  ) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return parseExcelFileFromBytes(
      bytes,
      deckName,
      fileName: file.path.split(Platform.pathSeparator).last,
    );
  }

  static Future<Deck> parseExcelFileFromBytes(
    List<int> bytes,
    String deckName, {
    String? fileName,
  }) async {
    debugPrint('>>> ExcelService: Parsing deck from bytes (${bytes.length} bytes)...');
    try {
      final excel = Excel.decodeBytes(bytes);
      return _buildDeckFromExcel(excel, deckName);
    } catch (e) {
      debugPrint('>>> ExcelService Deck Standard Parse Failed: $e');
      debugPrint('>>> ExcelService Deck Fallback Parser: Activating...');
      try {
        final decoder = SpreadsheetDecoder.decodeBytes(bytes);
        final deck = _buildDeckFromDecoder(decoder, deckName);
        debugPrint('>>> ExcelService Deck Fallback Parser: Success!');
        return deck;
      } catch (fallbackError) {
        debugPrint('>>> ExcelService Deck Fallback Parser Failed: $fallbackError');
        throw Exception(
          'Gagal menyimpan dataset dari file Excel. Pastikan format .xlsx standar tanpa password/macros.',
        );
      }
    }
  }

  static Deck _buildDeckFromExcel(Excel excel, String deckName) {
    final cards = <FlashcardCard>[];
    List<String> headers = [];
    int dataColumnCount = 0;

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table]!;

      if (sheet.rows.isEmpty) {
        throw Exception('Excel file is empty');
      }

      final headerRow = sheet.rows[0];
      dataColumnCount = headerRow.length.clamp(1, 6);

      for (int i = 0; i < dataColumnCount && i < headerRow.length; i++) {
        headers.add(headerRow[i]?.value?.toString() ?? 'Column ${i + 1}');
      }

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        final col1 = row[0]?.value?.toString();
        if (col1 == null || col1.trim().isEmpty) continue;

        cards.add(
          FlashcardCard(
            col1: col1,
            col2: dataColumnCount >= 2 && row.length > 1
                ? row[1]?.value?.toString()
                : null,
            col3: dataColumnCount >= 3 && row.length > 2
                ? row[2]?.value?.toString()
                : null,
            col4: dataColumnCount >= 4 && row.length > 3
                ? row[3]?.value?.toString()
                : null,
            col5: dataColumnCount >= 5 && row.length > 4
                ? row[4]?.value?.toString()
                : null,
            col6: dataColumnCount >= 6 && row.length > 5
                ? row[5]?.value?.toString()
                : null,
            columnCount: dataColumnCount,
          ),
        );
      }

      break;
    }

    if (cards.isEmpty) {
      throw Exception('No valid data found. Ensure column 1 has text data.');
    }

    return Deck(
      name: deckName,
      columnCount: dataColumnCount,
      columnHeaders: headers,
      cards: cards,
    );
  }

  static Deck _buildDeckFromDecoder(
    SpreadsheetDecoder decoder,
    String deckName,
  ) {
    final cards = <FlashcardCard>[];
    List<String> headers = [];
    int dataColumnCount = 0;

    for (var sheetName in decoder.tables.keys) {
      final table = decoder.tables[sheetName]!;

      if (table.rows.isEmpty) {
        throw Exception('Excel file is empty');
      }

      final headerRow = table.rows[0];
      dataColumnCount = headerRow.length.clamp(1, 6);

      for (int i = 0; i < dataColumnCount && i < headerRow.length; i++) {
        headers.add(headerRow[i]?.toString() ?? 'Column ${i + 1}');
      }

      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isEmpty) continue;

        final col1 = row[0]?.toString();
        if (col1 == null || col1.trim().isEmpty) continue;

        cards.add(
          FlashcardCard(
            col1: col1,
            col2: dataColumnCount >= 2 && row.length > 1 ? row[1]?.toString() : null,
            col3: dataColumnCount >= 3 && row.length > 2 ? row[2]?.toString() : null,
            col4: dataColumnCount >= 4 && row.length > 3 ? row[3]?.toString() : null,
            col5: dataColumnCount >= 5 && row.length > 4 ? row[4]?.toString() : null,
            col6: dataColumnCount >= 6 && row.length > 5 ? row[5]?.toString() : null,
            columnCount: dataColumnCount,
          ),
        );
      }

      break;
    }

    if (cards.isEmpty) {
      throw Exception('No valid data found. Ensure column 1 has text data.');
    }

    return Deck(
      name: deckName,
      columnCount: dataColumnCount,
      columnHeaders: headers,
      cards: cards,
    );
  }

  static Future<FileMetadata> getFileMetadata(String filePath) async {
    final file = File(filePath);
    final fileName = file.path.split(Platform.pathSeparator).last;
    final bytes = await file.readAsBytes();
    return getFileMetadataFromBytes(bytes, fileName);
  }

  static Future<FileMetadata> getFileMetadataFromBytes(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      debugPrint('>>> ExcelService: Decoding Excel bytes (${bytes.length} bytes)...');
      final excel = Excel.decodeBytes(bytes);
      debugPrint('>>> ExcelService: Decoded successfully');

      for (var table in excel.tables.keys) {
        final sheetName = table.toString();
        debugPrint('>>> ExcelService: Processing sheet: $sheetName');
        final sheet = excel.tables[table]!;

        if (sheet.rows.isEmpty) {
          debugPrint('>>> ExcelService: Sheet $sheetName is empty, skipping');
          continue;
        }

        final headerRow = sheet.rows[0];
        final columnCount = headerRow.length.clamp(1, 6);
        List<String> headers = [];

        for (int i = 0; i < columnCount && i < headerRow.length; i++) {
          headers.add(headerRow[i]?.value?.toString() ?? 'Column ${i + 1}');
        }

        List<Map<String, dynamic>> allRows = [];

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.isNotEmpty && row[0]?.value != null) {
            final col1 = row[0]?.value?.toString();
            if (col1 != null && col1.trim().isNotEmpty) {
              Map<String, dynamic> rowData = {'col1': col1};
              for (int j = 1; j < columnCount && j < row.length; j++) {
                rowData['col${j + 1}'] = row[j]?.value?.toString();
              }
              allRows.add(rowData);
            }
          }
        }

        if (allRows.isNotEmpty) {
          final previewData = allRows.length <= 32
              ? allRows
              : [
                  ...allRows.take(29),
                  ...allRows.skip(allRows.length - 3),
                ];

          return FileMetadata(
            fileName: _sanitizeFileName(fileName),
            sheetName: sheetName,
            columnCount: columnCount,
            totalRows: allRows.length,
            columnHeaders: headers,
            previewData: previewData,
          );
        }
      }

      throw Exception('No valid data found');
    } catch (e) {
      debugPrint('>>> ExcelService Standard Parse Failed: $e');
      rethrow;
    }
  }

  static Future<FileMetadata> getFileMetadataFallback(
    List<int> bytes,
    String fileName,
  ) async {
    debugPrint('>>> Fallback Parser: Activating...');
    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);

      for (var sheetName in decoder.tables.keys) {
        final table = decoder.tables[sheetName]!;
        if (table.rows.isEmpty) {
          debugPrint('>>> Fallback Parser: Sheet $sheetName is empty, skipping');
          continue;
        }

        final headerRow = table.rows[0];
        final columnCount = headerRow.length.clamp(1, 6);
        List<String> headers = [];
        for (int i = 0; i < columnCount && i < headerRow.length; i++) {
          headers.add(headerRow[i]?.toString() ?? 'Column ${i + 1}');
        }

        List<Map<String, dynamic>> allRows = [];
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row.isNotEmpty) {
            final col1 = row[0]?.toString();
            if (col1 != null && col1.trim().isNotEmpty) {
              Map<String, dynamic> rowData = {'col1': col1};
              for (int j = 1; j < columnCount && j < row.length; j++) {
                rowData['col${j + 1}'] = row[j]?.toString();
              }
              allRows.add(rowData);
            }
          }
        }

        if (allRows.isNotEmpty) {
          final previewData = allRows.length <= 32
              ? allRows
              : [
                  ...allRows.take(29),
                  ...allRows.skip(allRows.length - 3),
                ];

          debugPrint('>>> Fallback Parser: Success! Found ${allRows.length} rows');
          return FileMetadata(
            fileName: _sanitizeFileName(fileName),
            sheetName: sheetName,
            columnCount: columnCount,
            totalRows: allRows.length,
            columnHeaders: headers,
            previewData: previewData,
          );
        }
      }

      throw Exception('Fallback also found no valid data');
    } catch (e) {
      debugPrint('>>> Fallback Parser Failed: $e');
      throw Exception(
        'Gagal membaca file. Pastikan format .xlsx standar tanpa password/macros.',
      );
    }
  }
}
