import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../models/order_mode.dart';
import '../models/deck.dart';
import '../models/font_size_settings.dart';
import '../models/sort_mode.dart';
import '../models/flashcard_card.dart';
import 'flashcard_screen.dart';
import 'learning_preview_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  OrderMode _selectedMode = OrderMode.normal;
  SortMode _sortMode = SortMode.original;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  bool _rangeInitialized = false;

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
    if (!_rangeInitialized) {
      final deck = context.read<DeckProvider>().selectedDeck;
      if (deck != null) {
        _fromController.text = (deck.lastLearningRangeStart ?? 1).toString();
        _toController.text = (deck.lastLearningRangeEnd ?? deck.totalCards).toString();
        _rangeInitialized = true;
      }
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

    // Fix for when starting from 0 cards
    if (int.tryParse(_toController.text) == 0 && deck.totalCards > 0) {
      _toController.text = deck.totalCards.toString();
    }

    // Set _toController if empty (moved from here to didChangeDependencies)

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
      ),
      floatingActionButton: deck.id == 'custom_mode_deck_default'
          ? FloatingActionButton(
              onPressed: () => _showAddCardDialog(context, deck),
              tooltip: 'Add Custom Card',
              child: const Icon(Icons.add),
            )
          : null,
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
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SortMode>(
                    isExpanded: true,
                    value: _sortMode,
                    items: const [
                      DropdownMenuItem(
                        value: SortMode.original,
                        child: Text('Original Order (As in File)'),
                      ),
                      DropdownMenuItem(
                        value: SortMode.lowestScore,
                        child: Text('Lowest Score First (Paling Tidak Tahu)'),
                      ),
                      DropdownMenuItem(
                        value: SortMode.highestScore,
                        child: Text('Highest Score First (Paling Banyak Tahu)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortMode = value;
                        });
                      }
                    },
                  ),
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
                          label: const Text('Library Preview'),
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

  List<FlashcardCard> _getSortedCards(Deck deck) {
    List<FlashcardCard> sortedList = List.from(deck.cards);
    switch (_sortMode) {
      case SortMode.lowestScore:
        sortedList.sort((a, b) => a.score.compareTo(b.score));
        break;
      case SortMode.highestScore:
        sortedList.sort((a, b) => b.score.compareTo(a.score));
        break;
      case SortMode.original:
        break;
    }
    return sortedList;
  }

  void _startLearning() {
    final deck = context.read<DeckProvider>().selectedDeck;
    if (deck == null || deck.cards.isEmpty) return;
    
    final sortedCards = _getSortedCards(deck);

    int from = int.tryParse(_fromController.text) ?? 1;
    int to = int.tryParse(_toController.text) ?? deck.totalCards;

    // Auto-clamp values
    if (from < 1) from = 1;
    if (from > deck.totalCards) from = deck.totalCards;
    
    if (to < 1) to = 1;
    if (to > deck.totalCards) to = deck.totalCards;

    if (from > to) {
      final temp = from;
      from = to;
      to = temp;
    }
    
    // Update UI to reflect clamped values
    _fromController.text = from.toString();
    _toController.text = to.toString();

    final selectedCards = sortedCards.sublist(from - 1, to);
    if (selectedCards.isEmpty) {
      _showRangeError('Tidak ada data pada range yang dipilih.');
      return;
    }

    final updatedDeck = deck.copyWith(
      lastLearningRangeStart: from,
      lastLearningRangeEnd: to,
    );
    context.read<DeckProvider>().updateDeck(updatedDeck);

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
    
    final sortedCards = _getSortedCards(deck);

    int from = int.tryParse(_fromController.text) ?? 1;
    int to = int.tryParse(_toController.text) ?? deck.totalCards;

    // Auto-clamp values
    if (from < 1) from = 1;
    if (from > deck.totalCards) from = deck.totalCards;
    
    if (to < 1) to = 1;
    if (to > deck.totalCards) to = deck.totalCards;

    if (from > to) {
      final temp = from;
      from = to;
      to = temp;
    }

    // Update UI to reflect clamped values
    _fromController.text = from.toString();
    _toController.text = to.toString();

    final selectedCards = sortedCards.sublist(from - 1, to);
    if (selectedCards.isEmpty) {
      _showRangeError('Tidak ada data pada range yang dipilih.');
      return;
    }

    final updatedDeck = deck.copyWith(
      lastLearningRangeStart: from,
      lastLearningRangeEnd: to,
    );
    context.read<DeckProvider>().updateDeck(updatedDeck);

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
    int visibleColumnCount = deck.visibleColumnCount.clamp(1, deck.columnCount);

    // Get global settings (Settings = source of truth)
    final themeProvider = context.read<ThemeProvider>();
    final fontSizeSettings = themeProvider.fontSizeSettings;

    // Helper functions
    String formatFontSize(double size) {
      if (size == size.toInt()) {
        return size.toInt().toString();
      }
      return size.toString();
    }

    double? parseFontSize(String input) {
      final intValue = int.tryParse(input);
      if (intValue != null) return intValue.toDouble();
      return double.tryParse(input); // Returns null if invalid
    }

    final fontSize1Controller = TextEditingController(
      text: formatFontSize(fontSizeSettings.currentFontSize1),
    );
    final fontSize23Controller = TextEditingController(
      text: formatFontSize(fontSizeSettings.currentFontSize23),
    );
    final fontSize45Controller = TextEditingController(
      text: formatFontSize(fontSizeSettings.currentFontSize45),
    );
    final fontSize6Controller = TextEditingController(
      text: formatFontSize(fontSizeSettings.currentFontSize6),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Column Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[800] 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[700]! 
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Show: ', 
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white70 
                                      : Colors.black87
                                )),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                dropdownColor: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[800] 
                                    : Colors.white,
                                value: visibleColumnCount,
                                isDense: true,
                                iconSize: 18,
                                iconEnabledColor: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : Colors.black,
                                ),
                                items: List.generate(deck.columnCount, (i) => i + 1).map((val) {
                                  return DropdownMenuItem(value: val, child: Text('$val'));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      visibleColumnCount = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
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
                          controller: fontSize1Controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          decoration: const InputDecoration(
                            labelText: 'Kolom 1 (Atas Tengah)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: fontSize23Controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          decoration: const InputDecoration(
                            labelText: 'Kolom 2 & 3',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: fontSize45Controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          decoration: const InputDecoration(
                            labelText: 'Kolom 4 & 5',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: fontSize6Controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          decoration: const InputDecoration(
                            labelText: 'Kolom 6 (Bawah)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Parse font sizes - support both int and float input
                  final double? newSize1 = parseFontSize(fontSize1Controller.text);
                  final double? newSize23 = parseFontSize(fontSize23Controller.text);
                  final double? newSize45 = parseFontSize(fontSize45Controller.text);
                  final double? newSize6 = parseFontSize(fontSize6Controller.text);

                  // Validate font sizes
                  if ((newSize1 != null && newSize1 <= 0) ||
                      (newSize23 != null && newSize23 <= 0) ||
                      (newSize45 != null && newSize45 <= 0) ||
                      (newSize6 != null && newSize6 <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Font size harus lebih dari 0'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Update GLOBAL SETTINGS (Settings = source of truth)
                  final themeProvider = context.read<ThemeProvider>();
                  final deckProvider = context.read<DeckProvider>();
                  final currentSettings = themeProvider.fontSizeSettings;

                  // Update appropriate platform settings
                  FontSizeSettings updatedSettings;
                  if (FontSizeSettings.isMobilePlatform()) {
                    updatedSettings = currentSettings.copyWith(
                      mobileFontSize1: newSize1 ?? currentSettings.mobileFontSize1,
                      mobileFontSize23: newSize23 ?? currentSettings.mobileFontSize23,
                      mobileFontSize45: newSize45 ?? currentSettings.mobileFontSize45,
                      mobileFontSize6: newSize6 ?? currentSettings.mobileFontSize6,
                    );
                  } else {
                    updatedSettings = currentSettings.copyWith(
                      pcFontSize1: newSize1 ?? currentSettings.pcFontSize1,
                      pcFontSize23: newSize23 ?? currentSettings.pcFontSize23,
                      pcFontSize45: newSize45 ?? currentSettings.pcFontSize45,
                      pcFontSize6: newSize6 ?? currentSettings.pcFontSize6,
                    );
                  }

                  await themeProvider.updateFontSizeSettings(updatedSettings);

                  // Apply column reorder to deck (deck only handles column order, not font sizes)
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

                  // Save deck (column order and visible count changes)
                  updatedDeck = updatedDeck.copyWith(visibleColumnCount: visibleColumnCount);
                  await deckProvider.updateDeck(updatedDeck);

                  // Check if context is still mounted before using it
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        fontSize1Controller.dispose();
        fontSize23Controller.dispose();
        fontSize45Controller.dispose();
        fontSize6Controller.dispose();
      });
    });
  }

  void _showAddCardDialog(BuildContext context, Deck currentDeck) {
    final kataController = TextEditingController();
    final artiController = TextEditingController();
    final deckProvider = context.read<DeckProvider>();
    final availableDecks = deckProvider.decks.where((d) => d.id != currentDeck.id).toList();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Kata Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: kataController,
                      decoration: const InputDecoration(
                        labelText: 'Kata',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: artiController,
                      decoration: const InputDecoration(
                        labelText: 'Arti',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final kata = kataController.text.trim();
                    final arti = artiController.text.trim();
                    if (kata.isEmpty) return;

                    List<String> newHeaders = List.from(currentDeck.columnHeaders);
                    if (newHeaders.length < 2) {
                      newHeaders = ['Kata', 'Arti'];
                    }

                    Deck targetDeck = currentDeck;
                    bool foundAny = false;
                    int addedCount = 0;

                    for (final deck in availableDecks) {
                      FlashcardCard? matchInDeck;
                      for (final card in deck.cards) {
                        if (card.columns.any((col) => col.toLowerCase().trim() == kata.toLowerCase())) {
                          matchInDeck = card;
                          break;
                        }
                      }

                      if (matchInDeck != null) {
                        foundAny = true;
                        addedCount++;
                        
                        List<String> newColumns = [kata, arti, deck.name]; // Source file di kolom ke-3
                        newColumns.addAll(matchInDeck.columns);
                        
                        int requiredCols = newColumns.length;
                        
                        // Perluas headers jika perlu
                        for (int i = newHeaders.length; i < requiredCols; i++) {
                          if (i == 2) {
                            newHeaders.add('Source File');
                          } else {
                            if (i - 3 >= 0 && i - 3 < deck.columnHeaders.length) {
                              newHeaders.add(deck.columnHeaders[i - 3]);
                            } else {
                              newHeaders.add('Col ${i + 1}');
                            }
                          }
                        }

                        // Samakan jumlah kolom dengan deck utama
                        if (newColumns.length > targetDeck.columnCount) {
                           targetDeck = targetDeck.upgradeColumnCount(newColumns.length, newHeaders);
                        } else if (newColumns.length < targetDeck.columnCount) {
                           while(newColumns.length < targetDeck.columnCount) {
                             newColumns.add('');
                           }
                        }

                        final newCard = FlashcardCard(columns: newColumns);
                        targetDeck = targetDeck.addCard(newCard);
                      }
                    }

                    // Jika tidak ditemukan di file manapun
                    if (!foundAny) {
                        addedCount = 1;
                        List<String> newColumns = [kata, arti, 'Manual/Custom']; // Pastikan ada kolom ke-3
                        
                        int requiredCols = newColumns.length;
                        for (int i = newHeaders.length; i < requiredCols; i++) {
                          if (i == 2) {
                            newHeaders.add('Source File');
                          } else {
                            newHeaders.add('Col ${i + 1}');
                          }
                        }

                        if (newColumns.length > targetDeck.columnCount) {
                           targetDeck = targetDeck.upgradeColumnCount(newColumns.length, newHeaders);
                        } else if (newColumns.length < targetDeck.columnCount) {
                           while(newColumns.length < targetDeck.columnCount) {
                             newColumns.add('');
                           }
                        }
                        
                        final newCard = FlashcardCard(columns: newColumns);
                        targetDeck = targetDeck.addCard(newCard);
                    }

                    await deckProvider.updateDeck(targetDeck);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Kata "$kata" berhasil ditambahkan!')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

