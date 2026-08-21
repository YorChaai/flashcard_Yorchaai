import 'package:flutter/material.dart';

class SheetSelectionDialog extends StatelessWidget {
  final List<String> sheets;

  const SheetSelectionDialog({super.key, required this.sheets});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Sheet'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: sheets.length,
          itemBuilder: (context, index) {
            final sheet = sheets[index];
            return ListTile(
              title: Text(sheet),
              leading: const Icon(Icons.table_chart),
              onTap: () {
                Navigator.of(context).pop(sheet);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
