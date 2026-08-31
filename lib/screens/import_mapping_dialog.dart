import 'package:flutter/material.dart';
import '../services/excel_service.dart';

class ImportMappingDialog extends StatefulWidget {
  final FileMetadata metadata;
  final bool showBackButton;

  const ImportMappingDialog({super.key, required this.metadata, this.showBackButton = false});

  @override
  State<ImportMappingDialog> createState() => _ImportMappingDialogState();
}

class _ImportMappingDialogState extends State<ImportMappingDialog> {
  int _numFlashcardColumns = 5;
  List<int?> _selectedExcelColumns = [];

  @override
  void initState() {
    super.initState();
    // Default to all columns in the dataset (unlimited)
    _numFlashcardColumns = widget.metadata.columnHeaders.length;
    if (_numFlashcardColumns < 1) _numFlashcardColumns = 1;

    _updateSelectionList(initial: true);
  }

  void _updateSelectionList({bool initial = false}) {
    final oldSelections = List<int?>.from(_selectedExcelColumns);
    _selectedExcelColumns = List.filled(_numFlashcardColumns, null);
    
    for (int i = 0; i < _numFlashcardColumns; i++) {
      if (i < oldSelections.length && !initial) {
        _selectedExcelColumns[i] = oldSelections[i];
      } else {
        // Automatically map if it makes sense
        if (i < widget.metadata.columnHeaders.length && !_selectedExcelColumns.contains(i)) {
          _selectedExcelColumns[i] = i;
        }
      }
    }
  }

  String _getPreviewText(int colIndex) {
    List<String> values = [];
    for (var rowMap in widget.metadata.previewData) {
      List<String> row = rowMap['columns'] as List<String>? ?? [];
      if (colIndex < row.length) {
        if (row[colIndex].trim().isNotEmpty) {
          values.add(row[colIndex].trim());
        }
      }
    }
    if (values.isEmpty) return '(Kosong)';
    return values.take(5).join(', ');
  }

  void _onProceed() {
    // Validate mapping
    final selectedSet = <int>{};
    for (int i = 0; i < _numFlashcardColumns; i++) {
      final col = _selectedExcelColumns[i];
      if (col != null) {
        if (selectedSet.contains(col)) {
          _showError('Kolom Excel "${widget.metadata.columnHeaders[col]}" dipilih lebih dari satu kali!');
          return;
        }
        selectedSet.add(col);
      }
    }

    if (selectedSet.isEmpty) {
      _showError('Pilih minimal satu kolom Excel untuk diimpor.');
      return;
    }

    // importOrder[flashcardColIdx] = excelColIdx (-1 for empty slots)
    List<int> importOrder = _selectedExcelColumns.map((e) => e ?? -1).toList();

    Navigator.of(context).pop(importOrder);
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
      title: const Text('Map Import Columns'),
      content: SizedBox(
        width: 500, // Fixed max width so it doesn't get too wide
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih berapa banyak kolom Flashcard yang ingin dibuat, lalu petakan ke kolom Excel yang sesuai.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text('Jumlah Kolom Flashcard:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _numFlashcardColumns,
                    items: List.generate(
                      widget.metadata.columnHeaders.length > 10 ? widget.metadata.columnHeaders.length : 10,
                      (index) => index + 1,
                    ).map((val) {
                      return DropdownMenuItem(value: val, child: Text('$val Kolom'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _numFlashcardColumns = val;
                          _updateSelectionList();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (int i = 0; i < _numFlashcardColumns; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14.0),
                          child: Text(
                            'Kolom ${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 14.0, right: 12.0),
                        child: Icon(Icons.arrow_forward, size: 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  isExpanded: true,
                                  value: _selectedExcelColumns[i],
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('(Kosong / Abaikan)'),
                                    ),
                                    for (int j = 0; j < widget.metadata.columnHeaders.length; j++)
                                      DropdownMenuItem<int?>(
                                        value: j,
                                        child: Text(widget.metadata.columnHeaders[j], overflow: TextOverflow.ellipsis),
                                      ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedExcelColumns[i] = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            if (_selectedExcelColumns[i] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _getPreviewText(_selectedExcelColumns[i]!),
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.showBackButton)
          TextButton(
            onPressed: () => Navigator.of(context).pop('BACK'),
            child: const Text('Kembali'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _onProceed,
          child: const Text('Lanjut'),
        ),
      ],
    );
  }
}

