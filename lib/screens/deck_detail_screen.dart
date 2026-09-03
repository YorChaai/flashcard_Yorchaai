import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../models/order_mode.dart';
import '../models/deck.dart';
import '../models/font_size_settings.dart';
import '../models/flashcard_card.dart';
import '../services/storage_service.dart';
import '../utils/deck_column_helper.dart';
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
      final provider = context.read<DeckProvider>();
      final deck = provider.selectedDeck;
      if (deck != null) {
        final config = provider.getDeckConfig(deck.id);
        _fromController.text =
            (config.rangeStart ?? deck.lastLearningRangeStart ?? 1).toString();
        _toController.text =
            (config.rangeEnd ?? deck.lastLearningRangeEnd ?? deck.totalCards)
                .toString();
        _selectedMode = config.orderMode;
        _rangeInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckProvider>().selectedDeck;

    if (deck == null) {
      return const Scaffold(body: Center(child: Text('No deck selected')));
    }

    // Fix for when starting from 0 cards
    if (int.tryParse(_toController.text) == 0 && deck.totalCards > 0) {
      _toController.text = deck.totalCards.toString();
    }

    // Set _toController if empty (moved from here to didChangeDependencies)

    return Scaffold(
      appBar: AppBar(
        title: Text(
          deck.name,
          softWrap: true,
          maxLines: 2,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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

            // Active Dataset Selector
            const Text(
              'Active Dataset',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Deck>(
                    isExpanded: true,
                    value:
                        context.watch<DeckProvider>().decks.any(
                          (d) => d.id == deck.id,
                        )
                        ? context.watch<DeckProvider>().decks.firstWhere(
                            (d) => d.id == deck.id,
                          )
                        : deck,
                    items: context.watch<DeckProvider>().decks.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(
                          '${d.name} (${d.totalCards} cards)',
                          softWrap: true,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                    onChanged: (newDeck) {
                      if (newDeck != null && newDeck.id != deck.id) {
                        final provider = context.read<DeckProvider>();
                        provider.selectDeck(newDeck);
                        StorageService().setLastSelectedDeckId(newDeck.id);
                        final config = provider.getDeckConfig(newDeck.id);
                        setState(() {
                          _fromController.text =
                              (config.rangeStart ??
                                      newDeck.lastLearningRangeStart ??
                                      1)
                                  .toString();
                          _toController.text =
                              (config.rangeEnd ??
                                      newDeck.lastLearningRangeEnd ??
                                      newDeck.totalCards)
                                  .toString();
                          _selectedMode = config.orderMode;
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
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

            const Text(
              'Order Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      onTap: () {
                        setState(() {
                          _selectedMode = OrderMode.normal;
                        });
                      },
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
                      onTap: () {
                        setState(() {
                          _selectedMode = OrderMode.reverse;
                        });
                      },
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
                      onTap: () {
                        setState(() {
                          _selectedMode = OrderMode.random;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _startLearning,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
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
    final provider = context.read<DeckProvider>();
    final deck = provider.selectedDeck;
    if (deck == null || deck.cards.isEmpty) return;

    int from = int.tryParse(_fromController.text) ?? 1;
    int to = int.tryParse(_toController.text) ?? deck.totalCards;

    if (from < 1) from = 1;
    if (from > deck.totalCards) from = deck.totalCards;

    if (to < 1) to = 1;
    if (to > deck.totalCards) to = deck.totalCards;

    if (from > to) {
      final temp = from;
      from = to;
      to = temp;
    }

    _fromController.text = from.toString();
    _toController.text = to.toString();

    var config = provider.getDeckConfig(deck.id);
    config = config.copyWith(
      rangeStart: from,
      rangeEnd: to,
      orderMode: _selectedMode,
    );
    provider.updateDeckConfig(config);

    final processedCards = provider.getProcessedCards(
      deck,
      config,
      applyOrderMode: true,
    );
    if (processedCards.isEmpty) {
      _showRangeError('Tidak ada data pada range / filter yang dipilih.');
      return;
    }

    context.read<LearningSessionProvider>().startSession(
      processedCards,
      OrderMode.normal,
      deckId: deck.id,
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

    int from = int.tryParse(_fromController.text) ?? 1;
    int to = int.tryParse(_toController.text) ?? deck.totalCards;

    if (from < 1) from = 1;
    if (from > deck.totalCards) from = deck.totalCards;

    if (to < 1) to = 1;
    if (to > deck.totalCards) to = deck.totalCards;

    if (from > to) {
      final temp = from;
      from = to;
      to = temp;
    }

    _fromController.text = from.toString();
    _toController.text = to.toString();

    final provider = context.read<DeckProvider>();
    var config = provider.getDeckConfig(deck.id);
    config = config.copyWith(
      rangeStart: from,
      rangeEnd: to,
      orderMode: _selectedMode,
    );
    provider.updateDeckConfig(config);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningPreviewScreen(
          previewCards: deck.cards,
          columnHeaders: deck.columnHeaders,
          deck: deck,
        ),
      ),
    ).then((_) {
      final updatedConfig = provider.getDeckConfig(deck.id);
      setState(() {
        _fromController.text = (updatedConfig.rangeStart ?? 1).toString();
        _toController.text = (updatedConfig.rangeEnd ?? deck.totalCards)
            .toString();
        _selectedMode = updatedConfig.orderMode;
      });
    });
  }

  void _showRangeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showColumnEditDialog(BuildContext context, Deck deck) {
    final columnOrder = List<int>.generate(deck.columnCount, (i) => i);
    final columnHeaders = List<String>.from(deck.columnHeaders);
    int visibleColumnCount = deck.visibleColumnCount.clamp(1, deck.columnCount);

    final themeProvider = context.read<ThemeProvider>();
    final fontSizeSettings = themeProvider.fontSizeSettings;

    String formatFontSize(double size) {
      if (size == size.toInt()) {
        return size.toInt().toString();
      }
      return size.toString();
    }

    double? parseFontSize(String input) {
      final intValue = int.tryParse(input);
      if (intValue != null) return intValue.toDouble();
      return double.tryParse(input);
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
          return AlertDialog(
            title: const Text('Column Settings'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width.clamp(280.0, 440.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'Column Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Show: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  dropdownColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  value: visibleColumnCount,
                                  isDense: true,
                                  iconSize: 18,
                                  iconEnabledColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  items:
                                      List.generate(
                                        deck.columnCount,
                                        (i) => i + 1,
                                      ).map((val) {
                                        return DropdownMenuItem(
                                          value: val,
                                          child: Text('$val'),
                                        );
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
                      height: (columnOrder.length * 52.0).clamp(160.0, 280.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).cardColor,
                      ),
                      child: ReorderableListView.builder(
                        itemCount: columnOrder.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setDialogState(() {
                            final itemOrder = columnOrder.removeAt(oldIndex);
                            columnOrder.insert(newIndex, itemOrder);

                            final itemHeader = columnHeaders.removeAt(oldIndex);
                            columnHeaders.insert(newIndex, itemHeader);
                          });
                        },
                        itemBuilder: (context, idx) {
                          final headerName = columnHeaders[idx];
                          return ListTile(
                            key: ValueKey('column_order_${columnOrder[idx]}'),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${idx + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                            title: Text(
                              headerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'Font Size Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                            ),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Kolom 1 (Atas Tengah)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: fontSize23Controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Kolom 2 & 3',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: fontSize45Controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Kolom 4 & 5',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: fontSize6Controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Kolom 6 (Bawah)',
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
                  final double? newSize1 = parseFontSize(
                    fontSize1Controller.text,
                  );
                  final double? newSize23 = parseFontSize(
                    fontSize23Controller.text,
                  );
                  final double? newSize45 = parseFontSize(
                    fontSize45Controller.text,
                  );
                  final double? newSize6 = parseFontSize(
                    fontSize6Controller.text,
                  );

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
                      mobileFontSize1:
                          newSize1 ?? currentSettings.mobileFontSize1,
                      mobileFontSize23:
                          newSize23 ?? currentSettings.mobileFontSize23,
                      mobileFontSize45:
                          newSize45 ?? currentSettings.mobileFontSize45,
                      mobileFontSize6:
                          newSize6 ?? currentSettings.mobileFontSize6,
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
                      final findIndex = columnOrder.indexWhere(
                        (idx) => idx == i,
                      );
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
                  updatedDeck = updatedDeck.copyWith(
                    visibleColumnCount: visibleColumnCount,
                  );
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
    showDialog(
      context: context,
      builder: (dialogContext) => _AddCustomCardDialog(currentDeck: currentDeck),
    );
  }
}

class _AddCustomCardDialog extends StatefulWidget {
  final Deck currentDeck;

  const _AddCustomCardDialog({required this.currentDeck});

  @override
  State<_AddCustomCardDialog> createState() => _AddCustomCardDialogState();
}

class _AddCustomCardRowItem {
  final Key key;
  final TextEditingController kataController;
  final TextEditingController artiController;
  bool hasError = false;

  _AddCustomCardRowItem({
    required this.key,
    required this.kataController,
    required this.artiController,
  });

  void dispose() {
    kataController.dispose();
    artiController.dispose();
  }
}

class _AddCustomCardDialogState extends State<_AddCustomCardDialog> {
  static const int maxRows = 20;
  final List<_AddCustomCardRowItem> _rows = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addRow();
  }

  void _addRow() {
    if (_rows.length >= maxRows) return;
    setState(() {
      _rows.add(_AddCustomCardRowItem(
        key: UniqueKey(),
        kataController: TextEditingController(),
        artiController: TextEditingController(),
      ));
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final removed = _rows.removeAt(index);
      removed.dispose();
    });
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    // --- Validasi ---
    bool hasValidationError = false;
    setState(() {
      for (final row in _rows) {
        final kataVal = row.kataController.text.trim();
        final artiVal = row.artiController.text.trim();
        row.hasError = artiVal.isNotEmpty && kataVal.isEmpty;
        if (row.hasError) {
          hasValidationError = true;
        }
      }
    });

    if (hasValidationError) return;

    final validRows = _rows
        .where((r) => r.kataController.text.trim().isNotEmpty)
        .toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi minimal 1 kata.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final deckProvider = context.read<DeckProvider>();
      final availableDecks = deckProvider.decks
          .where((d) => d.id != widget.currentDeck.id)
          .toList();

      Deck targetDeck = widget.currentDeck.copyWith(
        columnHeaders: DeckColumnHelper.standardCustomHeaders,
        columnCount: DeckColumnHelper.standardCustomHeaders.length,
        visibleColumnCount: DeckColumnHelper.standardCustomHeaders.length,
      );

      for (final row in validRows) {
        final kata = row.kataController.text.trim();
        final arti = row.artiController.text.trim();
        bool foundAny = false;

        for (final deck in availableDecks) {
          FlashcardCard? matchInDeck;
          for (final card in deck.cards) {
            // Cocokkan HANYA pada kolom pertama (Kata/Word)
            if (card.columns.isNotEmpty &&
                card.columns[0].toLowerCase().trim() == kata.toLowerCase()) {
              matchInDeck = card;
              break;
            }
          }

          if (matchInDeck != null) {
            foundAny = true;
            final newColumns = DeckColumnHelper.buildStandardCustomColumns(
              kata: kata,
              arti: arti,
              sourceName: deck.name,
              sourceCard: matchInDeck,
              sourceHeaders: deck.columnHeaders,
            );

            targetDeck = targetDeck.addCard(
              FlashcardCard(
                columns: newColumns,
                score: matchInDeck.score,
              ),
            );
            break; // Stop di source pertama yang cocok
          }
        }

        if (!foundAny) {
          final newColumns = DeckColumnHelper.buildStandardCustomColumns(
            kata: kata,
            arti: arti,
            sourceName: 'Manual/Custom',
          );

          targetDeck = targetDeck.addCard(
            FlashcardCard(columns: newColumns),
          );
        }
      }

      await deckProvider.updateDeck(targetDeck);

      if (mounted) {
        final count = validRows.length;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 1
                  ? 'Kata "${validRows.first.kataController.text.trim()}" berhasil ditambahkan!'
                  : '$count kata berhasil ditambahkan!',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Kata Baru'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header labels
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kata',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arti',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 36), // Space for delete button
                  ],
                ),
              ),

              // Input rows
              ...List.generate(_rows.length, (i) {
                final rowItem = _rows[i];
                final hasError = rowItem.hasError;
                return Padding(
                  key: rowItem.key,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kata field
                      Expanded(
                        child: TextField(
                          controller: rowItem.kataController,
                          autofocus: i == 0,
                          decoration: InputDecoration(
                            hintText: 'Kata ${i + 1}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (_) {
                            if (rowItem.hasError) {
                              setState(() => rowItem.hasError = false);
                            }
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Arti field
                      Expanded(
                        child: TextField(
                          controller: rowItem.artiController,
                          decoration: InputDecoration(
                            hintText: 'Arti ${i + 1}',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: hasError ? Colors.red : Colors.grey,
                                width: hasError ? 2 : 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: hasError ? Colors.red : Colors.grey,
                                width: hasError ? 2 : 1,
                              ),
                            ),
                            errorText: hasError ? 'Kata wajib diisi' : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (_) {
                            if (rowItem.hasError) {
                              setState(() => rowItem.hasError = false);
                            }
                          },
                          textInputAction: i == _rows.length - 1
                              ? TextInputAction.done
                              : TextInputAction.next,
                        ),
                      ),
                      // Delete button (hidden on first row)
                      SizedBox(
                        width: 36,
                        child: i == 0
                            ? const SizedBox.shrink()
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                onPressed: () => _removeRow(i),
                                tooltip: 'Hapus baris',
                              ),
                      ),
                    ],
                  ),
                );
              }),

              // Add-row button / limit message
              if (_rows.length < maxRows)
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah baris'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Maksimal $maxRows baris tercapai',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
