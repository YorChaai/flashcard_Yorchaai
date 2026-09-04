import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/flashcard_card.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../utils/app_strings.dart';
import '../widgets/swipeable_notification.dart';

class DeletedDataScreen extends StatefulWidget {
  final Deck deck;
  final List<String> columnHeaders;

  const DeletedDataScreen({
    super.key,
    required this.deck,
    required this.columnHeaders,
  });

  @override
  State<DeletedDataScreen> createState() => _DeletedDataScreenState();
}

class _DeletedDataScreenState extends State<DeletedDataScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination state
  int _rowsPerPage = 50;
  int _currentPage = 0;
  final Map<String, int> _cardOriginalNumbers = {};

  @override
  void initState() {
    super.initState();
    _rebuildOriginalNumbers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Deck _getCurrentDeck() {
    final provider = context.read<DeckProvider>();
    try {
      return provider.decks.firstWhere((d) => d.id == widget.deck.id);
    } catch (_) {
      return widget.deck;
    }
  }

  void _rebuildOriginalNumbers() {
    final deck = _getCurrentDeck();
    _cardOriginalNumbers.clear();
    for (int i = 0; i < deck.deletedCards.length; i++) {
      _cardOriginalNumbers[deck.deletedCards[i].id] = i + 1;
    }
  }

  List<FlashcardCard> _getFilteredCards() {
    final deck = _getCurrentDeck();
    List<FlashcardCard> list = List.from(deck.deletedCards);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      list = list.where((card) {
        final matchesCol = card.columns.any((c) => c.toLowerCase().contains(query));
        final matchesScore = card.score.toString().contains(query);
        return matchesCol || matchesScore;
      }).toList();
    }

    return list;
  }

  Future<void> _handleRestoreCard(FlashcardCard card) async {
    final provider = context.read<DeckProvider>();
    final word = card.columns.isNotEmpty ? card.columns[0] : 'baris';
    final success = await provider.restoreCard(widget.deck.id, card.id);

    if (mounted) {
      final lang = context.read<LanguageProvider>().currentLanguage;
      _rebuildOriginalNumbers();
      setState(() {});
      AppNotification.show(
        context,
        message: success
            ? AppStrings.cardRestoredSuccess(lang, word)
            : AppStrings.cardRestoreFailed(lang),
        icon: success ? Icons.restore_from_trash_rounded : Icons.error_outline,
        backgroundColor: success ? Colors.green[800] : Colors.red[800],
      );
    }
  }

  Future<void> _handleRefreshRow(FlashcardCard card) async {
    final provider = context.read<DeckProvider>();
    final result = await provider.refreshSingleCard(widget.deck.id, card.id, isDeleted: true);

    if (mounted) {
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? '';
      AppNotification.show(
        context,
        message: message,
        icon: success ? Icons.sync : Icons.info_outline,
        backgroundColor: success ? Colors.green[800] : Colors.orange[800],
      );
      setState(() {});
    }
  }

  void _showEditCardDialog(FlashcardCard card, int displayNumber) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final columnHeaders = widget.columnHeaders;
    final Map<int, TextEditingController> controllers = {};

    for (int i = 0; i < columnHeaders.length; i++) {
      final initialText = i < card.columns.length ? card.columns[i] : '';
      controllers[i] = TextEditingController(text: initialText);
    }
    final scoreController = TextEditingController(text: card.score.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.editDeletedRowTitle(lang, displayNumber),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.editingTrashWarning(lang),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < columnHeaders.length; i++) ...[
                  TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      labelText: AppStrings.formatColumnHeader(columnHeaders[i], lang),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.formatColumnHeader('Score', lang),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel(lang)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: Text(AppStrings.saveChanges(lang)),
            onPressed: () async {
              List<String> newCols = [];
              for (int i = 0; i < columnHeaders.length; i++) {
                newCols.add(controllers[i]?.text.trim() ?? '');
              }
              if (card.columns.length > columnHeaders.length) {
                for (int i = columnHeaders.length; i < card.columns.length; i++) {
                  newCols.add(card.columns[i]);
                }
              }

              final newScore = int.tryParse(scoreController.text.trim()) ?? card.score;
              final updatedCard = card.copyWith(
                columns: newCols,
                score: newScore,
              );

              Navigator.pop(dialogContext);

              final provider = context.read<DeckProvider>();
              await provider.updateDeletedCard(widget.deck.id, updatedCard);

              if (mounted) {
                setState(() {});
                AppNotification.show(
                  context,
                  message: AppStrings.changesSavedSuccess(lang),
                  icon: Icons.check_circle_outline,
                  backgroundColor: Colors.green[800],
                );
              }
            },
          ),
        ],
      ),
    ).then((_) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
      scoreController.dispose();
    });
  }

  void _showJumpToPageDialog(int totalPages) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final pageController = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.find_in_page_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Flexible(child: Text(AppStrings.jumpToPage(lang))),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width.clamp(260.0, 320.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.enterPageNumber(lang, totalPages),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pageController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: AppStrings.typePageNumber(lang),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixText: '/ $totalPages',
                ),
                onSubmitted: (val) {
                  _handleJump(val, totalPages, dialogContext);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel(lang)),
          ),
          ElevatedButton(
            onPressed: () {
              _handleJump(pageController.text, totalPages, dialogContext);
            },
            child: Text(AppStrings.go(lang)),
          ),
        ],
      ),
    ).then((_) => pageController.dispose());
  }

  void _handleJump(String text, int totalPages, BuildContext dialogContext) {
    final parsed = int.tryParse(text.trim());
    if (parsed != null && parsed >= 1) {
      final clampedPage = parsed > totalPages ? totalPages : parsed;
      setState(() {
        _currentPage = clampedPage - 1;
      });
      Navigator.pop(dialogContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final filteredCards = _getFilteredCards();
    final deck = _getCurrentDeck();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.deletedData(lang)} (${deck.deletedCards.length}) - ${deck.name}',
          softWrap: true,
          maxLines: 2,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: Column(
        children: [
          // Header search bar (No Refine / Sort & Filter as specified in plan3.md)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchDeletedData(lang),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 0;
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Data Table
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDataTableCard(context, filteredCards, lang),
                  const SizedBox(height: 12),
                  _buildPaginationControls(context, filteredCards, lang),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Bottom close button
          Container(
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
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(AppStrings.backToCustomDb(lang)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTableCard(BuildContext context, List<FlashcardCard> filteredCards, String lang) {
    final startIdx = _currentPage * _rowsPerPage;
    final endIdx = ((startIdx + _rowsPerPage) < filteredCards.length)
        ? (startIdx + _rowsPerPage)
        : filteredCards.length;
    final pageCards = filteredCards.isNotEmpty
        ? filteredCards.sublist(startIdx, endIdx)
        : <FlashcardCard>[];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      AppStrings.deletedDataRecords(lang),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppStrings.rowsDeletedCount(lang, filteredCards.length),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                // Rows per page dropdown
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.rowsPerPage(lang), style: const TextStyle(fontSize: 13)),
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      isDense: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 25, child: Text('25')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                        DropdownMenuItem(value: 100, child: Text('100')),
                        DropdownMenuItem(value: 250, child: Text('250')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rowsPerPage = val;
                            _currentPage = 0;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pageCards.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    AppStrings.noDeletedData(lang),
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24.0,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: double.infinity,
                  columns: [
                    const DataColumn(
                      label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    for (int i = 0; i < widget.columnHeaders.length; i++)
                      DataColumn(
                        label: Text(
                          AppStrings.formatColumnHeader(widget.columnHeaders[i], lang),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                    DataColumn(
                      label: Text(
                        AppStrings.tableAction(lang),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: [
                    for (int i = 0; i < pageCards.length; i++)
                      _createDataRow(pageCards[i], startIdx + i + 1, lang),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _createDataRow(FlashcardCard card, int absoluteIndex, String lang) {
    final originalNo = card.originalIndex != null
        ? (card.originalIndex! + 1)
        : (_cardOriginalNumbers[card.id] ?? absoluteIndex);
    final columns = card.allColumns;
    return DataRow(
      cells: [
        DataCell(Text(originalNo.toString())),
        for (int i = 0; i < widget.columnHeaders.length; i++)
          DataCell(
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  i < columns.length ? columns[i] : '',
                  softWrap: true,
                ),
              ),
            ),
          ),

        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Refresh per-row
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.blueAccent, size: 20),
                onPressed: () => _handleRefreshRow(card),
                tooltip: AppStrings.refreshRowTooltip(lang),
              ),
              // Edit
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.amber, size: 20),
                onPressed: () => _showEditCardDialog(card, originalNo),
                tooltip: AppStrings.editCard(lang),
              ),
              // Restore button (Undo)
              IconButton(
                icon: const Icon(Icons.restore_from_trash_rounded, color: Colors.green, size: 20),
                onPressed: () => _handleRestoreCard(card),
                tooltip: AppStrings.restoreCard(lang),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(BuildContext context, List<FlashcardCard> filteredCards, String lang) {
    if (filteredCards.isEmpty) return const SizedBox.shrink();

    final totalRows = filteredCards.length;
    final totalPages = (totalRows + _rowsPerPage - 1) ~/ _rowsPerPage;
    final startIdx = _currentPage * _rowsPerPage + 1;
    final endIdx = ((_currentPage + 1) * _rowsPerPage < totalRows)
        ? (_currentPage + 1) * _rowsPerPage
        : totalRows;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          AppStrings.showingEntries(lang, startIdx, endIdx, totalRows),
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
              tooltip: AppStrings.previous(lang),
            ),
            InkWell(
              onTap: () => _showJumpToPageDialog(totalPages),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.blue.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.pageOfTotal(lang, _currentPage + 1, totalPages),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_note, size: 16, color: Colors.blueAccent),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < (totalPages - 1) ? () => setState(() => _currentPage++) : null,
              tooltip: AppStrings.next(lang),
            ),
          ],
        ),
      ],
    );
  }
}
