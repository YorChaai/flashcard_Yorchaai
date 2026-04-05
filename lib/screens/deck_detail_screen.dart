import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../models/order_mode.dart';
import '../models/deck.dart';
import '../models/font_size_settings.dart';
import 'flashcard_screen.dart';
import 'learning_preview_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  OrderMode _selectedMode = OrderMode.normal;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: '1');
    _toController = TextEditingController();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set _toController when deck changes or first load
    final deck = context.read<DeckProvider>().selectedDeck;
    if (deck != null && _toController.text.isEmpty) {
      _toController.text = deck.totalCards.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckProvider>().selectedDeck;

    if (deck == null) {
      return const Scaffold(
        body: Center(child: Text('No deck selected')),
      );
    }

    // Set _toController if empty (moved from here to didChangeDependencies)

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      runSpacing: 16,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.format_list_numbered, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '${deck.totalCards}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Total Cards'),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.view_column, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '${deck.columnCount}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Columns'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Column Headers section with edit button
                    Row(
                      children: [
                        const Text(
                          'Column Headers:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showColumnEditDialog(context, deck),
                          tooltip: 'Edit Column Settings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: deck.columnHeaders.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(
                            '${entry.key + 1}. ${entry.value}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Learning Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available data: 1 - ${deck.totalCards}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _previewLearning(deck),
                          icon: const Icon(Icons.preview, size: 20),
                          label: const Text('Preview'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fromController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'From',
                              hintText: '1',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _toController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'To',
                              hintText: deck.totalCards.toString(),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order Mode
            const Text(
              'Order Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Radio<OrderMode>(
                        // ignore: deprecated_member_use
                        value: OrderMode.normal,
                        // ignore: deprecated_member_use
                        groupValue: _selectedMode,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                            });
                          }
                        },
                      ),
                      title: const Text('Normal'),
                      subtitle: const Text('Original order (as in Excel)'),
                    ),
                    ListTile(
                      leading: Radio<OrderMode>(
                        // ignore: deprecated_member_use
                        value: OrderMode.reverse,
                        // ignore: deprecated_member_use
                        groupValue: _selectedMode,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                            });
                          }
                        },
                      ),
                      title: const Text('Reverse'),
                      subtitle: const Text('Reversed order'),
                    ),
                    ListTile(
                      leading: Radio<OrderMode>(
                        // ignore: deprecated_member_use
                        value: OrderMode.random,
                        // ignore: deprecated_member_use
                        groupValue: _selectedMode,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                            });
                          }
                        },
                      ),
                      title: const Text('Random'),
                      subtitle: const Text('Shuffled order'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Start Button
            ElevatedButton(
              onPressed: _startLearning,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Start Learning',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startLearning() {
    final deck = context.read<DeckProvider>().selectedDeck;
    if (deck == null || deck.cards.isEmpty) return;

    final from = int.tryParse(_fromController.text) ?? 1;
    final to = int.tryParse(_toController.text) ?? deck.totalCards;

    if (from < 1 || to < 1 || from > deck.totalCards || to > deck.totalCards) {
      _showRangeError('Range harus di antara 1 sampai ${deck.totalCards}.');
      return;
    }

    if (from > to) {
      _showRangeError('Nilai "From" tidak boleh lebih besar dari "To".');
      return;
    }

    final selectedCards = deck.cards.sublist(from - 1, to);
    if (selectedCards.isEmpty) {
      _showRangeError('Tidak ada data pada range yang dipilih.');
      return;
    }

    context.read<LearningSessionProvider>().startSession(
          selectedCards,
          _selectedMode,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FlashcardScreen(),
        settings: const RouteSettings(name: 'FlashcardScreen'),
      ),
    );
  }

  void _previewLearning(Deck deck) {
    if (deck.cards.isEmpty) return;

    final from = int.tryParse(_fromController.text) ?? 1;
    final to = int.tryParse(_toController.text) ?? deck.totalCards;

    if (from < 1 || to < 1 || from > deck.totalCards || to > deck.totalCards) {
      _showRangeError('Range harus di antara 1 sampai ${deck.totalCards}.');
      return;
    }

    if (from > to) {
      _showRangeError('Nilai "From" tidak boleh lebih besar dari "To".');
      return;
    }

    final selectedCards = deck.cards.sublist(from - 1, to);
    if (selectedCards.isEmpty) {
      _showRangeError('Tidak ada data pada range yang dipilih.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningPreviewScreen(
          previewCards: selectedCards,
          columnHeaders: deck.columnHeaders,
        ),
      ),
    );
  }

  void _showRangeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showColumnEditDialog(BuildContext context, Deck deck) {
    // State untuk urutan kolom saat ini
    final columnOrder = List<int>.generate(deck.columnCount, (i) => i);
    final columnHeaders = List<String>.from(deck.columnHeaders);

    // Helper functions
    String formatFontSize(double size) {
      if (size == size.toInt()) {
        return size.toInt().toString();
      }
      return size.toString();
    }

    double parseFontSize(String input) {
      final intValue = int.tryParse(input);
      if (intValue != null) return intValue.toDouble();
      return double.tryParse(input) ?? 40.0;
    }

    // Controllers untuk font sizes (use deck override)
    final mainFontSizeController = TextEditingController(
      text: formatFontSize(deck.mainFontSize),
    );
    final subFontSizeController = TextEditingController(
      text: formatFontSize(deck.subFontSize),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void moveColumn(int index, bool moveUp) {
            setDialogState(() {
              final targetIndex = moveUp ? index - 1 : index + 1;
              if (targetIndex >= 0 && targetIndex < columnOrder.length) {
                // Swap positions
                final temp = columnOrder[index];
                columnOrder[index] = columnOrder[targetIndex];
                columnOrder[targetIndex] = temp;

                // Swap headers untuk display
                final tempHeader = columnHeaders[index];
                columnHeaders[index] = columnHeaders[targetIndex];
                columnHeaders[targetIndex] = tempHeader;
              }
            });
          }

          return AlertDialog(
            title: const Text('Column Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Column Order
                  const Text(
                    'Column Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: List.generate(
                        columnOrder.length,
                        (index) => Container(
                          margin: EdgeInsets.only(
                            bottom: index < columnOrder.length - 1 ? 8 : 0,
                          ),
                          child: Row(
                            children: [
                              // Column number
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Column header name
                              Expanded(
                                child: Text(
                                  columnHeaders[index],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Up button
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_upward,
                                  size: 20,
                                  color: index == 0
                                      ? Colors.grey[600]
                                      : Theme.of(context).primaryColor,
                                ),
                                onPressed: index == 0
                                    ? null
                                    : () => moveColumn(index, true),
                                tooltip: 'Move Up',
                              ),
                              // Down button
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_downward,
                                  size: 20,
                                  color: index == columnOrder.length - 1
                                      ? Colors.grey[600]
                                      : Theme.of(context).primaryColor,
                                ),
                                onPressed: index == columnOrder.length - 1
                                    ? null
                                    : () => moveColumn(index, false),
                                tooltip: 'Move Down',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Font Size Settings
                  Row(
                    children: [
                      const Text(
                        'Font Size Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Theme.of(context).primaryColor),
                        ),
                        child: Text(
                          FontSizeSettings.getCurrentPlatformLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: mainFontSizeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Main Column (Kolom 1)',
                            hintText: '40',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: subFontSizeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Sub Columns (Kolom 2-6)',
                            hintText: '8',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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
                onPressed: () {
                  // Cleanup controllers
                  mainFontSizeController.dispose();
                  subFontSizeController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Parse font sizes - support both int and float input
                  final newMainFontSize = parseFontSize(mainFontSizeController.text);
                  final newSubFontSize = parseFontSize(subFontSizeController.text);

                  // Validate font sizes
                  if (newMainFontSize <= 0 || newSubFontSize <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Font size harus lebih dari 0'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Apply column reorder using proper permutation mapping
                  // columnOrder[i] = original index of column that should be at position i
                  var updatedDeck = deck;

                  // Apply swaps to transform current order to target order
                  for (int i = 0; i < columnOrder.length; i++) {
                    if (columnOrder[i] != i) {
                      // Find where column i currently is
                      final findIndex = columnOrder.indexWhere((idx) => idx == i);
                      if (findIndex != -1 && findIndex != i) {
                        // Swap in columnOrder array
                        final temp = columnOrder[i];
                        columnOrder[i] = columnOrder[findIndex];
                        columnOrder[findIndex] = temp;
                        // Apply reorder to deck
                        updatedDeck = updatedDeck.reorderColumn(findIndex, i);
                      }
                    }
                  }

                  // Update font sizes
                  updatedDeck = updatedDeck.copyWith(
                    mainFontSize: newMainFontSize,
                    subFontSize: newSubFontSize,
                  );

                  // Save to provider
                  final deckProvider = context.read<DeckProvider>();
                  await deckProvider.updateDeck(updatedDeck);

                  // Check if widget is still mounted before using context
                  if (!context.mounted) return;

                  // Cleanup controllers
                  mainFontSizeController.dispose();
                  subFontSizeController.dispose();

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Column settings saved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
