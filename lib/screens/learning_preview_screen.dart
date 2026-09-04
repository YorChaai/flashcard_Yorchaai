import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck.dart';
import '../models/deck_config.dart';
import '../models/flashcard_card.dart';
import '../models/order_mode.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../services/prompt_service.dart';
import '../utils/app_strings.dart';
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

  // Dynamic Column Filter State (Column Header -> Set of selected values)
  final Map<String, List<String>> _allColumnUniqueValues = {};
  Map<String, Set<String>> _columnFilters = {};
  String? _lastSelectedFilterColumn;

  // Type Filter & Sort Priority (Legacy compatibility)
  List<String> _allUniqueTypes = [];
  List<String> _typeSortPriority = [];
  Set<String> _selectedFilterTypes = {};
  bool _isTypeFilterInitialized = false;

  // CEFR Filter (Legacy compatibility)
  static const List<String> _allCefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  Set<String> _selectedCefrLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'EMPTY'};

  // Score Filter (Legacy compatibility)
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

  // Table horizontal scroll controller for smooth 60fps scrolling
  final ScrollController _horizontalScrollController = ScrollController();

  // Table Zoom State (50% - 100%)
  int _zoomPercent = 100;
  static const String _zoomPrefKey = 'preview_table_zoom_percent';

  Future<void> _loadZoomPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_zoomPrefKey);
      if (saved != null && saved >= 50 && saved <= 100) {
        if (mounted) {
          setState(() {
            _zoomPercent = saved;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveZoomPreference(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_zoomPrefKey, value);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadZoomPreference();
    _allCards = List.from(widget.previewCards);
    _cardOriginalNumbers.clear();
    for (int i = 0; i < _allCards.length; i++) {
      _cardOriginalNumbers[_allCards[i].id] = i + 1;
    }
    _extractUniqueTypes();
    _extractUniqueColumnValues();

    final deck = _getCurrentDeck();
    if (deck != null) {
      final provider = context.read<DeckProvider>();
      final config = provider.getDeckConfig(deck.id);

      _sortColumnIndex = config.sortColumnIndex;
      _sortAscending = config.sortAscending;
      if (config.typeSortPriority.isNotEmpty) {
        _typeSortPriority = _sanitizeTypeList(config.typeSortPriority);
      }
      _cefrSortAscending = config.cefrSortAscending;
      _scoreSortAscending = config.scoreSortAscending;

      if (config.selectedFilterTypes.isNotEmpty) {
        final cleaned = config.selectedFilterTypes
            .map((e) => _cleanTypeString(e).trim().toUpperCase())
            .where((e) => _allUniqueTypes.contains(e))
            .toSet();
        _selectedFilterTypes = cleaned.isNotEmpty ? cleaned : Set.from(_allUniqueTypes);
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

      if (config.columnFilters.isNotEmpty) {
        _columnFilters = Map.from(config.columnFilters);
      }
      _lastSelectedFilterColumn = config.lastSelectedFilterColumn;
      _rangeStart = config.rangeStart;
      _rangeEnd = config.rangeEnd;
      _orderMode = config.orderMode;
    }

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

    if (!mounted) return;
    // Fast check: if config in memory is already identical, avoid redundant re-filter/re-sort on 14,000 cards
    if (config.sortColumnIndex == _sortColumnIndex &&
        config.sortAscending == _sortAscending &&
        config.typeSortPriority.length == _typeSortPriority.length &&
        config.rangeStart == _rangeStart &&
        config.rangeEnd == _rangeEnd &&
        config.selectedFilterTypes.length == _selectedFilterTypes.length &&
        config.selectedFilterCefr.length == _selectedCefrLevels.length &&
        config.columnFilters.length == _columnFilters.length) {
      return;
    }

    setState(() {
      _sortColumnIndex = config.sortColumnIndex;
      _sortAscending = config.sortAscending;
      if (config.typeSortPriority.isNotEmpty) {
        _typeSortPriority = _sanitizeTypeList(config.typeSortPriority);
        _formattedTypeCache.clear();
      }
      _cefrSortAscending = config.cefrSortAscending;
      _scoreSortAscending = config.scoreSortAscending;

      if (config.selectedFilterTypes.isNotEmpty) {
        final cleaned = config.selectedFilterTypes
            .map((e) => _cleanTypeString(e).trim().toUpperCase())
            .where((e) => _allUniqueTypes.contains(e))
            .toSet();
        _selectedFilterTypes = cleaned.isNotEmpty ? cleaned : Set.from(_allUniqueTypes);
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

      if (config.columnFilters.isNotEmpty) {
        _columnFilters = Map.from(config.columnFilters);
      }
      _lastSelectedFilterColumn = config.lastSelectedFilterColumn;

      _rangeStart = config.rangeStart;
      _rangeEnd = config.rangeEnd;
      _orderMode = config.orderMode;
    });

    _applyFilterAndSort();
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
      columnFilters: _columnFilters,
      lastSelectedFilterColumn: _lastSelectedFilterColumn,
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
      orderMode: _orderMode,
    );
    context.read<DeckProvider>().updateDeckConfig(config);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
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

  static final RegExp _bracketRegExp = RegExp(r'[\(\[\{].*?[\)\]\}]');

  String _cleanTypeString(String raw) {
    var s = raw;
    if (s.contains('(') || s.contains('[') || s.contains('{')) {
      s = s.replaceAll(_bracketRegExp, ' ');
    }
    if (s.contains(')') || s.contains(']') || s.contains('}') || s.contains('(') || s.contains('[') || s.contains('{')) {
      s = s.replaceAll(RegExp(r'[\(\)\[\]\{\}]'), ' ');
    }
    return s.trim();
  }

  List<String> _sanitizeTypeList(Iterable<String> types) {
    final result = <String>[];
    for (final raw in types) {
      final clean = _cleanTypeString(raw);
      for (final tok in clean.split(RegExp(r'[,/]'))) {
        final t = tok.trim().toUpperCase();
        if (t.isNotEmpty && !result.contains(t)) {
          if (_allUniqueTypes.isEmpty || _allUniqueTypes.contains(t)) {
            result.add(t);
          }
        }
      }
    }
    for (final u in _allUniqueTypes) {
      if (!result.contains(u)) result.add(u);
    }
    return result;
  }

  final Map<String, String> _formattedTypeCache = {};

  String _formatCardType(String rawType) {
    if (rawType.trim().isEmpty || _typeSortPriority.isEmpty) return rawType;
    final cached = _formattedTypeCache[rawType];
    if (cached != null) return cached;

    final clean = _cleanTypeString(rawType);
    if (clean.isEmpty) return rawType;

    final priorityMap = <String, int>{};
    for (int i = 0; i < _typeSortPriority.length; i++) {
      priorityMap[_typeSortPriority[i].toUpperCase().trim()] = i;
    }

    final tokens = clean.split(RegExp(r'[,/]'));
    final parsedTokens = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final tok in tokens) {
      final trimmed = tok.trim().toUpperCase();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      final p = priorityMap[trimmed] ?? 999999;
      parsedTokens.add({
        'original': trimmed,
        'priority': p,
      });
    }

    parsedTokens.sort((a, b) {
      final pComp = (a['priority'] as int).compareTo(b['priority'] as int);
      if (pComp != 0) return pComp;
      return 0;
    });

    final formatted = parsedTokens.map((e) => e['original'] as String).join(', ');
    _formattedTypeCache[rawType] = formatted;
    return formatted;
  }

  List<String> _getCardBaseTypes(FlashcardCard card, int typeColIdx) {
    if (typeColIdx >= card.columns.length) return [];
    final raw = card.columns[typeColIdx].trim();
    if (raw.isEmpty) return [];

    final clean = _cleanTypeString(raw);
    if (clean.isEmpty) return [];

    final tokens = clean.split(RegExp(r'[,/]'));
    final result = <String>[];
    for (final t in tokens) {
      final trimmed = t.trim().toUpperCase();
      if (trimmed.isNotEmpty && !result.contains(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  int _getCardTopPriority(FlashcardCard card, int typeColIdx, Map<String, int> priorityMap) {
    if (typeColIdx >= card.columns.length) return 999999;
    final raw = card.columns[typeColIdx].trim();
    if (raw.isEmpty) return 999999;

    final clean = _cleanTypeString(raw);
    if (clean.isEmpty) return 999999;

    int minPriority = 999999;
    final tokens = clean.split(RegExp(r'[,/]'));
    for (final tok in tokens) {
      final trimmed = tok.trim().toUpperCase();
      if (trimmed.isEmpty) continue;
      final p = priorityMap[trimmed] ?? 999999;
      if (p < minPriority) minPriority = p;
    }
    return minPriority;
  }

  List<String> _getUniqueValuesForColumn(String header, [int? colIdx]) {
    if (header == 'Score') {
      return ['+ (Score > 0)', '0 (Score = 0)', '- (Score < 0)'];
    }
    final typeIdx = _getTypeColumnIndex();
    final idx = colIdx ?? widget.columnHeaders.indexWhere((h) => h.trim().toLowerCase() == header.trim().toLowerCase());
    if (idx != -1 && idx == typeIdx) {
      return List.from(_allUniqueTypes);
    }
    if (_allColumnUniqueValues.containsKey(header)) {
      return _allColumnUniqueValues[header]!;
    }
    if (idx == -1) return [];

    final set = <String>{};
    for (final card in _allCards) {
      if (idx < card.columns.length) {
        final val = card.columns[idx].trim();
        if (val.isEmpty) {
          set.add('(Empty)');
        } else if (val.contains(',')) {
          for (final tag in val.split(',')) {
            final t = tag.trim();
            if (t.isNotEmpty) set.add(t);
          }
        } else {
          set.add(val);
        }
      } else {
        set.add('(Empty)');
      }
    }
    final sortedList = set.toList()
      ..sort((a, b) {
        if (a == '(Empty)') return 1;
        if (b == '(Empty)') return -1;
        final numA = num.tryParse(a);
        final numB = num.tryParse(b);
        if (numA != null && numB != null) return numA.compareTo(numB);
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    _allColumnUniqueValues[header] = sortedList;
    return sortedList;
  }

  void _extractUniqueColumnValues() {
    _allColumnUniqueValues.clear();
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
    } else {
      _typeSortPriority = _sanitizeTypeList(_typeSortPriority);
    }
    if (!_isTypeFilterInitialized) {
      _selectedFilterTypes = Set.from(_allUniqueTypes);
      _isTypeFilterInitialized = true;
    } else {
      _selectedFilterTypes = _selectedFilterTypes.where((t) => _allUniqueTypes.contains(t)).toSet();
      if (_selectedFilterTypes.isEmpty) {
        _selectedFilterTypes = Set.from(_allUniqueTypes);
      }
    }
  }

  bool _isColumnNumeric(int sortColIndex) {
    if (sortColIndex == 0) return true; // No.
    final colIdx = sortColIndex - 1;
    if (colIdx >= 0 && colIdx < widget.columnHeaders.length) {
      int numCount = 0;
      int checked = 0;
      for (final card in _allCards) {
        if (colIdx < card.columns.length) {
          final val = card.columns[colIdx].trim();
          if (val.isNotEmpty) {
            checked++;
            if (num.tryParse(val) != null) {
              numCount++;
            }
            if (checked >= 30) break;
          }
        }
      }
      return checked > 0 && (numCount / checked) >= 0.7;
    }
    return false;
  }

  void _applyFilterAndSort() {
    final hasSearch = _searchQuery.isNotEmpty;
    final query = _searchQuery.toLowerCase().trim();

    // Map column names in _columnFilters to their column index
    final activeColumnFilters = <int, Set<String>>{};
    for (int colIdx = 0; colIdx < widget.columnHeaders.length; colIdx++) {
      final header = widget.columnHeaders[colIdx];
      final allowedSet = _columnFilters[header];
      if (allowedSet != null) {
        activeColumnFilters[colIdx] = allowedSet;
      }
    }
    final hasColFilters = activeColumnFilters.isNotEmpty;

    final typeColIdx = _getTypeColumnIndex();
    final filterTypes = (typeColIdx != null &&
        _allUniqueTypes.isNotEmpty &&
        _selectedFilterTypes.length < _allUniqueTypes.length);

    final cefrColIdx = _getCefrColumnIndex();
    final filterCefr = (cefrColIdx != null &&
        _selectedCefrLevels.length < (_allCefrLevels.length + 1));

    final filterScore = !(_includeNegativeScore && _includeZeroScore && _includePositiveScore);

    final hasRange = _rangeStart != null || _rangeEnd != null;
    final rangeStart = _rangeStart ?? 1;
    final rangeEnd = _rangeEnd ?? _allCards.length;

    // Single unified filtering pass: O(N)
    final List<FlashcardCard> result = [];
    for (final card in _allCards) {
      if (hasSearch) {
        final matchesCol = card.columns.any((c) => c.toLowerCase().contains(query));
        final matchesScore = card.score.toString().contains(query);
        if (!matchesCol && !matchesScore) continue;
      }

      if (hasColFilters) {
        bool matches = true;
        for (final entry in activeColumnFilters.entries) {
          final colIdx = entry.key;
          final allowed = entry.value;
          if (allowed.isEmpty) {
            matches = false;
            break;
          }

          if (colIdx == typeColIdx) {
            final cardTypes = _getCardBaseTypes(card, colIdx);
            if (cardTypes.isEmpty) {
              if (allowed.contains('(Empty)')) continue;
            } else {
              if (cardTypes.any((t) => allowed.contains(t))) continue;
            }
            matches = false;
            break;
          }

          final val = colIdx < card.columns.length ? card.columns[colIdx].trim() : '';
          final checkVal = val.isEmpty ? '(Empty)' : val;
          if (allowed.contains(checkVal)) continue;

          if (val.contains(',') || val.contains('/')) {
            final tags = val.split(RegExp(r'[,/]'));
            bool foundTag = false;
            for (final tag in tags) {
              final t = tag.trim();
              if (t.isNotEmpty && allowed.contains(t)) {
                foundTag = true;
                break;
              }
            }
            if (foundTag) continue;
          }
          matches = false;
          break;
        }
        if (!matches) continue;
      }

      if (filterTypes) {
        final types = _getCardBaseTypes(card, typeColIdx);
        if (!types.any((t) => _selectedFilterTypes.contains(t))) continue;
      }

      if (filterCefr) {
        final raw = cefrColIdx < card.columns.length
            ? card.columns[cefrColIdx].trim().toUpperCase()
            : '';
        final cefrVal = raw.isEmpty ? 'EMPTY' : raw;
        if (!_selectedCefrLevels.contains(cefrVal)) continue;
      }

      if (filterScore) {
        if (card.score < 0 && !_includeNegativeScore) continue;
        if (card.score == 0 && !_includeZeroScore) continue;
        if (card.score > 0 && !_includePositiveScore) continue;
      }

      if (hasRange) {
        final originalNo = _cardOriginalNumbers[card.id] ?? 0;
        if (originalNo < rangeStart || originalNo > rangeEnd) continue;
      }

      result.add(card);
    }

    // High-performance sorting with precomputed keys (Schwartzian transform)
    if (_sortColumnIndex != null && result.isNotEmpty) {
      final sortCol = _sortColumnIndex!;
      if (sortCol == 0) {
        final typeIdx = _getTypeColumnIndex();
        if (typeIdx != null && _typeSortPriority.isNotEmpty) {
          final priorityMap = <String, int>{};
          for (int i = 0; i < _typeSortPriority.length; i++) {
            priorityMap[_typeSortPriority[i].toUpperCase().trim()] = i;
          }
          final rankKeys = <String, int>{};
          for (final card in result) {
            rankKeys[card.id] = _getCardTopPriority(card, typeIdx, priorityMap);
          }
          result.sort((a, b) {
            final rA = rankKeys[a.id] ?? 999999;
            final rB = rankKeys[b.id] ?? 999999;
            final comp = rA.compareTo(rB);
            if (comp != 0) return comp;
            final noA = _cardOriginalNumbers[a.id] ?? 0;
            final noB = _cardOriginalNumbers[b.id] ?? 0;
            return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
          });
        } else {
          result.sort((a, b) {
            final noA = _cardOriginalNumbers[a.id] ?? 0;
            final noB = _cardOriginalNumbers[b.id] ?? 0;
            return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
          });
        }
      } else if (sortCol == widget.columnHeaders.length + 1) {
        result.sort((a, b) {
          final comp = a.score.compareTo(b.score);
          return _sortAscending ? comp : -comp;
        });
      } else {
        final dataColIndex = sortCol - 1;
        final headerName = widget.columnHeaders[dataColIndex].trim().toLowerCase();

        if (headerName == 'type' || headerName == 'tipe') {
          final priorityMap = <String, int>{};
          for (int i = 0; i < _typeSortPriority.length; i++) {
            priorityMap[_typeSortPriority[i].toUpperCase().trim()] = i;
          }

          final rankKeys = <String, int>{};
          for (final card in result) {
            rankKeys[card.id] = _getCardTopPriority(card, dataColIndex, priorityMap);
          }

          result.sort((a, b) {
            final rA = rankKeys[a.id] ?? 999999;
            final rB = rankKeys[b.id] ?? 999999;
            final comp = rA.compareTo(rB);
            if (comp != 0) return _sortAscending ? comp : -comp;
            final noA = _cardOriginalNumbers[a.id] ?? 0;
            final noB = _cardOriginalNumbers[b.id] ?? 0;
            return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
          });
        } else if (headerName == 'cefr' || headerName == 'cerf' || headerName == 'level') {
          final cefrMap = <String, int>{};
          for (int i = 0; i < _allCefrLevels.length; i++) {
            cefrMap[_allCefrLevels[i]] = i;
          }

          final keys = <String, int>{};
          for (final card in result) {
            final raw = dataColIndex < card.columns.length ? card.columns[dataColIndex].trim().toUpperCase() : '';
            keys[card.id] = cefrMap[raw] ?? 999;
          }

          result.sort((a, b) {
            final rankA = keys[a.id] ?? 999;
            final rankB = keys[b.id] ?? 999;
            final comp = rankA.compareTo(rankB);
            if (comp != 0) return _sortAscending ? comp : -comp;
            final noA = _cardOriginalNumbers[a.id] ?? 0;
            final noB = _cardOriginalNumbers[b.id] ?? 0;
            return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
          });
        } else {
          final isNumeric = _isColumnNumeric(sortCol);
          if (isNumeric) {
            final numKeys = <String, num?>{};
            for (final card in result) {
              final val = dataColIndex < card.columns.length ? card.columns[dataColIndex].trim() : '';
              numKeys[card.id] = num.tryParse(val);
            }
            result.sort((a, b) {
              final numA = numKeys[a.id];
              final numB = numKeys[b.id];
              if (numA != null && numB != null) {
                final comp = numA.compareTo(numB);
                if (comp != 0) return _sortAscending ? comp : -comp;
              } else if (numA != null) {
                return _sortAscending ? -1 : 1;
              } else if (numB != null) {
                return _sortAscending ? 1 : -1;
              }
              final noA = _cardOriginalNumbers[a.id] ?? 0;
              final noB = _cardOriginalNumbers[b.id] ?? 0;
              return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
            });
          } else {
            final strKeys = <String, String>{};
            for (final card in result) {
              final val = dataColIndex < card.columns.length ? card.columns[dataColIndex].trim() : '';
              strKeys[card.id] = val.toLowerCase();
            }
            result.sort((a, b) {
              final keyA = strKeys[a.id] ?? '';
              final keyB = strKeys[b.id] ?? '';
              final comp = keyA.compareTo(keyB);
              if (comp != 0) return _sortAscending ? comp : -comp;
              final noA = _cardOriginalNumbers[a.id] ?? 0;
              final noB = _cardOriginalNumbers[b.id] ?? 0;
              return _sortAscending ? noA.compareTo(noB) : noB.compareTo(noA);
            });
          }
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
      _columnFilters.clear();
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
    final lang = context.read<LanguageProvider>().currentLanguage;
    final totalCards = _allCards.length;
    final fromController = TextEditingController(text: (_rangeStart ?? 1).toString());
    final toController = TextEditingController(text: (_rangeEnd ?? totalCards).toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.linear_scale_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Flexible(child: Text(AppStrings.rangeDialogTitle(lang))),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width.clamp(280.0, 380.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang == 'id'
                    ? 'Tentukan batas awal dan akhir baris data yang ingin ditampilkan dan dipelajari (Total data: $totalCards).'
                    : 'Set the start and end row range of data to display and study (Total cards: $totalCards).',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fromController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: lang == 'id' ? 'Dari (No.)' : 'From (No.)',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: toController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: lang == 'id' ? 'Sampai (No.)' : 'To (No.)',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            child: Text(lang == 'id' ? 'Reset Rentang' : 'Reset Range', style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel(lang)),
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
            child: Text(lang == 'id' ? 'Terapkan' : 'Apply'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    final lang = context.read<LanguageProvider>().currentLanguage;
    int tempSortCol = _sortColumnIndex ?? 0;
    bool tempAscending = _sortAscending;
    List<String> tempTypePriority = List.from(_typeSortPriority);

    // Build available sort columns (excluding IPA)
    final availableSortColumns = <Map<String, dynamic>>[];
    availableSortColumns.add({
      'index': 0,
      'title': lang == 'id' ? 'No. (Urutan Baris)' : 'No. (Row Order)',
    });

    for (int i = 0; i < widget.columnHeaders.length; i++) {
      final header = widget.columnHeaders[i];
      if (header.trim().toLowerCase() == 'ipa') continue; // Exclude IPA
      availableSortColumns.add({
        'index': i + 1,
        'title': header, // Raw header from Excel
      });
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
          final showTypePriority = isType;
          final isCefr = selectedColName == 'cefr' || selectedColName == 'cerf' || selectedColName == 'level';
          final isNumeric = _isColumnNumeric(tempSortCol);

          return AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_vert_rounded, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Flexible(child: Text(AppStrings.sortDataTitle(lang))),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width.clamp(280.0, 480.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.selectColToSort(lang),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

                    // Special UI for TYPE / No: Reorderable Priority List
                    if (showTypePriority && tempTypePriority.isNotEmpty) ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          const Icon(Icons.drag_indicator, size: 18, color: Colors.blueAccent),
                          Text(
                            AppStrings.typePriorityTitle(lang),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.typePriorityDesc(lang),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: (tempTypePriority.length * 52.0).clamp(160.0, 270.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).cardColor,
                        ),
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: tempTypePriority.length,
                          onReorderItem: (oldIndex, newIndex) {
                            setDialogState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = tempTypePriority.removeAt(oldIndex);
                              tempTypePriority.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, idx) {
                            final typeName = tempTypePriority[idx];
                            final isFirst = idx == 0;
                            final isLast = idx == tempTypePriority.length - 1;

                            return ListTile(
                              key: ValueKey('type_priority_$typeName'),
                              dense: true,
                              contentPadding: const EdgeInsets.only(left: 10, right: 4),
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Quick Up Button (convenient on mobile)
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
                                              final item = tempTypePriority.removeAt(idx);
                                              tempTypePriority.insert(idx - 1, item);
                                            });
                                          },
                                  ),
                                  // Quick Down Button (convenient on mobile)
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
                                              final item = tempTypePriority.removeAt(idx);
                                              tempTypePriority.insert(idx + 1, item);
                                            });
                                          },
                                  ),
                                  const SizedBox(width: 2),
                                  // Touch Drag Handle
                                  ReorderableDragStartListener(
                                    index: idx,
                                    child: const MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                        child: Icon(Icons.drag_handle, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.priorityDirection(lang),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      Text(
                        AppStrings.selectSortDirection(lang),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                                        ? (lang == 'id' ? 'A1 → C2 (Ascending / Level Dasar ke Mahir)' : 'A1 → C2 (Ascending / Basic to Advanced)')
                                        : showTypePriority
                                            ? (lang == 'id' ? 'Prioritas Teratas ke Terbawah (Ascending)' : 'Top Priority to Bottom (Ascending)')
                                            : isScore
                                                ? (lang == 'id' ? '-100 → 0 → +100 (Ascending / Terendah ke Tertinggi)' : '-100 → 0 → +100 (Ascending / Lowest to Highest)')
                                                : isNumeric
                                                    ? (lang == 'id' ? '0 → 9 (Ascending / Kecil ke Besar)' : '0 → 9 (Ascending / Low to High)')
                                                    : (lang == 'id' ? 'A → Z (Ascending / Dari A ke Z)' : 'A → Z (Ascending / A to Z)'),
                                    style: TextStyle(
                                      fontWeight: tempAscending ? FontWeight.bold : FontWeight.normal,
                                      color: tempAscending ? Colors.blueAccent : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCefr
                                        ? (lang == 'id' ? 'Urutkan berdasarkan tingkatan level CEFR standar' : 'Sort by standard CEFR level progression')
                                        : showTypePriority
                                            ? (lang == 'id' ? 'Data dengan tipe urutan teratas akan ditampilkan lebih dulu' : 'Data with top priority types will appear first')
                                            : isScore
                                                ? (lang == 'id' ? 'Urutkan angka score negatif, nol, hingga positif' : 'Sort score numbers from negative to zero to positive')
                                                : isNumeric
                                                    ? (lang == 'id' ? 'Urutkan angka dari nilai terendah ke tertinggi' : 'Sort numbers from lowest to highest')
                                                    : (lang == 'id' ? 'Urutkan teks berdasarkan alfabet A ke Z' : 'Sort text alphabetically from A to Z'),
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
                                        ? (lang == 'id' ? 'C2 → A1 (Descending / Level Mahir ke Dasar)' : 'C2 → A1 (Descending / Advanced to Basic)')
                                        : showTypePriority
                                            ? (lang == 'id' ? 'Prioritas Terbawah ke Teratas (Descending)' : 'Bottom Priority to Top (Descending)')
                                            : isScore
                                                ? (lang == 'id' ? '+100 → 0 → -100 (Descending / Tertinggi ke Terendah)' : '+100 → 0 → -100 (Descending / Highest to Lowest)')
                                                : isNumeric
                                                    ? (lang == 'id' ? '9 → 0 (Descending / Besar ke Kecil)' : '9 → 0 (Descending / High to Low)')
                                                    : (lang == 'id' ? 'Z → A (Descending / Dari Z ke A)' : 'Z → A (Descending / Z to A)'),
                                    style: TextStyle(
                                      fontWeight: !tempAscending ? FontWeight.bold : FontWeight.normal,
                                      color: !tempAscending ? Colors.blueAccent : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCefr
                                        ? (lang == 'id' ? 'Urutkan terbalik dari level tertinggi C2 ke level dasar A1' : 'Sort backwards from highest level C2 to basic A1')
                                        : showTypePriority
                                            ? (lang == 'id' ? 'Data dengan tipe urutan terbawah akan ditampilkan lebih dulu' : 'Data with lower priority types will appear first')
                                            : isScore
                                                ? (lang == 'id' ? 'Urutkan angka score positif, nol, hingga negatif' : 'Sort score numbers from positive to zero to negative')
                                                : isNumeric
                                                    ? (lang == 'id' ? 'Urutkan angka dari nilai tertinggi ke terendah' : 'Sort numbers from highest to lowest')
                                                    : (lang == 'id' ? 'Urutkan teks terbalik dari alfabet Z ke A' : 'Sort text backwards from Z to A'),
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
                    _formattedTypeCache.clear();
                    _currentPage = 0;
                  });
                  _applyFilterAndSort();
                  _saveCurrentConfig();
                  Navigator.pop(dialogContext);
                },
                child: Text(lang == 'id' ? 'Reset Sort' : 'Reset Sort', style: const TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppStrings.cancel(lang)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sortColumnIndex = tempSortCol;
                    _sortAscending = tempAscending;
                    if (isType) {
                      _typeSortPriority = List.from(tempTypePriority);
                      _formattedTypeCache.clear();
                    }
                    _currentPage = 0;
                  });
                  _applyFilterAndSort();
                  _saveCurrentConfig();
                  Navigator.pop(dialogContext);
                },
                child: Text(lang == 'id' ? 'Terapkan' : 'Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final filterableColumns = [
      ...widget.columnHeaders.where((h) => h.trim().toLowerCase() != 'ipa'),
      'Score',
    ];
    if (filterableColumns.isEmpty) return;

    final tempFilters = <String, Set<String>>{};
    for (final col in filterableColumns) {
      if (col == 'Score') {
        final scoreSet = <String>{};
        if (_includePositiveScore) scoreSet.add('+ (Score > 0)');
        if (_includeZeroScore) scoreSet.add('0 (Score = 0)');
        if (_includeNegativeScore) scoreSet.add('- (Score < 0)');
        tempFilters['Score'] = scoreSet;
      } else if (_columnFilters.containsKey(col)) {
        tempFilters[col] = Set.from(_columnFilters[col]!);
      } else {
        tempFilters[col] = Set.from(_getUniqueValuesForColumn(col));
      }
    }

    String selectedCol;
    if (_lastSelectedFilterColumn != null && filterableColumns.contains(_lastSelectedFilterColumn)) {
      selectedCol = _lastSelectedFilterColumn!;
    } else {
      final isScoreActive = !(_includeNegativeScore && _includeZeroScore && _includePositiveScore);
      final activeFilteredCol = isScoreActive
          ? 'Score'
          : filterableColumns.firstWhere(
              (col) => _columnFilters.containsKey(col) && _columnFilters[col]!.length < _getUniqueValuesForColumn(col).length,
              orElse: () => filterableColumns.first,
            );
      selectedCol = activeFilteredCol;
      _lastSelectedFilterColumn = selectedCol;
    }
    String filterQuery = '';
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final currentValues = _getUniqueValuesForColumn(selectedCol);
          final selectedForCol = tempFilters[selectedCol] ?? Set.from(currentValues);
          final query = filterQuery.toLowerCase().trim();
          final displayValues = query.isEmpty
              ? currentValues
              : currentValues.where((v) => v.toLowerCase().contains(query)).toList();

          return AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_alt_rounded, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Flexible(child: Text(AppStrings.filterDataTitle(lang))),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width.clamp(320.0, 520.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.selectColToFilter(lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCol,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        for (final col in filterableColumns)
                          DropdownMenuItem<String>(
                            value: col,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(col, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (tempFilters.containsKey(col) && tempFilters[col]!.length < (_getUniqueValuesForColumn(col).length)) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${tempFilters[col]!.length}/${_getUniqueValuesForColumn(col).length}',
                                      style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null && val != selectedCol) {
                          _lastSelectedFilterColumn = val;
                          _saveCurrentConfig();
                          setDialogState(() {
                            selectedCol = val;
                            searchController.clear();
                            filterQuery = '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.filterValuesFor(lang, selectedCol),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempFilters[selectedCol] = Set.from(currentValues);
                            });
                          },
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: Text(AppStrings.selectAll(lang), style: const TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempFilters[selectedCol] = <String>{};
                            });
                          },
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: Text(AppStrings.deselectAll(lang), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Quick Search Bar for filter values (hidden for Score)
                    if (selectedCol != 'Score') ...[
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: lang == 'id' ? 'Cari nilai dalam kolom ini...' : 'Search values in this column...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          suffixIcon: filterQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setDialogState(() {
                                      searchController.clear();
                                      filterQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            filterQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (displayValues.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            currentValues.isEmpty
                                ? AppStrings.noValuesToFilter(lang)
                                : (lang == 'id' ? 'Tidak ada nilai yang cocok.' : 'No matching values.'),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ),
                      )
                    else
                      // Virtualized ListView.builder for instant O(1) rendering of any dataset size
                      Container(
                        height: selectedCol == 'Score'
                            ? (displayValues.length * 42.0 + 4.0)
                            : 240.0,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).cardColor,
                        ),
                        child: ListView.builder(
                          itemCount: displayValues.length,
                          itemExtent: 38.0,
                          itemBuilder: (context, idx) {
                            final val = displayValues[idx];
                            final isChecked = selectedForCol.contains(val);
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  final set = Set<String>.from(tempFilters[selectedCol] ?? currentValues);
                                  if (isChecked) {
                                    set.remove(val);
                                  } else {
                                    set.add(val);
                                  }
                                  tempFilters[selectedCol] = set;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: isChecked,
                                        onChanged: (checked) {
                                          setDialogState(() {
                                            final set = Set<String>.from(tempFilters[selectedCol] ?? currentValues);
                                            if (checked == true) {
                                              set.add(val);
                                            } else {
                                              set.remove(val);
                                            }
                                            tempFilters[selectedCol] = set;
                                          });
                                        },
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        val == '(Empty)' ? AppStrings.emptyValue(lang) : val,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontStyle: val == '(Empty)' ? FontStyle.italic : FontStyle.normal,
                                          fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                          color: selectedCol == 'Score'
                                              ? (val.startsWith('+')
                                                  ? Colors.green.shade600
                                                  : (val.startsWith('-')
                                                      ? Colors.red.shade400
                                                      : (isDark ? Colors.white70 : Colors.black87)))
                                              : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                    _columnFilters.clear();
                    _includeNegativeScore = true;
                    _includeZeroScore = true;
                    _includePositiveScore = true;
                    _currentPage = 0;
                  });
                  _applyFilterAndSort();
                  _saveCurrentConfig();
                  Navigator.pop(dialogContext);
                },
                child: Text(AppStrings.resetFilter(lang), style: const TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppStrings.cancel(lang)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (tempFilters.containsKey('Score')) {
                      final selectedScore = tempFilters['Score']!;
                      _includePositiveScore = selectedScore.contains('+ (Score > 0)');
                      _includeZeroScore = selectedScore.contains('0 (Score = 0)');
                      _includeNegativeScore = selectedScore.contains('- (Score < 0)');
                    }

                    final newFilters = <String, Set<String>>{};
                    for (final entry in tempFilters.entries) {
                      final col = entry.key;
                      if (col == 'Score') continue;
                      final selected = entry.value;
                      final totalUnique = _getUniqueValuesForColumn(col).length;
                      if (selected.length < totalUnique) {
                        newFilters[col] = selected;
                      }
                    }
                    _columnFilters = newFilters;
                    _currentPage = 0;
                  });
                  _applyFilterAndSort();
                  _saveCurrentConfig();
                  Navigator.pop(dialogContext);
                },
                child: Text(lang == 'id' ? 'Terapkan' : 'Apply'),
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
    final lang = context.read<LanguageProvider>().currentLanguage;
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
                  AppStrings.editRowTitle(lang, displayNumber),
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
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lang == 'id'
                                ? 'Nomor baris (No.) adalah penomoran urut tampilan. Kolom data di bawah dapat diedit.'
                                : 'Row number (No.) is display order. Data columns below can be edited.',
                            style: const TextStyle(fontSize: 12),
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
                        labelText: AppStrings.formatColumnHeader(columnHeaders[i], lang),
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
                    decoration: InputDecoration(
                      labelText: AppStrings.formatColumnHeader('Score', lang),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      helperText: lang == 'id' ? 'Skor pemahaman kartu flashcard' : 'Flashcard comprehension score',
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
                    message: lang == 'id' ? 'Perubahan data berhasil disimpan' : 'Data changes saved successfully',
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
    final lang = context.read<LanguageProvider>().currentLanguage;
    final firstCol = card.columns.isNotEmpty ? card.columns[0] : '';
    final currentDeck = _getCurrentDeck();
    final isCustomDb = currentDeck?.id == 'custom_mode_deck_default';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isCustomDb
              ? (lang == 'id' ? 'Hapus Baris (Pindahkan ke Trash)' : 'Delete Row (Move to Trash)')
              : (lang == 'id' ? 'Hapus Baris' : 'Delete Row'),
        ),
        content: Text(
          lang == 'id'
              ? 'Yakin ingin menghapus kata "$firstCol"?\nData ini akan dipindahkan ke Deleted Data dan dapat dikembalikan kapan saja.'
              : 'Are you sure you want to delete word "$firstCol"?\nThis data will be moved to Deleted Data and can be restored anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel(lang)),
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
                  message: lang == 'id'
                      ? 'Baris "$firstCol" dipindahkan ke Deleted Data'
                      : 'Row "$firstCol" moved to Deleted Data',
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
            child: Text(AppStrings.delete(lang), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _copyPrompt() {
    final lang = context.read<LanguageProvider>().currentLanguage;
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
        SnackBar(
          content: Text(AppStrings.noWordForPrompt(lang)),
          duration: const Duration(seconds: 2),
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
              ? (lang == 'id'
                  ? 'Prompt berhasil disalin untuk ${_selectedCardIds.length} kata terpilih!'
                  : 'Prompt copied for ${_selectedCardIds.length} selected words!')
              : (lang == 'id'
                  ? 'Prompt berhasil disalin untuk ${cardsToCopy.length} kata!'
                  : 'Prompt copied for ${cardsToCopy.length} words!'),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildZoomButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return Center(
      child: InkWell(
        onTap: () => _showZoomDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: lang == 'id'
              ? 'Zoom Ukuran Tabel ($_zoomPercent%)'
              : 'Table Zoom ($_zoomPercent%)',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: _zoomPercent < 100
                  ? Colors.amber.withValues(alpha: 0.18)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _zoomPercent < 100
                    ? Colors.amber.shade700
                    : (isDark ? Colors.white24 : Colors.black12),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _zoomPercent < 100 ? Icons.zoom_out_rounded : Icons.zoom_in_rounded,
                  size: 15,
                  color: _zoomPercent < 100 ? Colors.amber.shade800 : null,
                ),
                const SizedBox(width: 3),
                Text(
                  '$_zoomPercent%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _zoomPercent < 100 ? Colors.amber.shade800 : null,
                  ),
                ),
                const SizedBox(width: 1),
                Icon(
                  Icons.arrow_drop_down,
                  size: 14,
                  color: _zoomPercent < 100 ? Colors.amber.shade800 : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showZoomDialog(BuildContext context) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    int tempZoom = _zoomPercent;
    final inputController = TextEditingController(text: tempZoom.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateZoom(int val) {
            final clamped = val.clamp(50, 100);
            setDialogState(() {
              tempZoom = clamped;
              inputController.text = clamped.toString();
            });
            setState(() {
              _zoomPercent = clamped;
            });
            _saveZoomPreference(clamped);
          }

          return AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.zoom_in_rounded, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    lang == 'id' ? 'Ukuran Tabel (Zoom)' : 'Table Zoom Size',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width.clamp(280.0, 360.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'id'
                        ? 'Atur persentase ukuran tampilan tabel (50% – 100%).'
                        : 'Adjust table scale percentage (50% – 100%).',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'id' ? 'Persentase:' : 'Percentage:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: TextField(
                          controller: inputController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          decoration: InputDecoration(
                            suffixText: '%',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onSubmitted: (val) {
                            final parsed = int.tryParse(val.trim());
                            if (parsed != null) updateZoom(parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('50%', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Expanded(
                        child: Slider(
                          value: tempZoom.toDouble(),
                          min: 50.0,
                          max: 100.0,
                          divisions: 50,
                          label: '$tempZoom%',
                          onChanged: (val) {
                            updateZoom(val.round());
                          },
                        ),
                      ),
                      const Text('100%', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang == 'id' ? 'Pilihan Cepat:' : 'Quick Presets:',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final preset in [50, 60, 70, 75, 80, 90, 100])
                        ChoiceChip(
                          label: Text('$preset%', style: const TextStyle(fontSize: 11)),
                          selected: tempZoom == preset,
                          visualDensity: VisualDensity.compact,
                          selectedColor: Colors.blueAccent,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: tempZoom == preset ? FontWeight.bold : FontWeight.normal,
                            color: tempZoom == preset ? Colors.white : null,
                          ),
                          onSelected: (selected) {
                            if (selected) updateZoom(preset);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  updateZoom(100);
                },
                child: Text(
                  lang == 'id' ? 'Reset 100%' : 'Reset 100%',
                  style: const TextStyle(color: Colors.amber),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppStrings.close(lang)),
              ),
            ],
          );
        },
      ),
    ).then((_) => inputController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final langProv = context.watch<LanguageProvider>();
    final lang = langProv.currentLanguage;
    final isCustomDb = _isCustomDatabase();
    final deck = _getCurrentDeck();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.libraryPreviewTitle(lang, deck?.name),
          softWrap: true,
          maxLines: 2,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isCustomDb) ...[
            if (_isRefreshing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _handleRefreshSource,
                icon: const Icon(Icons.sync, size: 20),
                tooltip: AppStrings.refreshSource(lang),
              ),
          ],
          // Zoom In / Out Dropdown / Slider Action (50% - 100%)
          _buildZoomButton(context),
          const SizedBox(width: 4),
          // Modern Copy Prompt Badge Action
          Badge(
            label: Text(
              _selectedCardIds.isNotEmpty
                  ? '${_selectedCardIds.length}'
                  : '${_filteredSortedCards.length}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: _selectedCardIds.isNotEmpty ? Colors.green : Colors.blueAccent,
            isLabelVisible: true,
            child: IconButton(
              onPressed: _copyPrompt,
              icon: Icon(
                Icons.copy_rounded,
                color: _selectedCardIds.isNotEmpty ? Colors.greenAccent : null,
                size: 20,
              ),
              tooltip: _selectedCardIds.isNotEmpty
                  ? (lang == 'id'
                      ? 'Copy Prompt (${_selectedCardIds.length} baris terpilih)'
                      : 'Copy Prompt (${_selectedCardIds.length} rows selected)')
                  : (lang == 'id'
                      ? 'Copy Prompt (Semua ${_filteredSortedCards.length} baris preview)'
                      : 'Copy Prompt (All ${_filteredSortedCards.length} preview rows)'),
            ),
          ),
          const SizedBox(width: 4),
          // Modern Deleted Data Badge Action
          Badge(
            label: Text(
              '${deck?.deletedCards.length ?? 0}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: (deck?.deletedCards.isNotEmpty ?? false) ? Colors.redAccent : Colors.grey[700],
            isLabelVisible: (deck?.deletedCards.length ?? 0) > 0,
            child: IconButton(
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
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Deleted Data (${deck?.deletedCards.length ?? 0} ${lang == 'id' ? 'item' : 'items'})',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
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
    final lang = context.watch<LanguageProvider>().currentLanguage;
    bool isAnyColFiltered = false;
    for (final entry in _columnFilters.entries) {
      final allVals = _getUniqueValuesForColumn(entry.key);
      if (allVals.isNotEmpty && entry.value.length < allVals.length) {
        isAnyColFiltered = true;
        break;
      }
    }
    final isTypeFiltered = _allUniqueTypes.isNotEmpty && _selectedFilterTypes.length < _allUniqueTypes.length;
    final isCefrFiltered = _selectedCefrLevels.length < (_allCefrLevels.length + 1);
    final isScoreFiltered = !(_includeNegativeScore && _includeZeroScore && _includePositiveScore);
    final isRangeFiltered = _rangeStart != null || _rangeEnd != null;
    final isFilterActive = isAnyColFiltered || isTypeFiltered || isCefrFiltered || isScoreFiltered;
    final isSpecificFilterActive = isFilterActive || isRangeFiltered;
    final isSorted = _sortColumnIndex != null && !(_sortColumnIndex == 0 && _sortAscending);
    final isFiltered = _searchQuery.isNotEmpty || isSpecificFilterActive || isSorted;

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
                    hintText: AppStrings.searchAllColumns(lang),
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
                tooltip: AppStrings.refineTooltip(lang),
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
                        Expanded(
                          child: Text(
                            AppStrings.sortData(lang),
                            style: const TextStyle(fontWeight: FontWeight.w500),
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
                          color: isFilterActive ? Colors.blueAccent : Colors.grey[400],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.filterData(lang),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (isFilterActive) ...[
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
                        Expanded(
                          child: Text(
                            AppStrings.rangeData(lang),
                            style: const TextStyle(fontWeight: FontWeight.w500),
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
                        AppStrings.refine(lang),
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
                  tooltip: lang == 'id' ? 'Reset Semua Filter, Sort & Range' : 'Reset All Filters, Sort & Range',
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
                    sortLabel = 'Sort: Type (${_sortAscending ? (lang == 'id' ? "Prioritas #1" : "Priority #1") : (lang == 'id' ? "Prioritas Terbalik" : "Reverse Priority")})';
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
                    label: '${lang == 'id' ? 'Cari' : 'Search'}: "$_searchQuery"',
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
                    label: 'Type: ${_selectedFilterTypes.length}/${_allUniqueTypes.length} ${lang == 'id' ? 'dipilih' : 'selected'}',
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

                for (final entry in _columnFilters.entries) {
                  final header = entry.key;
                  final selectedVals = entry.value;
                  final allVals = _getUniqueValuesForColumn(header);
                  if (selectedVals.length < allVals.length) {
                    activeItems.add(_ActiveFilterItem(
                      icon: Icons.filter_list_rounded,
                      label: '$header: ${selectedVals.length}/${allVals.length} ${lang == "id" ? "dipilih" : "selected"}',
                      onDeleted: () {
                        setState(() {
                          _columnFilters.remove(header);
                          _currentPage = 0;
                        });
                        _applyFilterAndSort();
                        _saveCurrentConfig();
                      },
                    ));
                  }
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
                          Text(
                            AppStrings.activeFilter(lang),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          PopupMenuButton<VoidCallback>(
                            tooltip: AppStrings.manageActiveFilters(lang),
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
                                child: Row(
                                  children: [
                                    const Icon(Icons.refresh_rounded, size: 16, color: Colors.red),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppStrings.resetAllFilters(lang),
                                        style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
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
                                    AppStrings.criteriaActive(lang, activeItems.length),
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
                        Text(AppStrings.activeFilter(lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
    final lang = context.watch<LanguageProvider>().currentLanguage;
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
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.dataPreview(lang),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_filteredSortedCards.length} / ${_allCards.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                // Rows per page dropdown
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      isDense: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: 25, child: Text(lang == 'id' ? '25 baris/hal' : '25/page', style: const TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 50, child: Text(lang == 'id' ? '50 baris/hal' : '50/page', style: const TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 100, child: Text(lang == 'id' ? '100 baris/hal' : '100/page', style: const TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rowsPerPage = val;
                            _currentPage = 0;
                            // Clear any range restriction below the chosen page size (e.g. 50 limit when choosing 100)
                            if (_rangeEnd != null && _rangeEnd! < val && (_rangeStart == null || _rangeStart == 1)) {
                              _rangeStart = null;
                              _rangeEnd = null;
                            }
                          });
                          _applyFilterAndSort();
                          _saveCurrentConfig();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (_selectedCardIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_selectedCardIds.length} ${lang == 'id' ? "baris dipilih" : "rows selected"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCardIds.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(Icons.close, size: 16, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (pageCards.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    lang == 'id'
                        ? 'Tidak ada data yang cocok dengan kriteria pencarian/filter.'
                        : 'No data matches the search/filter criteria.',
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                controller: _horizontalScrollController,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.hardEdge,
                child: RepaintBoundary(
                  child: () {
                    final zoomScale = (_zoomPercent / 100.0).clamp(0.5, 1.0);
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final isCustomDb = _isCustomDatabase();
                    final typeColIdx = _getTypeColumnIndex();

                    final noPillWidth = (46.0 * zoomScale).clamp(28.0, 46.0);
                    final noPillHeight = (30.0 * zoomScale).clamp(20.0, 30.0);
                    final noPillRadius = BorderRadius.circular(8 * zoomScale);
                    final noPillBorderWidth = 1.5 * zoomScale;
                    final noPillPadH = 6 * zoomScale;
                    final noPillPadV = 3 * zoomScale;
                    final noPillBoxConstraints = BoxConstraints(minWidth: noPillWidth, minHeight: noPillHeight);
                    final noPillPadding = EdgeInsets.symmetric(horizontal: noPillPadH, vertical: noPillPadV);

                    final noPillSelectedDecoration = BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: noPillRadius,
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: noPillBorderWidth,
                      ),
                    );
                    final noPillUnselectedDecoration = BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: noPillRadius,
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black12,
                        width: noPillBorderWidth,
                      ),
                    );

                    final cellFontSize = (13.0 * zoomScale).clamp(8.5, 13.0);
                    final cellMaxWidth = (240.0 * zoomScale).clamp(110.0, 240.0);
                    final cellTextStyle = TextStyle(fontSize: cellFontSize);

                    final scoreFontSize = (12.0 * zoomScale).clamp(8.0, 12.0);
                    final scorePadH = (8.0 * zoomScale).clamp(4.0, 8.0);
                    final scorePadV = (3.0 * zoomScale).clamp(1.5, 3.0);
                    final scoreRadius = BorderRadius.circular(6 * zoomScale);
                    final scorePadding = EdgeInsets.symmetric(horizontal: scorePadH, vertical: scorePadV);

                    final scorePositiveDecoration = BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: scoreRadius,
                      border: Border.all(color: Colors.green.shade600, width: 1),
                    );
                    final scoreNegativeDecoration = BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: scoreRadius,
                      border: Border.all(color: Colors.red.shade400, width: 1),
                    );
                    final scoreZeroDecoration = BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      borderRadius: scoreRadius,
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    );

                    final scorePositiveStyle = TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: scoreFontSize,
                      color: Colors.green.shade700,
                    );
                    final scoreNegativeStyle = TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: scoreFontSize,
                      color: Colors.red.shade700,
                    );
                    final scoreZeroStyle = TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: scoreFontSize,
                      color: isDark ? Colors.white70 : Colors.black87,
                    );

                    const rowSelectedColor = WidgetStatePropertyAll<Color?>(Color(0x264CAF50));

                    final iconBtnSize = (20.0 * zoomScale).clamp(14.0, 20.0);
                    final iconBtnConstraints = BoxConstraints(minWidth: 26 * zoomScale, minHeight: 26 * zoomScale);

                    return DataTable(
                      showCheckboxColumn: false,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      columnSpacing: (18.0 * zoomScale).clamp(6.0, 18.0),
                      dataRowMinHeight: (48.0 * zoomScale).clamp(26.0, 48.0),
                      dataRowMaxHeight: (48.0 * zoomScale).clamp(26.0, 48.0),
                      headingRowHeight: (56.0 * zoomScale).clamp(32.0, 56.0),
                      columns: [
                        DataColumn(
                          label: Tooltip(
                            message: lang == 'id'
                                ? 'Tekan lama nomor baris No. untuk memilih'
                                : 'Long press row No. to select',
                            child: Text(
                              'No.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: (14.0 * zoomScale).clamp(9.0, 14.0),
                              ),
                            ),
                          ),
                          onSort: (colIdx, asc) => _onSort(0, asc),
                        ),
                        for (int i = 0; i < widget.columnHeaders.length; i++)
                          DataColumn(
                            label: Text(
                              widget.columnHeaders[i],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: (14.0 * zoomScale).clamp(9.0, 14.0),
                              ),
                            ),
                            onSort: (colIdx, asc) => _onSort(i + 1, asc),
                          ),
                        DataColumn(
                          label: Text(
                            'Score',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (14.0 * zoomScale).clamp(9.0, 14.0),
                            ),
                          ),
                          onSort: (colIdx, asc) => _onSort(widget.columnHeaders.length + 1, asc),
                        ),
                        DataColumn(
                          label: Text(
                            AppStrings.tableAction(lang),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: (14.0 * zoomScale).clamp(9.0, 14.0),
                            ),
                          ),
                        ),
                      ],
                      rows: [
                        for (int i = 0; i < pageCards.length; i++)
                          _createDataRow(
                            pageCards[i],
                            startIdx + i + 1,
                            zoomScale,
                            lang: lang,
                            isDark: isDark,
                            isCustomDb: isCustomDb,
                            typeColIdx: typeColIdx,
                            noPillRadius: noPillRadius,
                            noPillBoxConstraints: noPillBoxConstraints,
                            noPillPadding: noPillPadding,
                            noPillSelectedDecoration: noPillSelectedDecoration,
                            noPillUnselectedDecoration: noPillUnselectedDecoration,
                            rowSelectedColor: rowSelectedColor,
                            cellMaxWidth: cellMaxWidth,
                            cellTextStyle: cellTextStyle,
                            scorePadding: scorePadding,
                            scorePositiveDecoration: scorePositiveDecoration,
                            scoreNegativeDecoration: scoreNegativeDecoration,
                            scoreZeroDecoration: scoreZeroDecoration,
                            scorePositiveStyle: scorePositiveStyle,
                            scoreNegativeStyle: scoreNegativeStyle,
                            scoreZeroStyle: scoreZeroStyle,
                            iconBtnSize: iconBtnSize,
                            iconBtnConstraints: iconBtnConstraints,
                          ),
                      ],
                    );
                  }(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableActionBtn({
    required IconData icon,
    required Color color,
    required double size,
    required BoxConstraints constraints,
    required VoidCallback onTap,
  }) {
    return InkResponse(
      onTap: onTap,
      radius: (size * 1.1).clamp(14.0, 24.0),
      child: Container(
        constraints: constraints,
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: size),
      ),
    );
  }

  DataRow _createDataRow(
    FlashcardCard card,
    int absoluteIndex,
    double zoomScale, {
    required String lang,
    required bool isDark,
    required bool isCustomDb,
    required int? typeColIdx,
    required BorderRadius noPillRadius,
    required BoxConstraints noPillBoxConstraints,
    required EdgeInsets noPillPadding,
    required BoxDecoration noPillSelectedDecoration,
    required BoxDecoration noPillUnselectedDecoration,
    required WidgetStatePropertyAll<Color?> rowSelectedColor,
    required double cellMaxWidth,
    required TextStyle cellTextStyle,
    required EdgeInsets scorePadding,
    required BoxDecoration scorePositiveDecoration,
    required BoxDecoration scoreNegativeDecoration,
    required BoxDecoration scoreZeroDecoration,
    required TextStyle scorePositiveStyle,
    required TextStyle scoreNegativeStyle,
    required TextStyle scoreZeroStyle,
    required double iconBtnSize,
    required BoxConstraints iconBtnConstraints,
  }) {
    final originalNo = _cardOriginalNumbers[card.id] ?? absoluteIndex;
    final columns = card.columns;
    final isSelected = _selectedCardIds.contains(card.id);
    final noFontSize = ((originalNo.toString().length >= 5 ? 11.0 : 12.5) * zoomScale).clamp(7.5, 12.5);

    return DataRow(
      color: isSelected ? rowSelectedColor : null,
      cells: [
        DataCell(
          InkWell(
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
            borderRadius: noPillRadius,
            child: Container(
              constraints: noPillBoxConstraints,
              padding: noPillPadding,
              alignment: Alignment.center,
              decoration: isSelected ? noPillSelectedDecoration : noPillUnselectedDecoration,
              child: Text(
                originalNo.toString(),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: noFontSize,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ),
        ),
        for (int i = 0; i < widget.columnHeaders.length; i++)
          DataCell(
            SizedBox(
              width: cellMaxWidth,
              child: Text(
                i < columns.length
                    ? (i == typeColIdx ? _formatCardType(columns[i]) : columns[i])
                    : '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: cellTextStyle,
              ),
            ),
          ),
        DataCell(
          Center(
            child: Container(
              padding: scorePadding,
              decoration: card.score > 0
                  ? scorePositiveDecoration
                  : (card.score < 0 ? scoreNegativeDecoration : scoreZeroDecoration),
              child: Text(
                card.score.toString(),
                style: card.score > 0
                    ? scorePositiveStyle
                    : (card.score < 0 ? scoreNegativeStyle : scoreZeroStyle),
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCustomDb)
                _buildTableActionBtn(
                  icon: Icons.sync,
                  color: Colors.blueAccent,
                  size: iconBtnSize,
                  constraints: iconBtnConstraints,
                  onTap: () => _handleRefreshSingleCard(card),
                ),
              _buildTableActionBtn(
                icon: Icons.edit_outlined,
                color: Colors.amber,
                size: iconBtnSize,
                constraints: iconBtnConstraints,
                onTap: () => _showEditCardDialog(card, originalNo),
              ),
              _buildTableActionBtn(
                icon: Icons.close,
                color: Colors.red,
                size: iconBtnSize,
                constraints: iconBtnConstraints,
                onTap: () => _confirmDelete(card),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showJumpToPageDialog(int totalPages) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final pageController = TextEditingController(text: ''); // blank/empty by default

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

  Widget _buildPaginationControls(BuildContext context) {
    if (_filteredSortedCards.isEmpty) return const SizedBox.shrink();

    final lang = context.watch<LanguageProvider>().currentLanguage;
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
          lang == 'id'
              ? 'Menampilkan $startIdx - $endIdx dari $totalRows data'
              : 'Showing $startIdx - $endIdx of $totalRows entries',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
              tooltip: lang == 'id' ? 'Halaman Sebelumnya' : 'Previous Page',
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
                      lang == 'id'
                          ? 'Halaman ${_currentPage + 1} dari $totalPages'
                          : 'Page ${_currentPage + 1} of $totalPages',
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
              tooltip: lang == 'id' ? 'Halaman Berikutnya' : 'Next Page',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
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
              child: Text(AppStrings.close(lang)),
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


