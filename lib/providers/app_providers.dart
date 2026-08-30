import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/deck.dart';
import '../models/deck_config.dart';
import '../models/flashcard_card.dart';
import '../models/order_mode.dart';
import '../services/storage_service.dart';
import '../services/excel_service.dart';

class DeckProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Deck> _decks = [];
  Deck? _selectedDeck;
  final Map<String, DeckConfig> _deckConfigs = {};

  List<Deck> get decks => _decks;
  Deck? get selectedDeck => _selectedDeck;

  Future<void> loadDecks() async {
    _decks = await _storageService.loadDecks();
    
    // Auto-fix any decks that were imported with more than 6 columns
    // (backward compatibility fix for when 10 columns were allowed)
    bool needsSave = false;
    for (int i = 0; i < _decks.length; i++) {
      final deck = _decks[i];
      Deck currentDeck = deck;
      bool modified = false;

      // Fix 1: Truncate decks with > 6 columns
      if (currentDeck.columnCount > 6) {
        final newHeaders = currentDeck.columnHeaders.length > 6 
            ? currentDeck.columnHeaders.sublist(0, 6) 
            : currentDeck.columnHeaders;
            
        final newCards = currentDeck.cards.map((card) {
          return card.copyWith(
            columns: card.columns.length > 6 
                ? card.columns.sublist(0, 6) 
                : card.columns,
          );
        }).toList();
        
        currentDeck = currentDeck.copyWith(
          columnCount: 6,
          columnHeaders: newHeaders,
          cards: newCards,
        );
        modified = true;
      }

      // Fix 2: Ensure visibleColumnCount is never greater than columnCount
      // (This recovers decks corrupted by previous versions)
      if (currentDeck.visibleColumnCount > currentDeck.columnCount) {
        currentDeck = currentDeck.copyWith(
          visibleColumnCount: currentDeck.columnCount,
        );
        modified = true;
      }

      if (modified) {
        _decks[i] = currentDeck;
        needsSave = true;
      }
    }
    
    // Auto-create "Custom Mode" deck if it doesn't exist
    final hasCustomDeck = _decks.any((d) => d.name == 'Custom Mode');
    if (!hasCustomDeck) {
      final customDeck = Deck(
        id: 'custom_mode_deck_default',
        name: 'Custom Mode',
        columnCount: 2,
        columnHeaders: ['Kata', 'Arti'],
        cards: [],
      );
      _decks.insert(0, customDeck);
      needsSave = true;
    }

    if (needsSave) {
      await _storageService.saveDecks(_decks);
    }
    
    notifyListeners();
  }

  Future<Deck?> importDeckFromFile(String filePath, String customName) async {
    try {
      final fileName = filePath.split(Platform.pathSeparator).last.replaceAll(RegExp(r'\.xlsx?$'), '');
      final deckName = customName.isEmpty ? fileName : customName;

      final deck = await ExcelService.parseExcelFile(filePath, deckName);
      return deck;
    } catch (e) {
      debugPrint('Error importing deck: $e');
      rethrow;
    }
  }

  Future<Deck?> importDeckFromFileBytes(
    List<int> bytes,
    String customName, {
    String? fileName,
    String? targetSheetName,
    List<int>? importOrder,
  }) async {
    try {
      final sanitizedFileName = (fileName ?? 'Imported Deck').replaceAll(
        RegExp(r'\.xlsx?$', caseSensitive: false),
        '',
      );
      final deckName = customName.isEmpty ? sanitizedFileName : customName;

      final deck = await ExcelService.parseExcelFileFromBytes(
        bytes,
        deckName,
        fileName: fileName,
        targetSheetName: targetSheetName,
        importOrder: importOrder,
      );
      return deck;
    } catch (e) {
      debugPrint('Error importing deck from bytes: $e');
      rethrow;
    }
  }

  Future<void> addDeck(Deck deck) async {
    final existingIndex = _decks.indexWhere((d) => d.name == deck.name);
    if (existingIndex != -1) {
      deck = deck.copyWith(name: _generateUniqueName(deck.name));
    }

    _decks.add(deck);
    await _storageService.saveDecks(_decks);
    notifyListeners();
  }

  String _generateUniqueName(String baseName) {
    final existingNames = _decks.map((d) => d.name).toSet();
    var counter = 2;
    String newName = '$baseName ($counter)';
    while (existingNames.contains(newName) && counter < 10000) {
      counter++;
      newName = '$baseName ($counter)';
    }
    return newName;
  }

  Future<void> deleteDeck(String deckId) async {
    await _storageService.deleteDeck(deckId);
    _decks.removeWhere((deck) => deck.id == deckId);

    if (_selectedDeck?.id == deckId) {
      _selectedDeck = null;
    }

    notifyListeners();
  }

  Future<void> renameDeck(String deckId, String newName) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index != -1) {
      _decks[index] = _decks[index].copyWith(name: newName);
      await _storageService.saveDecks(_decks);

      if (_selectedDeck?.id == deckId) {
        _selectedDeck = _decks[index];
      }

      notifyListeners();
    }
  }

  Future<void> updateDeck(Deck updatedDeck) async {
    final index = _decks.indexWhere((deck) => deck.id == updatedDeck.id);
    if (index != -1) {
      _decks[index] = updatedDeck;
      await _storageService.saveDecks(_decks);

      if (_selectedDeck?.id == updatedDeck.id) {
        _selectedDeck = updatedDeck;
      }

      notifyListeners();
    }
  }

  Future<void> updateCardInDeck(String deckId, FlashcardCard updatedCard) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index != -1) {
      final updatedDeck = _decks[index].updateCard(updatedCard);
      _decks[index] = updatedDeck;
      await _storageService.saveDecks(_decks);

      if (_selectedDeck?.id == deckId) {
        _selectedDeck = updatedDeck;
      }

      notifyListeners();
    }
  }

  /// Updates a card and synchronizes changes across Custom Database and Source Datasets
  Future<void> updateCardWithCrossDeckSync(
    String currentDeckId,
    FlashcardCard updatedCard, {
    String? originalWord,
  }) async {
    final searchWord = (originalWord ?? (updatedCard.columns.isNotEmpty ? updatedCard.columns[0] : '')).trim().toLowerCase();
    bool modified = false;

    // 1. Update current deck
    final currentDeckIndex = _decks.indexWhere((d) => d.id == currentDeckId);
    if (currentDeckIndex != -1) {
      _decks[currentDeckIndex] = _decks[currentDeckIndex].updateCard(updatedCard);
      modified = true;
    }

    final isCustomDeck = currentDeckId == 'custom_mode_deck_default' ||
        (_decks.any((d) => d.id == currentDeckId && d.name.toLowerCase().contains('custom')));

    if (isCustomDeck) {
      // If editing from Custom Deck, sync back to source deck if present
      if (updatedCard.columns.length > 2) {
        final sourceDeckName = updatedCard.columns[2];
        if (sourceDeckName != 'Manual/Custom') {
          final sourceDeckIndex = _decks.indexWhere((d) => d.name == sourceDeckName && d.id != currentDeckId);
          if (sourceDeckIndex != -1) {
            final sourceDeck = _decks[sourceDeckIndex];
            final cardIndex = sourceDeck.cards.indexWhere((c) =>
                c.columns.isNotEmpty && c.columns[0].trim().toLowerCase() == searchWord);
            if (cardIndex != -1) {
              final oldSourceCard = sourceDeck.cards[cardIndex];
              List<String> newSourceCols = List.from(oldSourceCard.columns);
              if (newSourceCols.isNotEmpty) newSourceCols[0] = updatedCard.columns[0];
              if (newSourceCols.length > 1 && updatedCard.columns.length > 1) {
                newSourceCols[1] = updatedCard.columns[1];
              }
              final newSourceCard = oldSourceCard.copyWith(
                columns: newSourceCols,
                score: updatedCard.score,
              );
              _decks[sourceDeckIndex] = sourceDeck.updateCard(newSourceCard);
            }
          }
        }
      }
    } else {
      // If editing from a source deck, sync to Custom Deck if it contains this card
      final customDeckIndex = _decks.indexWhere((d) => d.id == 'custom_mode_deck_default');
      if (customDeckIndex != -1) {
        final currentDeckName = currentDeckIndex != -1 ? _decks[currentDeckIndex].name : '';
        final customDeck = _decks[customDeckIndex];
        final customCardIndex = customDeck.cards.indexWhere((c) =>
            (c.columns.isNotEmpty && c.columns[0].trim().toLowerCase() == searchWord) ||
            (c.columns.length > 2 && c.columns[2] == currentDeckName && c.columns[0].trim().toLowerCase() == searchWord));

        if (customCardIndex != -1) {
          final oldCustomCard = customDeck.cards[customCardIndex];
          List<String> newCustomCols = List.from(oldCustomCard.columns);
          if (newCustomCols.isNotEmpty) newCustomCols[0] = updatedCard.columns[0];
          if (newCustomCols.length > 1 && updatedCard.columns.length > 1) {
            newCustomCols[1] = updatedCard.columns[1];
          }
          // Update trailing source columns if they match source format
          if (newCustomCols.length > 3) {
            for (int i = 0; i < updatedCard.columns.length && (i + 3) < newCustomCols.length; i++) {
              newCustomCols[i + 3] = updatedCard.columns[i];
            }
          }
          final newCustomCard = oldCustomCard.copyWith(
            columns: newCustomCols,
            score: updatedCard.score,
          );
          _decks[customDeckIndex] = customDeck.updateCard(newCustomCard);
        }
      }
    }

    if (modified) {
      await _storageService.saveDecks(_decks);
      if (_selectedDeck != null) {
        final selectedIndex = _decks.indexWhere((d) => d.id == _selectedDeck!.id);
        if (selectedIndex != -1) {
          _selectedDeck = _decks[selectedIndex];
        }
      }
      notifyListeners();
    }
  }

  /// Synchronizes the Custom Deck with the latest data from Source Datasets
  Future<Map<String, int>> refreshCustomDeck(String customDeckId) async {
    final customDeckIndex = _decks.indexWhere((d) => d.id == customDeckId);
    if (customDeckIndex == -1) {
      return {'updated': 0, 'removed': 0, 'total': 0};
    }

    final customDeck = _decks[customDeckIndex];
    final availableSourceDecks = _decks.where((d) => d.id != customDeckId).toList();

    List<FlashcardCard> updatedCards = [];
    int updatedCount = 0;
    int removedCount = 0;

    for (final card in customDeck.cards) {
      final isManual = card.columns.length <= 2 ||
          card.columns[2] == 'Manual/Custom' ||
          card.columns[2].trim().isEmpty;
      if (isManual) {
        updatedCards.add(card);
        continue;
      }

      final sourceDeckName = card.columns[2];
      final word = card.columns.isNotEmpty ? card.columns[0].trim().toLowerCase() : '';

      // Find source deck
      Deck? sourceDeck;
      try {
        sourceDeck = availableSourceDecks.firstWhere((d) => d.name == sourceDeckName);
      } catch (_) {
        // Fallback: search any source deck that has this word
        try {
          sourceDeck = availableSourceDecks.firstWhere((d) =>
              d.cards.any((c) => c.columns.isNotEmpty && c.columns[0].trim().toLowerCase() == word));
        } catch (_) {
          sourceDeck = null;
        }
      }

      if (sourceDeck == null) {
        // Source deck was not found or manual, keep the card intact
        updatedCards.add(card);
        continue;
      }

      // Find matching card in source deck
      FlashcardCard? matchingSourceCard;
      try {
        matchingSourceCard = sourceDeck.cards.firstWhere(
          (c) => c.columns.isNotEmpty && c.columns[0].trim().toLowerCase() == word,
        );
      } catch (_) {
        matchingSourceCard = null;
      }

      if (matchingSourceCard == null) {
        // Word was not found in source deck, keep the card intact
        updatedCards.add(card);
        continue;
      }

      // Rebuild updated columns
      List<String> newCols = [
        matchingSourceCard.columns.isNotEmpty ? matchingSourceCard.columns[0] : card.columns[0],
        matchingSourceCard.columns.length > 1 ? matchingSourceCard.columns[1] : (card.columns.length > 1 ? card.columns[1] : ''),
        sourceDeck.name,
      ];
      newCols.addAll(matchingSourceCard.columns);

      // Pad columns to match customDeck columnCount
      while (newCols.length < customDeck.columnCount) {
        newCols.add('');
      }

      final refreshedCard = card.copyWith(
        columns: newCols,
        score: matchingSourceCard.score,
      );
      updatedCards.add(refreshedCard);
      updatedCount++;
    }

    final newDeck = customDeck.copyWith(cards: updatedCards);
    _decks[customDeckIndex] = newDeck;
    await _storageService.saveDecks(_decks);

    if (_selectedDeck?.id == customDeckId) {
      _selectedDeck = newDeck;
    }

    notifyListeners();
    return {
      'updated': updatedCount,
      'removed': removedCount,
      'total': updatedCards.length,
    };
  }

  /// Soft deletes a card from active cards and moves it into deletedCards.
  Future<void> softDeleteCard(String deckId, String cardId) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index != -1) {
      final updatedDeck = _decks[index].softDeleteCard(cardId);
      _decks[index] = updatedDeck;
      await _storageService.saveDecks(_decks);

      if (_selectedDeck?.id == deckId) {
        _selectedDeck = updatedDeck;
      }

      notifyListeners();
    }
  }

  /// Restores a card from deletedCards back into active cards.
  Future<bool> restoreCard(String deckId, String cardId) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index != -1) {
      final currentDeck = _decks[index];
      // Check if already in active cards to prevent duplication
      if (currentDeck.cards.any((c) => c.id == cardId)) {
        final cleanedDeck = currentDeck.copyWith(
          deletedCards: currentDeck.deletedCards.where((c) => c.id != cardId).toList(),
        );
        _decks[index] = cleanedDeck;
        await _storageService.saveDecks(_decks);
        if (_selectedDeck?.id == deckId) _selectedDeck = cleanedDeck;
        notifyListeners();
        return true;
      }

      final updatedDeck = currentDeck.restoreCard(cardId);
      _decks[index] = updatedDeck;
      await _storageService.saveDecks(_decks);

      if (_selectedDeck?.id == deckId) {
        _selectedDeck = updatedDeck;
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Updates a card inside deletedCards list.
  Future<void> updateDeletedCard(String deckId, FlashcardCard updatedCard) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index != -1) {
      final updatedDeck = _decks[index].updateDeletedCard(updatedCard);
      _decks[index] = updatedDeck;
      await _storageService.saveDecks(_decks);

      if (_selectedDeck?.id == deckId) {
        _selectedDeck = updatedDeck;
      }

      notifyListeners();
    }
  }

  /// Refreshes a single row/card from its source dataset.
  Future<Map<String, dynamic>> refreshSingleCard(
    String deckId,
    String cardId, {
    bool isDeleted = false,
  }) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) {
      return {'success': false, 'message': 'Database tidak ditemukan'};
    }

    final targetDeck = _decks[deckIndex];
    FlashcardCard? card;
    try {
      if (isDeleted) {
        card = targetDeck.deletedCards.firstWhere((c) => c.id == cardId);
      } else {
        card = targetDeck.cards.firstWhere((c) => c.id == cardId);
      }
    } catch (_) {
      card = null;
    }

    if (card == null) {
      return {'success': false, 'message': 'Kartu tidak ditemukan'};
    }

    final isManual = card.columns.length <= 2 || card.columns[2] == 'Manual/Custom';
    if (isManual) {
      return {
        'success': false,
        'message': 'Baris ini dibuat secara manual (tidak memiliki dataset sumber).',
      };
    }

    final sourceDeckName = card.columns[2];
    final word = card.columns.isNotEmpty ? card.columns[0].trim().toLowerCase() : '';
    final availableSourceDecks = _decks.where((d) => d.id != deckId).toList();

    Deck? sourceDeck;
    try {
      sourceDeck = availableSourceDecks.firstWhere((d) => d.name == sourceDeckName);
    } catch (_) {
      try {
        sourceDeck = availableSourceDecks.firstWhere((d) =>
            d.cards.any((c) => c.columns.isNotEmpty && c.columns[0].trim().toLowerCase() == word));
      } catch (_) {
        sourceDeck = null;
      }
    }

    if (sourceDeck == null) {
      return {
        'success': false,
        'message': 'Dataset sumber "$sourceDeckName" tidak ditemukan atau telah dihapus.',
      };
    }

    FlashcardCard? matchingSourceCard;
    try {
      matchingSourceCard = sourceDeck.cards.firstWhere(
        (c) => c.columns.isNotEmpty && c.columns[0].trim().toLowerCase() == word,
      );
    } catch (_) {
      matchingSourceCard = null;
    }

    if (matchingSourceCard == null) {
      return {
        'success': false,
        'message': 'Kata "${card.columns[0]}" tidak ditemukan di dataset "${sourceDeck.name}".',
      };
    }

    // Rebuild updated columns
    List<String> newCols = [
      matchingSourceCard.columns.isNotEmpty ? matchingSourceCard.columns[0] : card.columns[0],
      matchingSourceCard.columns.length > 1 ? matchingSourceCard.columns[1] : (card.columns.length > 1 ? card.columns[1] : ''),
      sourceDeck.name,
    ];
    newCols.addAll(matchingSourceCard.columns);

    while (newCols.length < targetDeck.columnCount) {
      newCols.add('');
    }

    final refreshedCard = card.copyWith(
      columns: newCols,
      score: matchingSourceCard.score,
    );

    Deck updatedDeck;
    if (isDeleted) {
      updatedDeck = targetDeck.updateDeletedCard(refreshedCard);
    } else {
      updatedDeck = targetDeck.updateCard(refreshedCard);
    }

    _decks[deckIndex] = updatedDeck;
    await _storageService.saveDecks(_decks);

    if (_selectedDeck?.id == deckId) {
      _selectedDeck = updatedDeck;
    }

    notifyListeners();
    return {
      'success': true,
      'card': refreshedCard,
      'sourceName': sourceDeck.name,
      'message': 'Baris "${refreshedCard.columns[0]}" berhasil diperbarui dari ${sourceDeck.name}',
    };
  }

  DeckConfig getDeckConfig(String deckId) {
    return _deckConfigs[deckId] ?? DeckConfig(deckId: deckId);
  }

  Future<DeckConfig> loadDeckConfig(String deckId) async {
    if (_deckConfigs.containsKey(deckId)) {
      return _deckConfigs[deckId]!;
    }
    final config = await _storageService.getDeckConfig(deckId);
    _deckConfigs[deckId] = config;
    return config;
  }

  Future<void> updateDeckConfig(DeckConfig config) async {
    _deckConfigs[config.deckId] = config;
    await _storageService.saveDeckConfig(config);

    // Sync deck's learning range if this is selected deck
    if (_selectedDeck?.id == config.deckId) {
      final updatedDeck = _selectedDeck!.copyWith(
        lastLearningRangeStart: config.rangeStart,
        lastLearningRangeEnd: config.rangeEnd,
      );
      _selectedDeck = updatedDeck;
      final deckIdx = _decks.indexWhere((d) => d.id == config.deckId);
      if (deckIdx != -1) {
        _decks[deckIdx] = updatedDeck;
        await _storageService.saveDecks(_decks);
      }
    }

    notifyListeners();
  }

  /// Processes cards following the strict pipeline:
  /// Raw Data -> Filter (Type, CEFR, Score) -> Sort -> Range -> Order Mode
  List<FlashcardCard> getProcessedCards(Deck deck, DeckConfig config, {bool applyOrderMode = true}) {
    List<FlashcardCard> result = List.from(deck.cards);

    final Map<String, int> cardOriginalNumbers = {};
    for (int i = 0; i < deck.cards.length; i++) {
      cardOriginalNumbers[deck.cards[i].id] = i + 1;
    }

    final typeColIdx = deck.columnHeaders.indexWhere((h) {
      final l = h.trim().toLowerCase();
      return l == 'type' || l == 'tipe';
    });
    final cefrColIdx = deck.columnHeaders.indexWhere((h) {
      final l = h.trim().toLowerCase();
      return l == 'cerf' || l == 'cefr' || l == 'level';
    });

    // 1. FILTER
    // Type Filter
    if (typeColIdx != -1 && config.selectedFilterTypes.isNotEmpty) {
      // Find all unique types in deck
      final allUniqueTypes = <String>{};
      for (final card in deck.cards) {
        if (typeColIdx < card.columns.length) {
          final raw = card.columns[typeColIdx].trim();
          if (raw.isNotEmpty && raw != '-') {
            final tokens = raw.split(RegExp(r'[,/]')).map((e) {
              return e.replaceAll(RegExp(r'\(.*?\)'), '').trim().toUpperCase();
            }).where((e) => e.isNotEmpty);
            allUniqueTypes.addAll(tokens);
          }
        }
      }

      if (config.selectedFilterTypes.length < allUniqueTypes.length) {
        result = result.where((card) {
          if (typeColIdx >= card.columns.length) return false;
          final raw = card.columns[typeColIdx].trim();
          if (raw.isEmpty || raw == '-') return false;
          final tokens = raw.split(RegExp(r'[,/]')).map((e) {
            return e.replaceAll(RegExp(r'\(.*?\)'), '').trim().toUpperCase();
          }).where((e) => e.isNotEmpty).toList();
          return tokens.any((t) => config.selectedFilterTypes.contains(t));
        }).toList();
      }
    }

    // CEFR Filter (Multi-select: A1..C2, EMPTY)
    if (cefrColIdx != -1 && config.selectedFilterCefr.isNotEmpty && config.selectedFilterCefr.length < 7) {
      result = result.where((card) {
        if (cefrColIdx < card.columns.length) {
          final raw = card.columns[cefrColIdx].trim().toUpperCase();
          if (raw.isEmpty) {
            return config.selectedFilterCefr.contains('EMPTY');
          }
          return config.selectedFilterCefr.contains(raw);
        }
        return config.selectedFilterCefr.contains('EMPTY');
      }).toList();
    }

    // Score Filter (Negative, Zero, Positive)
    if (config.selectedFilterScore.isNotEmpty && config.selectedFilterScore.length < 3) {
      result = result.where((card) {
        if (card.score < 0) return config.selectedFilterScore.contains('<0');
        if (card.score == 0) return config.selectedFilterScore.contains('0');
        return config.selectedFilterScore.contains('>0');
      }).toList();
    }

    // 2. SORT
    if (config.sortColumnIndex != null) {
      final colIdx = config.sortColumnIndex!;
      final asc = config.sortAscending;

      int secondaryComparison(FlashcardCard a, FlashcardCard b) {
        final noA = cardOriginalNumbers[a.id] ?? 0;
        final noB = cardOriginalNumbers[b.id] ?? 0;
        return asc ? noA.compareTo(noB) : noB.compareTo(noA);
      }

      if (colIdx == 0) {
        // Sort by original row position
        result.sort((a, b) {
          final noA = cardOriginalNumbers[a.id] ?? 0;
          final noB = cardOriginalNumbers[b.id] ?? 0;
          return asc ? noA.compareTo(noB) : noB.compareTo(noA);
        });
      } else if (colIdx == deck.columnHeaders.length + 1) {
        // Sort by Score (numeric)
        result.sort((a, b) {
          final comp = a.score.compareTo(b.score);
          if (comp != 0) {
            return asc ? comp : -comp;
          }
          return secondaryComparison(a, b);
        });
      } else {
        final headerIdx = colIdx - 1;
        if (headerIdx >= 0 && headerIdx < deck.columnHeaders.length) {
          final headerName = deck.columnHeaders[headerIdx].trim().toLowerCase();

          if ((headerName == 'type' || headerName == 'tipe') && config.typeSortPriority.isNotEmpty) {
            result.sort((a, b) {
              final rawA = headerIdx < a.columns.length ? a.columns[headerIdx] : '';
              final rawB = headerIdx < b.columns.length ? b.columns[headerIdx] : '';
              final tokensA = rawA
                  .split(RegExp(r'[,/]'))
                  .map((e) => e.replaceAll(RegExp(r'\(.*?\)'), '').trim().toUpperCase())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final tokensB = rawB
                  .split(RegExp(r'[,/]'))
                  .map((e) => e.replaceAll(RegExp(r'\(.*?\)'), '').trim().toUpperCase())
                  .where((e) => e.isNotEmpty)
                  .toList();

              int getPriority(List<String> tokens) {
                int minP = 999;
                for (final t in tokens) {
                  final idx = config.typeSortPriority.indexOf(t);
                  if (idx != -1 && idx < minP) minP = idx;
                }
                return minP;
              }

              final pA = getPriority(tokensA);
              final pB = getPriority(tokensB);
              final comp = pA.compareTo(pB);
              if (comp != 0) {
                return asc ? comp : -comp;
              }
              return secondaryComparison(a, b);
            });
          } else if (headerName == 'cerf' || headerName == 'cefr' || headerName == 'level') {
            const cefrList = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
            final isAsc = config.cefrSortAscending ?? asc;
            result.sort((a, b) {
              final valA = (headerIdx < a.columns.length ? a.columns[headerIdx] : '').trim().toUpperCase();
              final valB = (headerIdx < b.columns.length ? b.columns[headerIdx] : '').trim().toUpperCase();
              int rankA = cefrList.indexOf(valA);
              if (rankA == -1) rankA = 999;
              int rankB = cefrList.indexOf(valB);
              if (rankB == -1) rankB = 999;
              final comp = rankA.compareTo(rankB);
              if (comp != 0) {
                return isAsc ? comp : -comp;
              }
              return secondaryComparison(a, b);
            });
          } else {
            // General column sort
            result.sort((a, b) {
              final valA = headerIdx < a.columns.length ? a.columns[headerIdx].trim() : '';
              final valB = headerIdx < b.columns.length ? b.columns[headerIdx].trim() : '';
              final numA = num.tryParse(valA);
              final numB = num.tryParse(valB);

              if (numA != null && numB != null) {
                final comp = numA.compareTo(numB);
                if (comp != 0) {
                  return asc ? comp : -comp;
                }
              } else {
                final comp = valA.toLowerCase().compareTo(valB.toLowerCase());
                if (comp != 0) {
                  return asc ? comp : -comp;
                }
              }
              return secondaryComparison(a, b);
            });
          }
        }
      }
    }

    // 3. RANGE (Slice)
    if (config.rangeStart != null || config.rangeEnd != null) {
      if (result.isNotEmpty) {
        final start = (config.rangeStart ?? 1).clamp(1, result.length) - 1;
        final end = (config.rangeEnd ?? result.length).clamp(1, result.length);
        if (start < end) {
          result = result.sublist(start, end);
        }
      }
    }

    // 4. ORDER MODE
    if (applyOrderMode) {
      switch (config.orderMode) {
        case OrderMode.normal:
          break;
        case OrderMode.reverse:
          result = result.reversed.toList();
          break;
        case OrderMode.random:
          result.shuffle();
          break;
      }
    }

    return result;
  }

  void selectDeck(Deck deck) {
    _selectedDeck = deck;
    notifyListeners();
  }
}

class LearningSessionProvider extends ChangeNotifier {
  List<FlashcardCard> _sessionCards = [];
  int _currentIndex = 0;
  int _knownCount = 0;
  OrderMode _orderMode = OrderMode.normal;
  bool _isFlipped = false;

  int get currentIndex => _currentIndex;
  int get totalCards => _sessionCards.length;
  FlashcardCard? get currentCard =>
      _sessionCards.isNotEmpty ? _sessionCards[_currentIndex] : null;
  OrderMode get orderMode => _orderMode;
  bool get isFlipped => _isFlipped;
  List<FlashcardCard> get sessionCards => _sessionCards;

  int get knownCount => _knownCount;
  int get unknownCount => _sessionCards.length - _knownCount;
  double get progressPercent =>
      totalCards > 0 ? (_knownCount / totalCards) * 100 : 0;

  void startSession(List<FlashcardCard> cards, OrderMode mode) {
    if (cards.isEmpty) {
      _sessionCards = [];
      _currentIndex = 0;
      _knownCount = 0;
      _orderMode = mode;
      _isFlipped = false;
      notifyListeners();
      return;
    }

    var filtered = List<FlashcardCard>.from(cards);
    _knownCount = filtered.where((card) => card.known).length;

    // Apply order mode
    switch (mode) {
      case OrderMode.normal:
        // Original order (as in Excel)
        break;
      case OrderMode.reverse:
        filtered = filtered.reversed.toList();
        break;
      case OrderMode.random:
        filtered.shuffle();
        break;
    }

    _sessionCards = filtered;
    _currentIndex = 0;
    _orderMode = mode;
    _isFlipped = false;
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void unflipCard() {
    _isFlipped = false;
    notifyListeners();
  }

  void nextCard() {
    if (_currentIndex < _sessionCards.length - 1) {
      _currentIndex++;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void previousCard() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void markKnown(bool known, {Function(FlashcardCard)? onCardUpdated}) {
    if (currentCard != null) {
      final wasKnown = _sessionCards[_currentIndex].known;
      final currentScore = _sessionCards[_currentIndex].score;
      final newScore = known ? currentScore + 1 : currentScore - 1;

      _sessionCards[_currentIndex] = _sessionCards[_currentIndex].copyWith(
        known: known,
        score: newScore,
      );
      
      // Update cached knownCount
      if (known && !wasKnown) {
        _knownCount++;
      } else if (!known && wasKnown) {
        _knownCount--;
      }

      if (onCardUpdated != null) {
        onCardUpdated(_sessionCards[_currentIndex]);
      }

      notifyListeners();
    }
  }

  void resetSession() {
    _sessionCards = [];
    _currentIndex = 0;
    _knownCount = 0;
    _isFlipped = false;
    notifyListeners();
  }
}
