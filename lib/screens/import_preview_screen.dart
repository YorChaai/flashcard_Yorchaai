import 'package:flutter/material.dart';
import '../services/excel_service.dart';

class ImportPreviewScreen extends StatelessWidget {
  final String filePath;
  final FileMetadata metadata;

  const ImportPreviewScreen({
    super.key,
    required this.filePath,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File Information Card
                  _buildFileInformationCard(context),
                  const SizedBox(height: 16),

                  // Column Structure Card
                  _buildColumnStructureCard(context),
                  const SizedBox(height: 16),

                  // Data Preview Table
                  _buildDataPreviewTable(context),
                  const SizedBox(height: 16),

                  // Summary
                  _buildSummary(context),
                ],
              ),
            ),
          ),

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildFileInformationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📄 File Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('File Name', metadata.fileName),
            const SizedBox(height: 8),
            _buildInfoRow('Sheet Name', metadata.sheetName),
            const SizedBox(height: 8),
            _buildInfoRow('Total Columns', '${metadata.columnCount - 1}'),
            const SizedBox(height: 8),
            _buildInfoRow('Total Data', '${metadata.totalRows} rows'),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnStructureCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Column Structure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metadata.columnHeaders.asMap().entries.map((entry) {
                final index = entry.key;
                final header = entry.value;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Chip(
                  label: Text(
                    '[${index + 1}] $header',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  side: BorderSide(
                    color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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

            // Horizontal scrollable table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24.0,
                columns: metadata.columnHeaders
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
            if (metadata.totalRows > 32)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  '(${metadata.totalRows - 32} more rows hidden)',
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
    final previewData = metadata.previewData;
    final totalRows = metadata.totalRows;

    // First 29 rows
    int firstRowCount = (totalRows <= 32) ? totalRows : 29;

    for (int i = 0; i < firstRowCount && i < previewData.length; i++) {
      rows.add(_createDataRow(previewData[i]));
    }

    // Skip indicator
    if (totalRows > 32) {
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
          for (int i = 1; i < metadata.columnCount; i++)
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

    // Last 3 rows (already added in previewData)
    if (totalRows > 32) {
      for (int i = previewData.length - 3; i < previewData.length; i++) {
        if (i >= 0 && i < previewData.length) {
          rows.add(_createDataRow(previewData[i]));
        }
      }
    }

    return rows;
  }

  DataRow _createDataRow(Map<String, dynamic> rowData) {
    return DataRow(
      cells: [
        for (int i = 0; i < metadata.columnCount; i++)
          DataCell(
            Text(
              (rowData['columns'] as List<String>?)?.length != null && 
              i < (rowData['columns'] as List<String>).length
                  ? rowData['columns'][i].toString()
                  : '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 24),
            const SizedBox(width: 12),
            Text(
              'Total rows to import: ${metadata.totalRows} cards',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.download),
              label: const Text('Import Dataset'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Information'),
        content: const Text(
          'This preview shows the first 29 rows and last 3 rows of your Excel file.\n\n'
          '• Column 1 will be displayed as the main word (large font)\n'
          '• Columns 2-6 will be displayed as extra info (small font)\n\n'
          'Click "Import Dataset" to proceed with importing this file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
