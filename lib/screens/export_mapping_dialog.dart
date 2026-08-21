import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/deck.dart';

class ExportMappingDialog extends StatefulWidget {
  final Deck deck;

  const ExportMappingDialog({super.key, required this.deck});

  @override
  State<ExportMappingDialog> createState() => _ExportMappingDialogState();
}

class _ExportMappingDialogState extends State<ExportMappingDialog> {
  // Mapping from Flashcard Column Index to Excel Column Number (1-based)
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.deck.columnCount; i++) {
      // Default mapping: Column 1 -> Excel 1, etc.
      _controllers[i] = TextEditingController(text: (i + 1).toString());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onExport() {
    // Validate mapping
    final Map<int, int> flashcardToExcel = {};
    int maxExcelCol = 0;

    for (int i = 0; i < widget.deck.columnCount; i++) {
      final text = _controllers[i]!.text.trim();
      if (text.isEmpty) continue; // Skip if empty (exclude column)
      
      final excelCol = int.tryParse(text);
      if (excelCol == null || excelCol < 1) {
        _showError('Invalid column number for ${widget.deck.columnHeaders[i]}');
        return;
      }

      // Check duplicates
      if (flashcardToExcel.containsValue(excelCol)) {
        _showError('Excel column $excelCol is mapped multiple times!');
        return;
      }

      flashcardToExcel[i] = excelCol;
      if (excelCol > maxExcelCol) {
        maxExcelCol = excelCol;
      }
    }

    if (flashcardToExcel.isEmpty) {
      _showError('Please map at least one column.');
      return;
    }

    // Build the exportOrder array (-1 for empty slots)
    List<int> exportOrder = List.filled(maxExcelCol, -1);
    flashcardToExcel.forEach((flashcardColIdx, excelColNum) {
      exportOrder[excelColNum - 1] = flashcardColIdx;
    });

    Navigator.of(context).pop(exportOrder);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Map Export Columns'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nomor kolom Excel tujuan untuk masing-masing data. Kosongkan jika tidak ingin diekspor.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < widget.deck.columnCount; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        widget.deck.columnHeaders[i],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _controllers[i],
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Excel Col',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kolom score akan selalu ditambahkan secara otomatis di kolom paling akhir.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _onExport,
          child: const Text('Export'),
        ),
      ],
    );
  }
}
