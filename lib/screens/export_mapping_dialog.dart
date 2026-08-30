import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/excel_service.dart';

class ExportColumnItem {
  final int index;
  final String title;
  final bool isScore;
  bool isEnabled;

  ExportColumnItem({
    required this.index,
    required this.title,
    required this.isScore,
    this.isEnabled = true,
  });
}

class ExportMappingResult {
  final List<int> exportOrder;
  final String fileName;

  ExportMappingResult({
    required this.exportOrder,
    required this.fileName,
  });
}

class ExportMappingDialog extends StatefulWidget {
  final Deck deck;

  const ExportMappingDialog({super.key, required this.deck});

  @override
  State<ExportMappingDialog> createState() => _ExportMappingDialogState();
}

class _ExportMappingDialogState extends State<ExportMappingDialog> {
  late List<ExportColumnItem> _items;
  late TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: 'Export_${widget.deck.name}');
    _initItems();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _initItems() {
    _items = [];
    // 1. Add all deck columns
    for (int i = 0; i < widget.deck.columnHeaders.length; i++) {
      _items.add(
        ExportColumnItem(
          index: i,
          title: widget.deck.columnHeaders[i],
          isScore: false,
          isEnabled: true,
        ),
      );
    }
    // 2. Add score column at the end
    _items.add(
      ExportColumnItem(
        index: ExcelService.scoreColumnIndex,
        title: 'score',
        isScore: true,
        isEnabled: true,
      ),
    );
  }

  int _getActiveColNumber(int itemIndex) {
    int count = 0;
    for (int i = 0; i <= itemIndex; i++) {
      if (_items[i].isEnabled) count++;
    }
    return count;
  }

  void _onExport() {
    final enabledItems = _items.where((it) => it.isEnabled).toList();
    if (enabledItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih setidaknya 1 kolom untuk diekspor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String rawName = _fileNameController.text.trim();
    if (rawName.isEmpty) {
      rawName = 'Export_${widget.deck.name}';
    }
    // Strip trailing .xlsx if manually typed
    rawName = rawName.replaceAll(RegExp(r'\.xlsx$', caseSensitive: false), '');
    final finalFileName = '$rawName.xlsx';

    final exportOrder = enabledItems.map((it) => it.index).toList();
    Navigator.of(context).pop(ExportMappingResult(
      exportOrder: exportOrder,
      fileName: finalFileName,
    ));
  }

  void _selectAll(bool select) {
    setState(() {
      for (final item in _items) {
        item.isEnabled = select;
      }
    });
  }

  void _resetOrder() {
    setState(() {
      _initItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = _items.where((it) => it.isEnabled).length;

    return AlertDialog(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune_rounded, color: Colors.blueAccent),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Pengaturan Kolom Export Excel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(320.0, 520.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom File Name Field
              const Text(
                'Nama File Hasil Export:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _fileNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixText: '.xlsx',
                  hintText: 'Ketik nama file...',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tarik (drag) untuk mengubah urutan kolom. Centang kolom yang ingin diekspor.',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
              const SizedBox(height: 10),
              // Action quick buttons
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _selectAll(true),
                    icon: const Icon(Icons.select_all, size: 16),
                    label: const Text('Pilih Semua', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _selectAll(false),
                    icon: const Icon(Icons.deselect, size: 16),
                    label: const Text('Hapus Semua', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetOrder,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset Urutan', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reorderable list
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).cardColor,
                ),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final item = _items.removeAt(oldIndex);
                      _items.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final colNumber = item.isEnabled ? _getActiveColNumber(index) : null;

                    return Material(
                      key: ValueKey('${item.isScore ? "score" : "col"}_${item.index}'),
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.15),
                              width: index < _items.length - 1 ? 1 : 0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            Checkbox(
                              value: item.isEnabled,
                              activeColor: Colors.blueAccent,
                              onChanged: (val) {
                                setState(() {
                                  item.isEnabled = val ?? true;
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            // Column Name & Score indicator
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: item.isEnabled ? null : Colors.grey,
                                        decoration: item.isEnabled ? null : TextDecoration.lineThrough,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.isScore) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.stars_rounded, size: 13, color: Colors.amber),
                                          SizedBox(width: 4),
                                          Text(
                                            'Skor Kartu',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Target Excel Column Badge (Deterministic & Accurate)
                            if (item.isEnabled && colNumber != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Kolom $colNumber',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Dilewati',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ),
                            const SizedBox(width: 8),
                            // Drag Handle
                            const Icon(
                              Icons.drag_indicator_rounded,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Info Footer
              Text(
                '$enabledCount dari ${_items.length} kolom akan diekspor ke file Excel.',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueAccent),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: enabledCount > 0 ? _onExport : null,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export Excel'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
