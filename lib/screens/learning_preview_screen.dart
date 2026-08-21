import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard_card.dart';
import '../providers/app_providers.dart';

class LearningPreviewScreen extends StatefulWidget {
  final List<FlashcardCard> previewCards;
  final List<String> columnHeaders;

  const LearningPreviewScreen({
    super.key,
    required this.previewCards,
    required this.columnHeaders,
  });

  @override
  State<LearningPreviewScreen> createState() => _LearningPreviewScreenState();
}

class _LearningPreviewScreenState extends State<LearningPreviewScreen> {
  late List<FlashcardCard> _previewCards;

  @override
  void initState() {
    super.initState();
    _previewCards = List.from(widget.previewCards);
  }

  void _confirmDelete(FlashcardCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Baris'),
        content: Text('Yakin ingin menghapus kata "${card.columns.isNotEmpty ? card.columns[0] : ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<DeckProvider>();
              final currentDeck = provider.selectedDeck;
              if (currentDeck != null) {
                final newDeck = currentDeck.removeCard(card.id);
                await provider.updateDeck(newDeck);
              }
              setState(() {
                _previewCards.removeWhere((c) => c.id == card.id);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Baris berhasil dihapus')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Preview'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDataPreviewTable(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDataPreviewTable(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👀 Data Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24.0,
                columns: [
                  const DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                  ...widget.columnHeaders.map((header) => DataColumn(
                        label: Text(
                          header,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )),
                  const DataColumn(label: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _buildPreviewRows(context),
              ),
            ),
            if (_previewCards.length > 100)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  '(${_previewCards.length - 99} more rows hidden)',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildPreviewRows(BuildContext context) {
    List<DataRow> rows = [];
    final totalRows = _previewCards.length;

    // Up to 98 items plus 1 skip array plus 1 last item = 100 items limit logic
    int firstRowCount = (totalRows <= 100) ? totalRows : 98;

    for (int i = 0; i < firstRowCount; i++) {
      rows.add(_createDataRow(_previewCards[i], i + 1));
    }

    // Skip indicator
    if (totalRows > 100) {
      rows.add(DataRow(
        cells: [
          DataCell(
            Text(
              '...',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
          for (int i = 0; i < widget.columnHeaders.length + 2; i++) // +1 for score, +1 for aksi
            DataCell(Text(
              '...',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            )),
        ],
      ));
    }

    // Last row
    if (totalRows > 100) {
      rows.add(_createDataRow(_previewCards.last, totalRows));
    }

    return rows;
  }

  DataRow _createDataRow(FlashcardCard card, int absoluteIndex) {
    final columns = card.allColumns;
    return DataRow(
      cells: [
        DataCell(Text(absoluteIndex.toString())),
        for (int i = 0; i < widget.columnHeaders.length; i++)
          DataCell(
            Text(
              i < columns.length ? columns[i] : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        DataCell(Text(card.score.toString())),
        DataCell(
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _confirmDelete(card),
            tooltip: 'Hapus baris',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
