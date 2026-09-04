import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../models/flashcard_card.dart';
import '../models/deck.dart';


class _ParseDeckParams {
  final List<int> bytes;
  final String deckName;
  final String? fileName;
  final String? targetSheetName;
  final List<int>? importOrder;
  const _ParseDeckParams(this.bytes, this.deckName, this.fileName, this.targetSheetName, this.importOrder);
}

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

  FileMetadata applyMapping(List<int> importOrder) {
    List<String> newHeaders = [];
    for (int idx in importOrder) {
      if (idx >= 0 && idx < columnHeaders.length) {
        newHeaders.add(columnHeaders[idx]);
      } else {
        newHeaders.add('Empty Column');
      }
    }

    List<Map<String, dynamic>> newPreviewData = [];
    for (var rowMap in previewData) {
      List<String> oldColumns = rowMap['columns'] as List<String>? ?? [];
      List<String> newColumns = [];
      for (int idx in importOrder) {
        if (idx >= 0 && idx < oldColumns.length) {
          newColumns.add(oldColumns[idx]);
        } else {
          newColumns.add('');
        }
      }
      newPreviewData.add({'columns': newColumns});
    }

    return FileMetadata(
      fileName: fileName,
      sheetName: sheetName,
      columnCount: newHeaders.length,
      totalRows: totalRows,
      columnHeaders: newHeaders,
      previewData: newPreviewData,
    );
  }
}

class ExcelService {
  static String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'\.xlsx?$', caseSensitive: false), '');
  }

  /// Automatically repairs Excel XML containing empty `<v></v>` or formula tags that break SpreadsheetDecoder
  static List<int> sanitizeExcelBytes(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final newArchive = Archive();

      bool modified = false;

      for (final file in archive) {
        if (file.isFile) {
          if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
            var xmlContent = utf8.decode(file.content as List<int>);

            // Regex to fix empty <v></v> or <v/> tags or formula cells without t
            final fixedXml = xmlContent.replaceAllMapped(
              RegExp(r'(<c\b[^>]*?)>(\s*(?:<f\b.*?</f>\s*)?(?:<v\s*/>|<v>\s*</v>)\s*</c>)'),
              (match) {
                var cTag = match.group(1)!;
                var inner = match.group(2)!;
                if (!cTag.contains(' t=')) {
                  cTag = '$cTag t="str"';
                }
                inner = inner.replaceAll(RegExp(r'<v\s*/>'), '<v></v>');
                return '$cTag>$inner';
              },
            );

            if (fixedXml != xmlContent) {
              modified = true;
              final newBytes = utf8.encode(fixedXml);
              newArchive.addFile(ArchiveFile(file.name, newBytes.length, newBytes));
              continue;
            }
          }
          newArchive.addFile(ArchiveFile(file.name, file.size, file.content));
        }
      }

      if (modified) {
        return ZipEncoder().encode(newArchive) ?? bytes;
      }
    } catch (_) {}
    return bytes;
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
    String? targetSheetName,
    List<int>? importOrder,
  }) async {
    debugPrint('>>> ExcelService: Parsing deck from bytes (${bytes.length} bytes) in background...');
    return compute(
      _parseExcelFromBytesIsolate,
      _ParseDeckParams(bytes, deckName, fileName, targetSheetName, importOrder),
    );
  }

  static Deck _parseExcelFromBytesIsolate(_ParseDeckParams params) {
    try {
      SpreadsheetDecoder decoder;
      try {
        decoder = SpreadsheetDecoder.decodeBytes(params.bytes);
      } catch (_) {
        final cleanBytes = sanitizeExcelBytes(params.bytes);
        decoder = SpreadsheetDecoder.decodeBytes(cleanBytes);
      }
      return _buildDeckFromDecoder(decoder, params.deckName,
          targetSheetName: params.targetSheetName, importOrder: params.importOrder);
    } catch (e) {
      throw Exception(
        'Gagal menyimpan dataset dari file Excel. Pastikan format .xlsx standar tanpa password/macros.',
      );
    }
  }

  static const int scoreColumnIndex = -2;

  static Future<List<int>> exportDeckToExcelBytes(Deck deck, {List<int>? exportOrder}) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Sheet1';

    // Default order: 0, 1, 2... and scoreColumnIndex (-2) at the end
    final order = exportOrder ?? [...List.generate(deck.columnCount, (i) => i), scoreColumnIndex];

    // Add headers (Syncfusion uses 1-based indexing)
    int colIndex = 1;
    for (int index in order) {
      if (index == scoreColumnIndex) {
        sheet.getRangeByIndex(1, colIndex).setText('score');
      } else if (index >= 0 && index < deck.columnHeaders.length) {
        sheet.getRangeByIndex(1, colIndex).setText(deck.columnHeaders[index]);
      } else {
        sheet.getRangeByIndex(1, colIndex).setText('Empty Column');
      }
      colIndex++;
    }

    // Add rows
    for (int i = 0; i < deck.cards.length; i++) {
      final card = deck.cards[i];
      final cols = card.allColumns;
      
      int cIndex = 1;
      for (int index in order) {
        if (index == scoreColumnIndex) {
          sheet.getRangeByIndex(i + 2, cIndex).setNumber(card.score.toDouble());
        } else if (index >= 0 && index < cols.length) {
          sheet.getRangeByIndex(i + 2, cIndex).setText(cols[index]);
        } else {
          sheet.getRangeByIndex(i + 2, cIndex).setText('');
        }
        cIndex++;
      }
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  static Deck _buildDeckFromDecoder(SpreadsheetDecoder decoder, String deckName, {String? targetSheetName, List<int>? importOrder}) {
    final cards = <FlashcardCard>[];
    List<String> headers = [];
    int dataColumnCount = 0;

    for (var sheetName in decoder.tables.keys) {
      if (targetSheetName != null && sheetName != targetSheetName) continue;
      
      final table = decoder.tables[sheetName]!;

      if (table.rows.isEmpty) {
        throw Exception('Excel file is empty');
      }

      final headerRow = table.rows[0];
      int scoreColumnIndex = -1;
      for (int i = 0; i < headerRow.length; i++) {
        final headerValue = headerRow[i]?.toString().toLowerCase().trim();
        if (headerValue == 'score' || headerValue == 'skor' || headerValue == 'nilai' || headerValue == '_appmeta_score') {
          scoreColumnIndex = i;
          break;
        }
      }

      List<String> rawHeaders = [];
      for (int i = 0; i < headerRow.length; i++) {
        rawHeaders.add(headerRow[i]?.toString() ?? 'Column ${rawHeaders.length + 1}');
      }
      
      dataColumnCount = rawHeaders.length;

      // Apply importOrder to headers
      if (importOrder != null) {
        for (int idx in importOrder) {
          if (idx >= 0 && idx < rawHeaders.length) {
            headers.add(rawHeaders[idx]);
          } else {
            headers.add('Empty Column');
          }
        }
      } else {
        headers = rawHeaders;
      }

      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isEmpty) continue;

        List<String> rawColumns = [];
        for (int j = 0; j < row.length; j++) {
          rawColumns.add(row[j]?.toString() ?? '');
        }

        // Apply importOrder to row columns
        List<String> cardColumns = [];
        if (importOrder != null) {
          for (int idx in importOrder) {
            if (idx >= 0 && idx < rawColumns.length) {
              cardColumns.add(rawColumns[idx]);
            } else {
              cardColumns.add('');
            }
          }
        } else {
          cardColumns = rawColumns;
        }

        // Pad with empty strings if row is shorter than expected data columns
        while (cardColumns.length < dataColumnCount) {
          cardColumns.add('');
        }
        
        // Ensure at least col1 has data
        if (cardColumns.isEmpty || cardColumns[0].trim().isEmpty) continue;

        int score = 0;
        if (scoreColumnIndex != -1 && scoreColumnIndex < row.length) {
          final rawVal = row[scoreColumnIndex];
          if (rawVal is num) {
            score = rawVal.round();
          } else if (rawVal != null) {
            final strVal = rawVal.toString().trim();
            score = int.tryParse(strVal) ?? (double.tryParse(strVal)?.round() ?? 0);
          }
        }

        cards.add(
          FlashcardCard(
            columns: cardColumns,
            score: score,
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

  static Future<List<int>?> attemptPythonRepair(String filePath) async {
    try {
      debugPrint('>>> ExcelService: Attempting Python repair for broken Excel...');
      final tempDir = Directory.systemTemp;
      final tempOut = '${tempDir.path}${Platform.pathSeparator}repaired_excel_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      final script = '''
import pandas as pd
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

try:
    xls = pd.ExcelFile(input_file)
    with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
        for sheet_name in xls.sheet_names:
            df = pd.read_excel(xls, sheet_name=sheet_name)
            df = df.fillna('')
            df.to_excel(writer, sheet_name=sheet_name, index=False)
    sys.exit(0)
except Exception as e:
    sys.exit(1)
''';

      final scriptFile = File('${tempDir.path}${Platform.pathSeparator}repair.py');
      await scriptFile.writeAsString(script);
      
      final result = await Process.run('python', [scriptFile.path, filePath, tempOut]);
      
      if (result.exitCode == 0) {
        final repairedFile = File(tempOut);
        if (await repairedFile.exists()) {
          debugPrint('>>> ExcelService: Python repair successful!');
          return await repairedFile.readAsBytes();
        }
      } else {
        debugPrint('>>> ExcelService: Python repair failed. Exit code: ${result.exitCode}');
        debugPrint(result.stderr.toString());
      }
    } catch (e) {
      debugPrint('>>> ExcelService: Failed to run python repair: $e');
    }
    return null;
  }

  static Future<List<String>> getAvailableSheets(List<int> bytes) async {
    return compute(_getAvailableSheetsSync, bytes);
  }

  // --- Isolate helper: list sheets ---
  static List<String> _getAvailableSheetsSync(List<int> bytes) {
    List<String> validSheets = [];
    try {
      SpreadsheetDecoder decoder;
      try {
        decoder = SpreadsheetDecoder.decodeBytes(bytes);
      } catch (_) {
        final cleanBytes = sanitizeExcelBytes(bytes);
        decoder = SpreadsheetDecoder.decodeBytes(cleanBytes);
      }
      for (var table in decoder.tables.keys) {
        if (decoder.tables[table]!.rows.isNotEmpty) {
          validSheets.add(table.toString());
        }
      }
      if (validSheets.isNotEmpty) return validSheets;
    } catch (_) {}
    return validSheets;
  }

  // --- Isolate helper: metadata ---
  static FileMetadata _getFileMetadataSync(Map<String, dynamic> args) {
    final bytes = args['bytes'] as List<int>;
    final fileName = args['fileName'] as String;
    final targetSheetName = args['targetSheetName'] as String?;

    SpreadsheetDecoder decoder;
    try {
      decoder = SpreadsheetDecoder.decodeBytes(bytes);
    } catch (_) {
      final cleanBytes = sanitizeExcelBytes(bytes);
      decoder = SpreadsheetDecoder.decodeBytes(cleanBytes);
    }

    for (var sheetName in decoder.tables.keys) {
      if (targetSheetName != null && sheetName != targetSheetName) continue;

      final table = decoder.tables[sheetName]!;
      if (table.rows.isEmpty) continue;

      final headerRow = table.rows[0];

      final columnCount = headerRow.length;
      List<String> headers = [];
      for (int i = 0; i < headerRow.length; i++) {
        headers.add(headerRow[i]?.toString() ?? 'Column ${headers.length + 1}');
      }

      List<Map<String, dynamic>> allRows = [];
      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isNotEmpty) {
          List<String> rowColumns = [];
          for (int j = 0; j < row.length; j++) {
            rowColumns.add(row[j]?.toString() ?? '');
          }
          if (rowColumns.isNotEmpty && rowColumns[0].trim().isNotEmpty) {
            allRows.add({'columns': rowColumns});
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
  }

  static Future<FileMetadata> getFileMetadataFromBytes(
    List<int> bytes,
    String fileName, {
    String? targetSheetName,
  }) async {
    debugPrint('>>> ExcelService: Decoding Excel bytes (${bytes.length} bytes) via isolate...');
    try {
      return await compute(_getFileMetadataSync, {
        'bytes': bytes,
        'fileName': fileName,
        'targetSheetName': targetSheetName,
      });
    } catch (e) {
      debugPrint('>>> ExcelService Parse Failed: $e');
      throw Exception(
        'Gagal membaca file. Pastikan format .xlsx standar tanpa password/macros.',
      );
    }
  }
}
