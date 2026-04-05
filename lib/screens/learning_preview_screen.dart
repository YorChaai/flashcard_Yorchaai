import 'package:flutter/material.dart';
import '../models/flashcard_card.dart';

class LearningPreviewScreen extends StatelessWidget {
  final List<FlashcardCard> previewCards;
  final List<String> columnHeaders;

  const LearningPreviewScreen({
    super.key,
    required this.previewCards,
    required this.columnHeaders,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Preview'),
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
                columns: columnHeaders
                    .map((header) => DataColumn(
                          label: Text(
                            header,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
                rows: _buildPreviewRows(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildPreviewRows(BuildContext context) {
    List<DataRow> rows = [];
    final totalRows = previewCards.length;

    // Up to 98 items plus 1 skip array plus 1 last item = 100 items limit logic
    int firstRowCount = (totalRows <= 100) ? totalRows : 98;

    for (int i = 0; i < firstRowCount; i++) {
      rows.add(_createDataRow(previewCards[i], i + 1));
    }

    // Skip indicator
    if (totalRows > 100) {
      final skippedRows = totalRows - 99; // Total items minus shown ones
      rows.add(DataRow(
        cells: [
          DataCell(
            Text(
              '... ($skippedRows more rows hidden) ...',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
          for (int i = 1; i < columnHeaders.length; i++)
            const DataCell(Text('')),
        ],
      ));
    }

    // Last row
    if (totalRows > 100) {
      rows.add(_createDataRow(previewCards.last, totalRows));
    }

    return rows;
  }

  DataRow _createDataRow(FlashcardCard card, int absoluteIndex) {
    final columns = card.allColumns;
    return DataRow(
      cells: [
        for (int i = 0; i < columnHeaders.length; i++)
          DataCell(
            Text(
              i < columns.length ? columns[i] : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
