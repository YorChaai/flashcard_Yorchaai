import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/deck_config.dart';
import '../models/flashcard_card.dart';
import '../models/order_mode.dart';
import '../providers/app_providers.dart';
import '../services/prompt_service.dart';
import '../widgets/swipeable_notification.dart';
import 'deleted_data_screen.dart';

class LearningPreviewScreen extends StatefulWidget {
  final List<FlashcardCard> previewCards;
  final List<String> columnHeaders;
  final Deck? deck;

  const LearningPreviewScreen({
    super.key,
    required this.previewCards,
    required this.columnHeaders,
    this.deck,
  });

  @override
  State<LearningPreviewScreen> createState() => _LearningPreviewScreenState();
}

class _LearningPreviewScreenState extends State<LearningPreviewScreen> {
  late List<FlashcardCard> _allCards;
  late List<FlashcardCard> _filteredSortedCards;

  // Row selection state for Copy Prompt & batch operations
  final Set<String> _selectedCardIds = {};

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Original row numbering map for cards
  final Map<String, int> _cardOriginalNumbers = {};

  // Type Filter & Sort Priority
  List<String> _allUniqueTypes = [];
  List<String> _typeSortPriority = [];
  Set<String> _selectedFilterTypes = {};
  bool _isTypeFilterInitialized = false;

  // CEFR Filter
  static const List<String> _allCefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  Set<String> _selectedCefrLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'EMPTY'};

  // Score Filter (3 distinct categories: Negative, Zero, Positive)
  bool _includeNegativeScore = true;
  bool _includeZeroScore = true;
  bool _includePositiveScore = true;

  // Sorting state
  int? _sortColumnIndex; // 0 = No., 1..N = columns, N+1 = Score
  bool _sortAscending = true;
  bool? _cefrSortAscending;
  bool? _scoreSortAscending;

  // Range state (synced with Learning Range)
  int? _rangeStart;
  int? _rangeEnd;
  OrderMode _orderMode = OrderMode.normal;

  // Pagination state
  int _rowsPerPage = 50;
  int _currentPage = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _allCards = List.from(widget.previewCards);
    _cardOriginalNumbers.clear();
    for (int i = 0; i < _allCards.length; i++) {
      _cardOriginalNumbers[_allCards[i].id] = i + 1;
    }
    _extractUniqueTypes();
    _applyFilterAndSort();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedConfig();
    });
  }

  Future<void> _loadSavedConfig() async {
    final deck = _getCurrentDeck();
    if (deck == null) return;
    final provider = context.read<DeckProvider>();
    final config = await provider.loadDeckConfig(deck.id);

    if (mounted) {
      setState(() {
        _sortColumnIndex = config.sortColumnIndex;
        _sortAscending = config.sortAscending;
        if (config.typeSortPriority.isNotEmpty) {
          _typeSortPriority = List.from(config.typeSortPriority);
        }
        _cefrSortAscending = config.cefrSortAscending;
        _scoreSortAscending = config.scoreSortAscending;

        if (config.selectedFilterTypes.isNotEmpty) {
          _selectedFilterTypes = Set.from(config.selectedFilterTypes);
          _isTypeFilterInitialized = true;
        }

        if (config.selectedFilterCefr.isNotEmpty) {
          _selectedCefrLevels = Set.from(config.selectedFilterCefr);
        }

        if (config.selectedFilterScore.isNotEmpty) {
          _includeNegativeScore = config.selectedFilterScore.contains('<0');
          _includeZeroScore = config.selectedFilterScore.contains('0');
          _includePositiveScore = config.selectedFilterScore.contains('>0');
        }

        _rangeStart = config.rangeStart ?? deck.lastLearningRangeStart;
        _rangeEnd = config.rangeEnd ?? deck.lastLearningRangeEnd;
        _orderMode = config.orderMode;
      });

      _applyFilterAndSort();
    }
  }

  void _saveCurrentConfig() {
    final deck = _getCurrentDeck();
    if (deck == null) return;
    final config = DeckConfig(
      deckId: deck.id,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      typeSortPriority: _typeSortPriority,
      cefrSortAscending: _cefrSortAscending,
      scoreSortAscending: _scoreSortAscending,
      selectedFilterTypes: _selectedFilterTypes,
      selectedFilterCefr: _selectedCefrLevels,
      selectedFilterScore: {
        if (_includeNegativeScore) '<0',
        if (_includeZeroScore) '0',
        if (_includePositiveScore) '>0',
      },
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
      orderMode: _orderMode,
    );
    context.read<DeckProvider>().updateDeckConfig(config);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Deck? _getCurrentDeck() {
    if (widget.deck != null) {
      final provider = context.read<DeckProvider>();
      try {
        return provider.decks.firstWhere((d) => d.id == widget.deck!.id);
      } catch (_) {
        return widget.deck;
      }
    }
    return context.read<DeckProvider>().selectedDeck;
  }

  bool _isCustomDatabase() {
    final deck = _getCurrentDeck();
    if (deck == null) return false;
    return deck.id == 'custom_mode_deck_default' ||
        deck.name.toLowerCase().contains('custom');
  }

  int? _getTypeColumnIndex() {
    for (int i = 0; i < widget.columnHeaders.length; i++) {
      final h = widget.columnHeaders[i].trim().toLowerCase();
      if (h == 'type' || h == 'tipe') return i;
    }
    return null;
  }

  int? _getCefrColumnIndex() {
    for (int i = 0; i < widget.columnHeaders.length; i++) {
      final h = widget.columnHeaders[i].trim().toLowerCase();
      if (h == 'cefr' || h == 'cerf' || h == 'level') return i;
    }
    return null;
  }

  String _cleanTypeToken(String token) {
    // Remove parenthesized content: e.g. "NOUN (Brand/Name)" -> "NOUN", "NOUN (Tech/Modern)" -> "NOUN"
    final withoutParen = token.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    return withoutParen.isNotEmpty ? withoutParen : token.trim();
  }

  List<String> _getCardBaseTypes(FlashcardCard card, int typeColIdx) {
    if (typeColIdx >= card.columns.length) return [];
    final raw = card.columns[typeColIdx].trim();
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((e) => _cleanTypeToken(e))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _extractUniqueTypes() {
    final typeIdx = _getTypeColumnIndex();
    final set = <String>{};
    if (typeIdx != null) {
      for (final card in _allCards) {
        final types = _getCardBaseTypes(card, typeIdx);
        for (final t in types) {
          set.add(t);
        }
      }
    }
    _allUniqueTypes = set.toList()..sort();
    if (_typeSortPriority.isEmpty) {
      _typeSortPriority = List.from(_allUniqueTypes);
    }
    if (!_isTypeFilterInitialized) {
      _selectedFilterTypes = Set.from(_allUniqueTypes);
      _isTypeFilterInitialized = true;
    }
  }

  bool _isColumnNumeric(int sortColIndex) {
    if (sortColIndex == 0) return true; // No.
    if (sortColIndex == widget.columnHeaders.length + 1) return true; // Score
    final colIdx = sortColIndex - 1;
    if (colIdx >= 0 && colIdx < widget.columnHeaders.length) {
      final header = widget.columnHeaders[colIdx].toLowerCase().trim();
      if (header == 'top' || header == 'no' || header == 'score' || header == 'id') {
        return true;
      }
      int numCount = 0;
      int checked = 0;
      for (final card in _allCards) {
        if (colIdx < card.columns.length && card.columns[colIdx].trim().isNotEmpty) {
          checked++;
          if (num.tryParse(card.columns[colIdx].trim()) != null) {
            numCount++;
          }
          if (checked >= 20) break;
        }
      }
      return checked > 0 && (numCount / checked) >= 0.7;
    }
    return false;
  }

  void _applyFilterAndSort() {
    List<FlashcardCard> result = List.from(_allCards);

    // 1. Search Query Filter (across all columns)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((card) {
        final matchesCol = card.columns.any((c) => c.toLowerCase().contains(query));
        final matchesScore = card.score.toString().contains(query);
        return matchesCol || matchesScore;
      }).toList();
    }

    // 2. Type Filter (Include concept: card must contain at least 1 checked base type)
    final typeColIdx = _getTypeColumnIndex();
    if (typeColIdx != null && _allUniqueTypes.isNotEmpty && _selectedFilterTypes.length < _allUniqueTypes.length) {
      result = result.where((card) {
        final types = _getCardBaseTypes(card, typeColIdx);
        return types.any((t) => _selectedFilterTypes.contains(t));
      }).toList();
    }

    // 3. CEFR Filter (Multi-select)
    final cefrColIdx = _getCefrColumnIndex();
    if (cefrColIdx != null && _selectedCefrLevels.length < (_allCefrLevels.length + 1)) {
      result = result.where((card) {
        if (cefrColIdx < card.columns.length) {
          final raw = card.columns[cefrColIdx].trim().toUpperCase();
          if (raw.isEmpty) {
            return _selectedCefrLevels.contains('EMPTY');
          }
          return _selectedCefrLevels.contains(raw);
        }
        return _selectedCefrLevels.contains('EMPTY');
      }).toList();
    }

    // 4. Score Filter (3 independent categories: Negative, Zero, Positive)
    final allScoreCategoriesChecked = _includeNegativeScore && _includeZeroScore && _includePositiveScore;
    if (!allScoreCategoriesChecked) {
      result = result.where((card) {
        if (card.score < 0) return _includeNegativeScore;
        if (card.score == 0) return _includeZeroScore;
        return _includePositiveScore; // card.score > 0
      }).toList();
    }

    // 5. Sorting
    if (_sortColumnIndex != null) {
      final sortCol = _sortColumnIndex!;
      if (sortCol == 0) {
        // Sort by original position / No.
        result.sort((a, b) {
          final noA = _cardOriginalNumbers[a.id] ?? 0;
          final noB = _cardOriginalNumbers[b.id] ?? 0;
          return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
        });
      } else if (sortCol == widget.columnHeaders.length + 1) {
        // Sort by Score (pure numeric: negative, zero, positive)
        result.sort((a, b) {
          final comp = a.score.compareTo(b.score);
          return _sortAscending ? comp : -comp;
        });
      } else {
        // Sort by Column index (sortCol - 1)
        final dataColIndex = sortCol - 1;
        final headerName = widget.columnHeaders[dataColIndex].trim().toLowerCase();

        if (headerName == 'type' || headerName == 'tipe') {
          // Sort by Custom Type Priority (Drag & Drop Reordered Priority)
          result.sort((a, b) {
            final tokensA = _getCardBaseTypes(a, dataColIndex);
            final tokensB = _getCardBaseTypes(b, dataColIndex);

            int rankA = 999999;
            for (final t in tokensA) {
              final idx = _typeSortPriority.indexOf(t);
              if (idx != -1 && idx < rankA) rankA = idx;
            }

            int rankB = 999999;
            for (final t in tokensB) {
              final idx = _typeSortPriority.indexOf(t);
              if (idx != -1 && idx < rankB) rankB = idx;
            }

            final comp = rankA.compareTo(rankB);
            if (comp != 0) {
              return _sortAscending ? comp : -comp;
            }
            final noA = _cardOriginalNumbers[a.id] ?? 0;
            final noB = _cardOriginalNumbers[b.id] ?? 0;
            return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
          });
        } else if (headerName == 'cefr' || headerName == 'cerf' || headerName == 'level') {
          // Sort by CEFR Official Level Hierarchy (A1 -> A2 -> B1 -> B2 -> C1 -> C2)
          result.sort((a, b) {
            final rawA = dataColIndex < a.columns.length ? a.columns[dataColIndex].trim().toUpperCase() : '';
            final rawB = dataColIndex < b.columns.length ? b.columns[dataColIndex].trim().toUpperCase() : '';

            int rankA = _allCefrLevels.indexOf(rawA);
            if (rankA == -1) rankA = 999;

            int rankB = _allCefrLevels.indexOf(rawB);
            if (rankB == -1) rankB = 999;

            final comp = rankA.compareTo(rankB);
            if (comp != 0) {
              return _sortAscending ? comp : -comp;
            }
            final noA = _cardOriginalNumbers[a.id] ?? 0;
            final noB = _cardOriginalNumbers[b.id] ?? 0;
            return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
          });
        } else {
          final isNumeric = _isColumnNumeric(sortCol);
          result.sort((a, b) {
            final valA = dataColIndex < a.columns.length ? a.columns[dataColIndex].trim() : '';
            final valB = dataColIndex < b.columns.length ? b.columns[dataColIndex].trim() : '';

            if (isNumeric) {
              final numA = num.tryParse(valA) ?? (_sortAscending ? double.infinity : -double.infinity);
              final numB = num.tryParse(valB) ?? (_sortAscending ? double.infinity : -double.infinity);
              final comp = numA.compareTo(numB);
              if (comp != 0) {
                return _sortAscending ? comp : -comp;
              }
            } else {
              final comp = valA.toLowerCase().compareTo(valB.toLowerCase());
              if (comp != 0) {
                return _sortAscending ? comp : -comp;
              }
            }
            final noA = _cardOriginalNumbers[a.id] ?? 0;
            final noB = _cardOriginalNumbers[b.id] ?? 0;
            return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
          });
        }
      }
    }

    // 6. Range Filter (From..To)
    if (_rangeStart != null || _rangeEnd != null) {
      if (result.isNotEmpty) {
        final start = (_rangeStart ?? 1).clamp(1, result.length) - 1;
        final end = (_rangeEnd ?? result.length).clamp(1, result.length);
        if (start < end) {
          result = result.sublist(start, end);
        }
      }
    }

    setState(() {
      _filteredSortedCards = result;
      // Reset page if out of bounds
      final maxPage = (_filteredSortedCards.isEmpty ? 0 : (_filteredSortedCards.length - 1) ~/ _rowsPerPage);
      if (_currentPage > maxPage) {
        _currentPage = maxPage;
      }
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    _applyFilterAndSort();
    _saveCurrentConfig();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedFilterTypes = Set.from(_allUniqueTypes);
      _selectedCefrLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'EMPTY'};
      _includeNegativeScore = true;
      _includeZeroScore = true;
      _includePositiveScore = true;
      _sortColumnIndex = null;
      _sortAscending = true;
      _rangeStart = null;
      _rangeEnd = null;
      _currentPage = 0;
    });
    _applyFilterAndSort();
    _saveCurrentConfig();
  }

  void _showRangeDialog() {
    final totalCards = _allCards.length;
    final fromController = TextEditingController(text: (_rangeStart ?? 1).toString());
    final toController = TextEditingController(text: (_rangeEnd ?? totalCards).toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.linear_scale_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Flexible(child: Text('Rentang Data (Range)')),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width.clamp(280.0, 380.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentukan batas awal dan akhir baris data yang ingin ditampilkan dan dipelajari (Total data: $totalCards).',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fromController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'From (Dari No.)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: toController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'To (Sampai No.)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _rangeStart = null;
                _rangeEnd = null;
                _currentPage = 0;
              });
              _applyFilterAndSort();
              _saveCurrentConfig();
              Navigator.pop(dialogContext);
            },
            child: const Text('Reset Range', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              int from = int.tryParse(fromController.text.trim()) ?? 1;
              int to = int.tryParse(toController.text.trim()) ?? totalCards;
              if (from < 1) from = 1;
              if (from > totalCards) from = totalCards;
              if (to < 1) to = 1;
              if (to > totalCards) to = totalCards;
              if (from > to) {
                final tmp = from;
                from = to;
                to = tmp;
              }

              setState(() {
                _rangeStart = from;
                _rangeEnd = to;
                _currentPage = 0;
              });
              _applyFilterAndSort();
              _saveCurrentConfig();
              Navigator.pop(dialogContext);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    int tempSortCol = _sortColumnIndex ?? 0;
    bool tempAscending = _sortAscending;
    List<String> tempTypePriority = List.from(_typeSortPriority);

    // Build available sort columns (excluding IPA)
    final availableSortColumns = <Map<String, dynamic>>[];
    availableSortColumns.add({'index': 0, 'title': 'No. (Urutan Baris)'});

    for (int i = 0; i < widget.columnHeaders.length; i++) {
      final header = widget.columnHeaders[i];
      if (header.trim().toLowerCase() == 'ipa') continue; // Exclude IPA
      availableSortColumns.add({'index': i + 1, 'title': header});
    }
    availableSortColumns.add({
      'index': widget.columnHeaders.length + 1,
      'title': 'Score',
    });

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isScore = tempSortCol == widget.columnHeaders.length + 1;
          final selectedColName = tempSortCol > 0 && tempSortCol <= widget.columnHeaders.length
              ? widget.columnHeaders[tempSortCol - 1].trim().toLowerCase()
              : '';
          final isType = selectedColName == 'type' || selectedColName == 'tipe';
          final isCefr = selectedColName == 'cefr' || selectedColName == 'cerf' || selectedColName == 'level';
          final isNumeric = _isColumnNumeric(tempSortCol);

          return AlertDialog(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert_rounded, color: Colors.blueAccent),
                SizedBox(width: 8),
                Flexible(child: Text('Urutkan Data (Sort)')),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width.clamp(280.0, 480.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Pilih Kolom untuk Diurutkan:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: availableSortColumns.any((c) => c['index'] == tempSortCol)
                          ? tempSortCol
                          : 0,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        for (final col in availableSortColumns)
                          DropdownMenuItem<int>(
                            value: col['index'] as int,
                            child: Text(col['title'] as String),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            tempSortCol = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Special UI for TYPE: Reorderable Priority List
                    if (isType && tempTypePriority.isNotEmpty) ...[
                      const Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Icon(Icons.drag_indicator, size: 18, color: Colors.blueAccent),
                          Text(
                            '2. Atur Prioritas Tipe (Tarik / Drag untuk ubah urutan):',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tipe paling atas memiliki prioritas tertinggi saat diurutkan.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).cardColor,
                        ),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          itemCount: tempTypePriority.length,
                          onReorderItem: (oldIndex, newIndex) {
                            setDialogState(() {
                              final item = tempTypePriority.removeAt(oldIndex);
                              tempTypePriority.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, idx) {
                            final typeName = tempTypePriority[idx];
                            return ListTile(
                              key: ValueKey(typeName),
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${idx + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                                ),
                              ),
                              title: Text(typeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '3. Arah Prioritas:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      const Text(
                        '2. Pilih Arah Urutan:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],

                    const SizedBox(height: 8),
                    // Ascending Option
                    InkWell(
                      onTap: () => setDialogState(() => tempAscending = true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: tempAscending ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.3),
                            width: tempAscending ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: tempAscending ? Colors.blue.withValues(alpha: 0.05) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tempAscending ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: tempAscending ? Colors.blueAccent : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              (isNumeric || isScore) ? Icons.arrow_upward_rounded : Icons.sort_by_alpha_rounded,
                              size: 20,
                              color: tempAscending ? Colors.blueAccent : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCefr
                                        ? 'A1 → C2 (Ascending / Level Dasar ke Mahir)'
                                        : isType
                                            ? 'Prioritas Teratas ke Terbawah (Ascending)'
                                            : isScore
                                                ? '-100 → 0 → +100 (Ascending / Terendah ke Tertinggi)'
                                                : isNumeric
                                                    ? '0 → 9 (Ascending / Kecil ke Besar)'
                                                    : 'A → Z (Ascending / Dari A ke Z)',
                                    style: TextStyle(
                                      fontWeight: tempAscending ? FontWeight.bold : FontWeight.normal,
                                      color: tempAscending ? Colors.blueAccent : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCefr
                                        ? 'Urutkan berdasarkan tingkatan level CEFR standar'
                                        : isType
                                            ? 'Data dengan tipe urutan teratas akan ditampilkan lebih dulu'
                                            : isScore
                                                ? 'Urutkan angka score negatif, nol, hingga positif'
                                                : isNumeric
                                                    ? 'Urutkan angka dari nilai terendah ke tertinggi'
                                                    : 'Urutkan teks berdasarkan alfabet A ke Z',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Descending Option
                    InkWell(
                      onTap: () => setDialogState(() => tempAscending = false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: !tempAscending ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.3),
                            width: !tempAscending ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: !tempAscending ? Colors.blue.withValues(alpha: 0.05) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              !tempAscending ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: !tempAscending ? Colors.blueAccent : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              (isNumeric || isScore) ? Icons.arrow_downward_rounded : Icons.sort_by_alpha_rounded,
                              size: 20,
                              color: !tempAscending ? Colors.blueAccent : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCefr
                                        ? 'C2 → A1 (Descending / Level Mahir ke Dasar)'
                                        : isType
                                            ? 'Prioritas Terbawah ke Teratas (Descending)'
                                            : isScore
                                                ? '+100 → 0 → -100 (Descending / Tertinggi ke Terendah)'
                                                : isNumeric
                                                    ? '9 → 0 (Descending / Besar ke Kecil)'
                                                    : 'Z → A (Descending / Dari Z ke A)',
                                    style: TextStyle(
                                      fontWeight: !tempAscending ? FontWeight.bold : FontWeight.normal,
                                      color: !tempAscending ? Colors.blueAccent : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCefr
                                        ? 'Urutkan terbalik dari level tertinggi C2 ke level dasar A1'
                                        : isType
                                            ? 'Data dengan tipe urutan terbawah akan ditampilkan lebih dulu'
                                            : isScore
                                                ? 'Urutkan angka score positif, nol, hingga negatif'
                                                : isNumeric
                                                    ? 'Urutkan angka dari nilai tertinggi ke terendah'
                                                    : 'Urutkan teks terbalik dari alfabet Z ke A',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _sortColumnIndex = null;
                    _sortAscending = true;
                    _typeSortPriority = List.from(_allUniqueTypes);
                    _currentPage = 0;
                  });
                  _applyFilterAndSort();
                  _saveCurrentConfig();
                  Navigator.pop(dialogContext);
                },
                child: const Text('Reset Sort', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sortColumnIndex = tempSortCol == 0 ? null : tempSortCol;
                    _sortAscending = tempAscending;
                    _typeSortPriority = List.from(tempTypePriority);
                    _currentPage = 0;
                  });
                  _applyFilterAndSort();
                  _saveCurrentConfig();
                  Navigator.pop(dialogContext);
                },
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    Set<String> tempTypes = Set.from(_selectedFilterTypes);
    Set<String> tempCefr = Set.from(_selectedCefrLevels);
    bool tempNegative = _includeNegativeScore;
    bool tempZero = _includeZeroScore;
    bool tempPositive = _includePositiveScore;

    final typeColIdx = _getTypeColumnIndex();
    final cefrColIdx = _getCefrColumnIndex();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_rounded, color: Colors.blueAccent),
                SizedBox(width: 8),
                Flexible(child: Text('Saring Data (Filter)')),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width.clamp(280.0, 480.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === 1. FILTER TYPE ===
                    if (typeColIdx != null && _allUniqueTypes.isNotEmpty) ...[
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            '1. Filter Tipe (Type):',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    tempTypes = Set.from(_allUniqueTypes);
                                  });
                                },
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                child: const Text('Pilih Semua', style: TextStyle(fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    tempTypes.clear();
                                  });
                                },
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                child: const Text('Hapus Semua', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Centang tipe yang diizinkan tampil di tabel:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in _allUniqueTypes)
                            FilterChip(
                              label: Text(t),
                              selected: tempTypes.contains(t),
                              selectedColor: Colors.blue.withValues(alpha: 0.2),
                              checkmarkColor: Colors.blueAccent,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    tempTypes.add(t);
                                  } else {
                                    tempTypes.remove(t);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    // === 2. FILTER CEFR ===
                    if (cefrColIdx != null) ...[
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text(
                            '2. Filter Level CEFR:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    tempCefr = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'EMPTY'};
                                  });
                                },
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                child: const Text('Pilih Semua', style: TextStyle(fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    tempCefr.clear();
                                  });
                                },
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                child: const Text('Hapus Semua', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih level CEFR yang ingin ditampilkan:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final level in _allCefrLevels)
                            FilterChip(
                              label: Text(level, style: const TextStyle(fontWeight: FontWeight.bold)),
                              selected: tempCefr.contains(level),
                              selectedColor: Colors.blue.withValues(alpha: 0.2),
                              checkmarkColor: Colors.blueAccent,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    tempCefr.add(level);
                                  } else {
                                    tempCefr.remove(level);
                                  }
                                });
                              },
                            ),
                          FilterChip(
                            label: const Text('Tanpa CEFR'),
                            selected: tempCefr.contains('EMPTY'),
                            selectedColor: Colors.blue.withValues(alpha: 0.2),
                            checkmarkColor: Colors.blueAccent,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  tempCefr.add('EMPTY');
                                } else {
                                  tempCefr.remove('EMPTY');
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    // === 3. FILTER SCORE ===
                    const Text(
                      '3. Filter Kategori Score:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih kategori score pemahaman kartu:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),

                    // Negative Score Checkbox
                    CheckboxListTile(
                      value: tempNegative,
                      activeColor: Colors.blueAccent,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Row(
                        children: [
                          Icon(Icons.trending_down, color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Negative (< 0)', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      subtitle: Text('Score bernilai minus (contoh: -1, -20, -100)', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      onChanged: (val) {
                        setDialogState(() {
                          tempNegative = val ?? false;
                        });
                      },
                    ),

                    // Zero Score Checkbox
                    CheckboxListTile(
                      value: tempZero,
                      activeColor: Colors.blueAccent,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Row(
                        children: [
                          Icon(Icons.radio_button_unchecked, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text('Zero (== 0)', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      subtitle: Text('Score 0 / kata baru yang belum dipelajari', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      onChanged: (val) {
                        setDialogState(() {
                          tempZero = val ?? false;
                        });
                      },
                    ),

                    // Positive Score Checkbox
                    CheckboxListTile(
                      value: tempPositive,
                      activeColor: Colors.blueAccent,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('Positive (> 0)', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      subtitle: Text('Score bernilai positif (contoh: 1, 20, 100)', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      onChanged: (val) {
                        setDialogState(() {
                          tempPositive = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilterTypes = Set.from(_allUniqueTypes);
                    _selectedCefrLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'EMPTY'};
                    _includeNegativeScore = true;
                    _includeZeroScore = true;
                    _includePositiveScore = true;
                    _currentPage = 0;
                  });
                  _applyFilterAndSort();
                  _saveCurrentConfig();
                  Navigator.pop(dialogContext);
                },
                child: const Text('Reset Filter', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilterTypes = Set.from(tempTypes);
                    _selectedCefrLevels = Set.from(tempCefr);
                    _includeNegativeScore = tempNegative;
                    _includeZeroScore = tempZero;
                    _includePositiveScore = tempPositive;
                    _currentPage = 0;
                  });
                  _applyFilterAndSort();
                  _saveCurrentConfig();
                  Navigator.pop(dialogContext);
                },
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleRefreshSource() async {
    final currentDeck = _getCurrentDeck();
    if (currentDeck == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final provider = context.read<DeckProvider>();
      final result = await provider.refreshCustomDeck(currentDeck.id);

      // Update local cards from refreshed deck
      final updatedDeck = provider.decks.firstWhere((d) => d.id == currentDeck.id);
      setState(() {
        _allCards = List.from(updatedDeck.cards);
        _cardOriginalNumbers.clear();
        for (int i = 0; i < _allCards.length; i++) {
          _cardOriginalNumbers[_allCards[i].id] = i + 1;
        }
      });
      _extractUniqueTypes();
      _applyFilterAndSort();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sinkronisasi selesai: ${result['updated']} data diperbarui, ${result['removed']} data dihapus. Total: ${result['total']} kata.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showEditCardDialog(FlashcardCard card, int displayNumber) {
    final currentDeck = _getCurrentDeck();
    final columnHeaders = widget.columnHeaders;
    final Map<int, TextEditingController> controllers = {};

    for (int i = 0; i < columnHeaders.length; i++) {
      final initialText = i < card.columns.length ? card.columns[i] : '';
      controllers[i] = TextEditingController(text: initialText);
    }
    final scoreController = TextEditingController(text: card.score.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit Baris #$displayNumber',
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
                  // Information banner
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nomor baris (No.) adalah penomoran urut tampilan. Kolom data di bawah dapat diedit.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dynamic column fields
                  for (int i = 0; i < columnHeaders.length; i++) ...[
                    TextField(
                      controller: controllers[i],
                      decoration: InputDecoration(
                        labelText: columnHeaders[i],
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Score field
                  TextField(
                    controller: scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Score',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      helperText: 'Skor pemahaman kartu flashcard',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Simpan Perubahan'),
              onPressed: () async {
                final originalWord = card.columns.isNotEmpty ? card.columns[0] : '';
                final currentContext = context;
                
                // Build new columns
                List<String> newCols = [];
                for (int i = 0; i < columnHeaders.length; i++) {
                  newCols.add(controllers[i]?.text.trim() ?? '');
                }

                // If card had additional hidden columns (e.g. in custom db), preserve trailing
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

                if (currentDeck != null) {
                  final provider = currentContext.read<DeckProvider>();
                  await provider.updateCardWithCrossDeckSync(
                    currentDeck.id,
                    updatedCard,
                    originalWord: originalWord,
                  );
                }

                // Update local list
                setState(() {
                  final idx = _allCards.indexWhere((c) => c.id == card.id);
                  if (idx != -1) {
                    _allCards[idx] = updatedCard;
                  }
                });
                _applyFilterAndSort();

                if (mounted) {
                  AppNotification.show(
                    this.context,
                    message: 'Perubahan data berhasil disimpan',
                    icon: Icons.check_circle_outline,
                    backgroundColor: Colors.green[800],
                  );
                }
              },
            ),
          ],
        ),
      ),
    ).then((_) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
      scoreController.dispose();
    });
  }

  Future<void> _handleRefreshSingleCard(FlashcardCard card) async {
    final currentDeck = _getCurrentDeck();
    if (currentDeck == null) return;
    final provider = context.read<DeckProvider>();
    final result = await provider.refreshSingleCard(currentDeck.id, card.id);

    if (mounted) {
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? '';
      if (success && result['card'] != null) {
        final refreshed = result['card'] as FlashcardCard;
        setState(() {
          final idx = _allCards.indexWhere((c) => c.id == card.id);
          if (idx != -1) {
            _allCards[idx] = refreshed;
          }
        });
        _extractUniqueTypes();
        _applyFilterAndSort();
      }

      AppNotification.show(
        context,
        message: message,
        icon: success ? Icons.sync : Icons.info_outline,
        backgroundColor: success ? Colors.green[800] : Colors.orange[800],
      );
    }
  }

  void _confirmDelete(FlashcardCard card) {
    final firstCol = card.columns.isNotEmpty ? card.columns[0] : '';
    final currentDeck = _getCurrentDeck();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Baris (Pindahkan ke Trash)'),
        content: Text(
          'Yakin ingin menghapus kata "$firstCol"?\nData ini akan dipindahkan ke Deleted Data dan dapat dikembalikan kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final provider = context.read<DeckProvider>();

              if (currentDeck != null) {
                await provider.softDeleteCard(currentDeck.id, card.id);
              }

              setState(() {
                _allCards.removeWhere((c) => c.id == card.id);
                _selectedCardIds.remove(card.id);
              });
              _extractUniqueTypes();
              _applyFilterAndSort();

              if (mounted) {
                AppNotification.show(
                  context,
                  message: 'Baris "$firstCol" dipindahkan ke Deleted Data',
                  actionLabel: 'Undo',
                  icon: Icons.delete_outline,
                  onAction: () async {
                    if (currentDeck != null) {
                      await provider.restoreCard(currentDeck.id, card.id);
                      final updatedDeck = _getCurrentDeck();
                      if (updatedDeck != null) {
                        setState(() {
                          _allCards = List.from(updatedDeck.cards);
                          _cardOriginalNumbers.clear();
                          for (int i = 0; i < _allCards.length; i++) {
                            _cardOriginalNumbers[_allCards[i].id] = i + 1;
                          }
                        });
                        _extractUniqueTypes();
                        _applyFilterAndSort();
                      }
                    }
                  },
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

  void _copyPrompt() {
    final deck = _getCurrentDeck();
    List<FlashcardCard> cardsToCopy;
    if (_selectedCardIds.isNotEmpty) {
      // Keep order matching current filtered & sorted cards
      cardsToCopy = _filteredSortedCards
          .where((card) => _selectedCardIds.contains(card.id))
          .toList();
    } else {
      cardsToCopy = _filteredSortedCards;
    }

    if (cardsToCopy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada kata untuk dibuatkan prompt.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final prompt = PromptService.generatePrompt(
      cards: cardsToCopy,
      deck: deck,
    );

    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedCardIds.isNotEmpty
              ? 'Prompt berhasil disalin untuk ${_selectedCardIds.length} kata terpilih!'
              : 'Prompt berhasil disalin untuk ${cardsToCopy.length} kata!',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomDb = _isCustomDatabase();
    final deck = _getCurrentDeck();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          deck != null ? 'Library Preview - ${deck.name}' : 'Library Preview',
          softWrap: true,
          maxLines: 2,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isCustomDb) ...[
            if (_isRefreshing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _handleRefreshSource,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Refresh Source'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
          // Copy Prompt button
          Tooltip(
            message: _selectedCardIds.isNotEmpty
                ? 'Copy Prompt (${_selectedCardIds.length} baris terpilih)'
                : 'Copy Prompt (Semua ${_filteredSortedCards.length} baris preview)',
            child: ElevatedButton.icon(
              onPressed: _copyPrompt,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(
                _selectedCardIds.isNotEmpty
                    ? 'Copy Prompt (${_selectedCardIds.length})'
                    : 'Copy Prompt',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedCardIds.isNotEmpty ? Colors.green[700] : Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Deleted Data button for ALL datasets (Icon + Count only)
          Tooltip(
            message: 'Deleted Data (${deck?.deletedCards.length ?? 0} item)',
            child: ElevatedButton.icon(
              onPressed: () {
                final currentDeck = _getCurrentDeck();
                if (currentDeck != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeletedDataScreen(
                        deck: currentDeck,
                        columnHeaders: widget.columnHeaders,
                      ),
                    ),
                  ).then((_) {
                    final updatedDeck = _getCurrentDeck();
                    if (updatedDeck != null) {
                      setState(() {
                        _allCards = List.from(updatedDeck.cards);
                        _cardOriginalNumbers.clear();
                        for (int i = 0; i < _allCards.length; i++) {
                          _cardOriginalNumbers[_allCards[i].id] = i + 1;
                        }
                      });
                      _extractUniqueTypes();
                      _applyFilterAndSort();
                    }
                  });
                }
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('${deck?.deletedCards.length ?? 0}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter & Search Controls Header (Now scrolls with content)
                  _buildFilterAndSortHeader(context),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDataPreviewTable(context),
                        const SizedBox(height: 12),
                        _buildPaginationControls(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortHeader(BuildContext context) {
    final isTypeFiltered = _allUniqueTypes.isNotEmpty && _selectedFilterTypes.length < _allUniqueTypes.length;
    final isCefrFiltered = _selectedCefrLevels.length < (_allCefrLevels.length + 1);
    final isScoreFiltered = !(_includeNegativeScore && _includeZeroScore && _includePositiveScore);
    final isRangeFiltered = _rangeStart != null || _rangeEnd != null;
    final isSpecificFilterActive = isTypeFiltered || isCefrFiltered || isScoreFiltered || isRangeFiltered;
    final isFiltered = _searchQuery.isNotEmpty || isSpecificFilterActive || _sortColumnIndex != null;
    final isSorted = _sortColumnIndex != null;

    final selectedSortColName = _sortColumnIndex != null && _sortColumnIndex! > 0 && _sortColumnIndex! <= widget.columnHeaders.length
        ? widget.columnHeaders[_sortColumnIndex! - 1].trim().toLowerCase()
        : '';
    final isSortType = selectedSortColName == 'type' || selectedSortColName == 'tipe';
    final isSortCefr = selectedSortColName == 'cefr' || selectedSortColName == 'cerf' || selectedSortColName == 'level';
    final isSortScore = _sortColumnIndex == widget.columnHeaders.length + 1;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari di semua kolom...',
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
                              _applyFilterAndSort();
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
                    _applyFilterAndSort();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Refine Dropdown Menu Button
              PopupMenuButton<String>(
                tooltip: 'Refine (Sort / Filter / Range)',
                offset: const Offset(0, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'sort') {
                    _showSortDialog();
                  } else if (value == 'filter') {
                    _showFilterDialog();
                  } else if (value == 'range') {
                    _showRangeDialog();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'sort',
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          size: 20,
                          color: isSorted ? Colors.blueAccent : Colors.grey[400],
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Sort (Urutan Data)',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (isSorted) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'filter',
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: 20,
                          color: (isTypeFiltered || isCefrFiltered || isScoreFiltered) ? Colors.blueAccent : Colors.grey[400],
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Filter (Saring Data)',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (isTypeFiltered || isCefrFiltered || isScoreFiltered) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'range',
                    child: Row(
                      children: [
                        Icon(
                          Icons.linear_scale_rounded,
                          size: 20,
                          color: isRangeFiltered ? Colors.blueAccent : Colors.grey[400],
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Range (Rentang Data)',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (isRangeFiltered) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isSorted || isSpecificFilterActive)
                          ? Colors.blueAccent
                          : Colors.grey.withValues(alpha: 0.4),
                      width: (isSorted || isSpecificFilterActive) ? 1.5 : 1.0,
                    ),
                    color: (isSorted || isSpecificFilterActive)
                        ? Colors.blue.withValues(alpha: 0.08)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: (isSorted || isSpecificFilterActive) ? Colors.blueAccent : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Refine',
                        style: TextStyle(
                          fontWeight: (isSorted || isSpecificFilterActive) ? FontWeight.bold : FontWeight.normal,
                          color: (isSorted || isSpecificFilterActive) ? Colors.blueAccent : null,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: (isSorted || isSpecificFilterActive) ? Colors.blueAccent : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (isFiltered) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.red),
                  tooltip: 'Reset Semua Filter, Sort & Range',
                ),
              ],
            ],
          ),
          // Active filter & sort badges (Responsive: Dropdown pill on small screen, Chips on wide screen)
          if (isFiltered) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final activeItems = <_ActiveFilterItem>[];

                if (_sortColumnIndex != null) {
                  final isSortNo = _sortColumnIndex == 0;
                  final String sortLabel;
                  final IconData sortIcon;

                  if (isSortNo) {
                    sortLabel = 'Sort: No. (${_sortAscending ? "1→${_allCards.length}" : "${_allCards.length}→1"})';
                    sortIcon = _sortAscending ? Icons.arrow_upward : Icons.arrow_downward;
                  } else if (isSortType) {
                    sortLabel = 'Sort: Type (${_sortAscending ? "Prioritas #1" : "Prioritas Terbalik"})';
                    sortIcon = Icons.sort;
                  } else if (isSortCefr) {
                    sortLabel = 'Sort: CEFR (${_sortAscending ? "A1→C2" : "C2→A1"})';
                    sortIcon = Icons.sort;
                  } else if (isSortScore) {
                    sortLabel = 'Sort: Score (${_sortAscending ? "-100→+100" : "+100→-100"})';
                    sortIcon = _sortAscending ? Icons.trending_up : Icons.trending_down;
                  } else {
                    sortLabel = 'Sort: ${_getSortColumnName(_sortColumnIndex!)} (${_isColumnNumeric(_sortColumnIndex!) ? (_sortAscending ? "0→9" : "9→0") : (_sortAscending ? "A→Z" : "Z→A")})';
                    sortIcon = _isColumnNumeric(_sortColumnIndex!)
                        ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                        : Icons.sort_by_alpha;
                  }

                  activeItems.add(_ActiveFilterItem(
                    icon: sortIcon,
                    label: sortLabel,
                    onDeleted: () {
                      setState(() {
                        _sortColumnIndex = null;
                        _sortAscending = true;
                      });
                      _applyFilterAndSort();
                      _saveCurrentConfig();
                    },
                  ));
                }

                if (_searchQuery.isNotEmpty) {
                  activeItems.add(_ActiveFilterItem(
                    icon: Icons.search,
                    label: 'Cari: "$_searchQuery"',
                    onDeleted: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      _applyFilterAndSort();
                    },
                  ));
                }

                if (isTypeFiltered) {
                  activeItems.add(_ActiveFilterItem(
                    icon: Icons.category_rounded,
                    label: 'Type: ${_selectedFilterTypes.length}/${_allUniqueTypes.length} dipilih',
                    onDeleted: () {
                      setState(() {
                        _selectedFilterTypes = Set.from(_allUniqueTypes);
                      });
                      _applyFilterAndSort();
                      _saveCurrentConfig();
                    },
                  ));
                }

                if (isCefrFiltered) {
                  activeItems.add(_ActiveFilterItem(
                    icon: Icons.school_rounded,
                    label: 'CEFR: ${_selectedCefrLevels.contains("EMPTY") ? _selectedCefrLevels.length - 1 : _selectedCefrLevels.length}/6 level',
                    onDeleted: () {
                      setState(() {
                        _selectedCefrLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'EMPTY'};
                      });
                      _applyFilterAndSort();
                      _saveCurrentConfig();
                    },
                  ));
                }

                if (isScoreFiltered) {
                  final cats = <String>[];
                  if (_includeNegativeScore) cats.add('Neg (<0)');
                  if (_includeZeroScore) cats.add('Zero (0)');
                  if (_includePositiveScore) cats.add('Pos (>0)');
                  activeItems.add(_ActiveFilterItem(
                    icon: Icons.stars_rounded,
                    label: 'Score: [${cats.join(", ")}]',
                    onDeleted: () {
                      setState(() {
                        _includeNegativeScore = true;
                        _includeZeroScore = true;
                        _includePositiveScore = true;
                      });
                      _applyFilterAndSort();
                      _saveCurrentConfig();
                    },
                  ));
                }

                if (isRangeFiltered) {
                  activeItems.add(_ActiveFilterItem(
                    icon: Icons.linear_scale_rounded,
                    label: 'Range: ${_rangeStart ?? 1}–${_rangeEnd ?? _allCards.length}',
                    onDeleted: () {
                      setState(() {
                        _rangeStart = null;
                        _rangeEnd = null;
                        _currentPage = 0;
                      });
                      _applyFilterAndSort();
                      _saveCurrentConfig();
                    },
                  ));
                }

                if (activeItems.isEmpty) return const SizedBox.shrink();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 620;
                    if (isCompact) {
                      return Row(
                        children: [
                          const Text(
                            'Aktif: ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          PopupMenuButton<VoidCallback>(
                            tooltip: 'Lihat & Kelola Filter Aktif',
                            offset: const Offset(0, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (callback) => callback(),
                            itemBuilder: (ctx) => [
                              for (final item in activeItems)
                                PopupMenuItem<VoidCallback>(
                                  value: item.onDeleted,
                                  child: Row(
                                    children: [
                                      Icon(item.icon, size: 16, color: Colors.blueAccent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              PopupMenuItem<VoidCallback>(
                                value: _resetFilters,
                                child: const Row(
                                  children: [
                                    Icon(Icons.refresh_rounded, size: 16, color: Colors.red),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Reset Semua Filter',
                                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.tune_rounded, size: 14, color: Colors.blueAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${activeItems.length} Kriteria Aktif',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 18, color: Colors.blueAccent),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Aktif:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        for (final item in activeItems)
                          Chip(
                            avatar: Icon(item.icon, size: 16, color: Colors.blueAccent),
                            label: Text(
                              item.label,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                            onDeleted: item.onDeleted,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _getSortColumnName(int index) {
    if (index == 0) return 'No.';
    if (index == widget.columnHeaders.length + 1) return 'Score';
    final colIdx = index - 1;
    if (colIdx >= 0 && colIdx < widget.columnHeaders.length) {
      return widget.columnHeaders[colIdx];
    }
    return 'Column $index';
  }

  Widget _buildDataPreviewTable(BuildContext context) {
    final startIdx = _currentPage * _rowsPerPage;
    final endIdx = ((startIdx + _rowsPerPage) < _filteredSortedCards.length)
        ? (startIdx + _rowsPerPage)
        : _filteredSortedCards.length;
    final pageCards = _filteredSortedCards.isNotEmpty
        ? _filteredSortedCards.sublist(startIdx, endIdx)
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
                    const Text(
                      '👀 Data Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredSortedCards.length} of ${_allCards.length} baris',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                // Rows per page dropdown
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Rows/page: ', style: TextStyle(fontSize: 13)),
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
            if (_selectedCardIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedCardIds.length} baris dipilih untuk Copy Prompt',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (final c in pageCards) {
                            _selectedCardIds.add(c.id);
                          }
                        });
                      },
                      child: const Text('Pilih Halaman Ini', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCardIds.clear();
                        });
                      },
                      child: const Text('Batal Pilih', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (pageCards.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Tidak ada data yang cocok dengan kriteria pencarian/filter.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  columnSpacing: 24.0,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: double.infinity,
                  columns: [
                    DataColumn(
                      label: const Text('No.', style: TextStyle(fontWeight: FontWeight.bold)),
                      onSort: (colIdx, asc) => _onSort(0, asc),
                    ),
                    for (int i = 0; i < widget.columnHeaders.length; i++)
                      DataColumn(
                        label: Text(
                          widget.columnHeaders[i],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onSort: (colIdx, asc) => _onSort(i + 1, asc),
                      ),
                    DataColumn(
                      label: const Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
                      onSort: (colIdx, asc) => _onSort(widget.columnHeaders.length + 1, asc),
                    ),
                    const DataColumn(
                      label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: [
                    for (int i = 0; i < pageCards.length; i++)
                      _createDataRow(pageCards[i], startIdx + i + 1),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _createDataRow(FlashcardCard card, int absoluteIndex) {
    final originalNo = _cardOriginalNumbers[card.id] ?? absoluteIndex;
    final columns = card.allColumns;
    final isCustomDb = _isCustomDatabase();
    final isSelected = _selectedCardIds.contains(card.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (isSelected) return Colors.green.withValues(alpha: 0.15);
        return null;
      }),
      cells: [
        DataCell(
          Tooltip(
            message: _selectedCardIds.isEmpty
                ? 'Tekan lama untuk mengaktifkan mode pilih'
                : (isSelected ? 'Klik untuk batal pilih' : 'Klik untuk memilih baris'),
            child: InkWell(
              onLongPress: () {
                setState(() {
                  if (isSelected) {
                    _selectedCardIds.remove(card.id);
                  } else {
                    _selectedCardIds.add(card.id);
                  }
                });
              },
              onTap: () {
                if (_selectedCardIds.isNotEmpty) {
                  setState(() {
                    if (isSelected) {
                      _selectedCardIds.remove(card.id);
                    } else {
                      _selectedCardIds.add(card.id);
                    }
                  });
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  originalNo.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
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
        DataCell(Text(card.score.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCustomDb)
                IconButton(
                  icon: const Icon(Icons.sync, color: Colors.blueAccent, size: 20),
                  onPressed: () => _handleRefreshSingleCard(card),
                  tooltip: 'Refresh baris ini dari dataset sumber',
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.amber, size: 20),
                onPressed: () => _showEditCardDialog(card, originalNo),
                tooltip: 'Edit data baris ini',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(card),
                tooltip: isCustomDb ? 'Pindahkan ke Deleted Data' : 'Hapus baris',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showJumpToPageDialog(int totalPages) {
    final pageController = TextEditingController(text: ''); // blank/empty by default

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.find_in_page_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Flexible(child: Text('Lompat ke Halaman')),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width.clamp(260.0, 320.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan nomor halaman (1 s/d $totalPages):',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pageController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ketik nomor halaman...',
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
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _handleJump(pageController.text, totalPages, dialogContext);
            },
            child: const Text('Lanjut'),
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

  Widget _buildPaginationControls(BuildContext context) {
    if (_filteredSortedCards.isEmpty) return const SizedBox.shrink();

    final totalRows = _filteredSortedCards.length;
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
          'Showing $startIdx - $endIdx of $totalRows entries',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
              tooltip: 'Halaman Sebelumnya',
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
                      'Page ${_currentPage + 1} of $totalPages',
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
              tooltip: 'Halaman Berikutnya',
            ),
          ],
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

class _ActiveFilterItem {
  final IconData icon;
  final String label;
  final VoidCallback onDeleted;

  const _ActiveFilterItem({
    required this.icon,
    required this.label,
    required this.onDeleted,
  });
}


