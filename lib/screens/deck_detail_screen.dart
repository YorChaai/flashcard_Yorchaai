import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../models/order_mode.dart';
import '../models/deck.dart';
import '../models/font_size_settings.dart';
import '../models/flashcard_card.dart';
import '../services/storage_service.dart';
import '../utils/app_strings.dart';
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
    final langProv = context.watch<LanguageProvider>();
    final lang = langProv.currentLanguage;
    final deck = context.watch<DeckProvider>().selectedDeck;

    if (deck == null) {
      return Scaffold(body: Center(child: Text(AppStrings.noDeckSelected(lang))));
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
              tooltip: AppStrings.addCustomCard(lang),
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
                            Text(AppStrings.totalCards(lang)),
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
                            Text(AppStrings.columns(lang)),
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
                        Text(
                          AppStrings.columnHeaders(lang),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showColumnEditDialog(context, deck),
                          tooltip: AppStrings.editColumnSettings(lang),
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
            Text(
              AppStrings.activeDataset(lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          '${d.name} (${AppStrings.cardsCount(lang, d.totalCards)})',
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

            Text(
              AppStrings.learningRange(lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          AppStrings.availableData(lang, deck.totalCards),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _previewLearning(deck),
                          icon: const Icon(Icons.preview, size: 20),
                          label: Text(AppStrings.libraryPreview(lang)),
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
                            decoration: InputDecoration(
                              labelText: AppStrings.from(lang),
                              hintText: '1',
                              border: const OutlineInputBorder(),
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
                              labelText: AppStrings.to(lang),
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

            Text(
              AppStrings.orderMode(lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      title: Text(AppStrings.orderNormal(lang)),
                      subtitle: Text(AppStrings.orderNormalDesc(lang)),
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
                      title: Text(AppStrings.orderReverse(lang)),
                      subtitle: Text(AppStrings.orderReverseDesc(lang)),
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
                      title: Text(AppStrings.orderRandom(lang)),
                      subtitle: Text(AppStrings.orderRandomDesc(lang)),
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
              child: Text(
                AppStrings.startLearningButton(lang),
                style: const TextStyle(fontSize: 18),
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
    final totalSlots = max(12, deck.columnCount);
    final columnHeaders = List<String>.generate(totalSlots, (i) {
      if (i < deck.columnHeaders.length) return deck.columnHeaders[i];
      return 'Kolom ${i + 1}';
    });
    final columnOrder = List<int>.generate(totalSlots, (i) => i);
    int visibleColumnCount = deck.visibleColumnCount.clamp(1, totalSlots);

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
    final fontSize2_5Controller = TextEditingController(
      text: formatFontSize(fontSizeSettings.currentFontSize2_5),
    );
    final fontSize6_9Controller = TextEditingController(
      text: formatFontSize(fontSizeSettings.currentFontSize6_9),
    );
    final fontSize10_12Controller = TextEditingController(
      text: formatFontSize(fontSizeSettings.currentFontSize10_12),
    );

    final lang = context.read<LanguageProvider>().currentLanguage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppStrings.columnSettings(lang)),
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
                        Text(
                          AppStrings.columnOrder(lang),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PopupMenuButton<int>(
                          tooltip: AppStrings.showCount(lang),
                          offset: const Offset(0, 38),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onSelected: (val) {
                            setDialogState(() {
                              visibleColumnCount = val;
                            });
                          },
                          itemBuilder: (context) => [
                            for (final val in List.generate(12, (i) => i + 1))
                              PopupMenuItem<int>(
                                value: val,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$val ${lang == 'id' ? 'Kolom' : 'Columns'}',
                                      style: TextStyle(
                                        fontWeight: visibleColumnCount == val ? FontWeight.bold : FontWeight.normal,
                                        color: visibleColumnCount == val ? Colors.green.shade700 : null,
                                      ),
                                    ),
                                    if (visibleColumnCount == val)
                                      Icon(Icons.check, size: 18, color: Colors.green.shade700),
                                  ],
                                ),
                              ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
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
                                Text(
                                  AppStrings.showCount(lang),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$visibleColumnCount',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: (columnOrder.length * 52.0).clamp(180.0, 320.0),
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
                        buildDefaultDragHandles: false,
                        physics: const ClampingScrollPhysics(),
                        itemCount: columnOrder.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setDialogState(() {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final itemOrder = columnOrder.removeAt(oldIndex);
                            columnOrder.insert(newIndex, itemOrder);

                            final itemHeader = columnHeaders.removeAt(oldIndex);
                            columnHeaders.insert(newIndex, itemHeader);
                          });
                        },
                        itemBuilder: (context, idx) {
                          final headerName = columnHeaders[idx];
                          final isActive = idx < visibleColumnCount;
                          final isFirst = idx == 0;
                          final isLast = idx == columnOrder.length - 1;

                          return ListTile(
                            key: ValueKey('column_order_${columnOrder[idx]}_$idx'),
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 10,
                              right: 4,
                            ),
                            leading: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                setDialogState(() {
                                  visibleColumnCount = isActive ? idx : (idx + 1);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withValues(alpha: 0.18)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isActive ? Colors.green.shade600 : Colors.black87,
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  '#${idx + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isActive ? Colors.green.shade800 : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              AppStrings.formatColumnHeader(headerName, lang),
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 14,
                                color: isActive ? null : Colors.grey[600],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward, size: 18),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  color: isFirst ? Colors.grey.withValues(alpha: 0.25) : Colors.blueAccent,
                                  tooltip: 'Move Up',
                                  onPressed: isFirst
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            final itemOrder = columnOrder.removeAt(idx);
                                            columnOrder.insert(idx - 1, itemOrder);
                                            final itemHeader = columnHeaders.removeAt(idx);
                                            columnHeaders.insert(idx - 1, itemHeader);
                                          });
                                        },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward, size: 18),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  color: isLast ? Colors.grey.withValues(alpha: 0.25) : Colors.blueAccent,
                                  tooltip: 'Move Down',
                                  onPressed: isLast
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            final itemOrder = columnOrder.removeAt(idx);
                                            columnOrder.insert(idx + 1, itemOrder);
                                            final itemHeader = columnHeaders.removeAt(idx);
                                            columnHeaders.insert(idx + 1, itemHeader);
                                          });
                                        },
                                ),
                                const SizedBox(width: 2),
                                ReorderableDragStartListener(
                                  index: idx,
                                  child: const MouseRegion(
                                    cursor: SystemMouseCursors.grab,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                        Text(
                          AppStrings.fontSizeSettingsTitle(lang),
                          style: const TextStyle(
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
                            decoration: InputDecoration(
                              labelText: AppStrings.col1(lang),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: fontSize2_5Controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: AppStrings.col2_5(lang),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: fontSize6_9Controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: AppStrings.col6_9(lang),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: fontSize10_12Controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: AppStrings.col10_12(lang),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
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
                child: Text(AppStrings.cancel(lang)),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Parse font sizes - support both int and float input
                  final double? newSize1 = parseFontSize(
                    fontSize1Controller.text,
                  );
                  final double? newSize2_5 = parseFontSize(
                    fontSize2_5Controller.text,
                  );
                  final double? newSize6_9 = parseFontSize(
                    fontSize6_9Controller.text,
                  );
                  final double? newSize10_12 = parseFontSize(
                    fontSize10_12Controller.text,
                  );

                  // Validate font sizes
                  if ((newSize1 != null && newSize1 <= 0) ||
                      (newSize2_5 != null && newSize2_5 <= 0) ||
                      (newSize6_9 != null && newSize6_9 <= 0) ||
                      (newSize10_12 != null && newSize10_12 <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.fontSizeError(lang)),
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
                      mobileFontSize2_5:
                          newSize2_5 ?? currentSettings.mobileFontSize2_5,
                      mobileFontSize6_9:
                          newSize6_9 ?? currentSettings.mobileFontSize6_9,
                      mobileFontSize10_12:
                          newSize10_12 ?? currentSettings.mobileFontSize10_12,
                    );
                  } else {
                    updatedSettings = currentSettings.copyWith(
                      pcFontSize1: newSize1 ?? currentSettings.pcFontSize1,
                      pcFontSize2_5:
                          newSize2_5 ?? currentSettings.pcFontSize2_5,
                      pcFontSize6_9:
                          newSize6_9 ?? currentSettings.pcFontSize6_9,
                      pcFontSize10_12:
                          newSize10_12 ?? currentSettings.pcFontSize10_12,
                    );
                  }

                  await themeProvider.updateFontSizeSettings(updatedSettings);

                  // Save deck with updated column count, headers, cards and visible count
                  final newColumnCount = max(deck.columnCount, visibleColumnCount);

                  final newCards = deck.cards.map((card) {
                    final reordered = columnOrder.map((oldIdx) {
                      if (oldIdx < card.columns.length) return card.columns[oldIdx];
                      return '';
                    }).toList();
                    while (reordered.length < newColumnCount) {
                      reordered.add('');
                    }
                    return card.copyWith(columns: reordered);
                  }).toList();

                  final newDeletedCards = deck.deletedCards.map((card) {
                    final reordered = columnOrder.map((oldIdx) {
                      if (oldIdx < card.columns.length) return card.columns[oldIdx];
                      return '';
                    }).toList();
                    while (reordered.length < newColumnCount) {
                      reordered.add('');
                    }
                    return card.copyWith(columns: reordered);
                  }).toList();

                  final newHeaders = List<String>.from(columnHeaders);
                  while (newHeaders.length < newColumnCount) {
                    newHeaders.add('Kolom ${newHeaders.length + 1}');
                  }

                  final updatedDeck = deck.copyWith(
                    columnCount: newColumnCount,
                    visibleColumnCount: visibleColumnCount,
                    columnHeaders: newHeaders.sublist(0, newColumnCount),
                    cards: newCards,
                    deletedCards: newDeletedCards,
                  );
                  await deckProvider.updateDeck(updatedDeck);

                  // Check if context is still mounted before using it
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.fontSizeSaved(lang)),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(AppStrings.save(lang)),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        fontSize1Controller.dispose();
        fontSize2_5Controller.dispose();
        fontSize6_9Controller.dispose();
        fontSize10_12Controller.dispose();
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

    final lang = context.read<LanguageProvider>().currentLanguage;

    if (hasValidationError) return;

    final validRows = _rows
        .where((r) => r.kataController.text.trim().isNotEmpty)
        .toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang == 'id' ? 'Silakan isi minimal 1 kata.' : 'Please enter at least 1 word.'),
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
              lang == 'id'
                  ? (count == 1
                      ? 'Kata "${validRows.first.kataController.text.trim()}" berhasil ditambahkan!'
                      : '$count kata berhasil ditambahkan!')
                  : (count == 1
                      ? 'Word "${validRows.first.kataController.text.trim()}" added successfully!'
                      : '$count words added successfully!'),
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
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return AlertDialog(
      title: Text(AppStrings.addNewWords(lang)),
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
                        AppStrings.formatColumnHeader('Kata', lang),
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
                        AppStrings.formatColumnHeader('Arti', lang),
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
                            hintText: '${AppStrings.formatColumnHeader('Kata', lang)} ${i + 1}',
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
                            hintText: '${AppStrings.formatColumnHeader('Arti', lang)} ${i + 1}',
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
                            errorText: hasError ? AppStrings.wordRequired(lang) : null,
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
                                tooltip: AppStrings.deleteRow(lang),
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
                  label: Text(AppStrings.addRow(lang)),
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
                    AppStrings.maxRowsReached(lang, maxRows),
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
          child: Text(AppStrings.cancel(lang)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppStrings.save(lang)),
        ),
      ],
    );
  }
}
