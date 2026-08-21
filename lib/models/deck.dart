import 'package:uuid/uuid.dart';
import 'flashcard_card.dart';

class Deck {
  final String id;
  final String name;
  final int columnCount;
  final int visibleColumnCount;
  final List<String> columnHeaders;
  final List<FlashcardCard> cards;
  final int? lastLearningRangeStart;
  final int? lastLearningRangeEnd;

  Deck({
    String? id,
    required this.name,
    this.columnCount = 2,
    int? visibleColumnCount,
    this.columnHeaders = const ['no', 'kata'],
    required this.cards,
    this.lastLearningRangeStart,
    this.lastLearningRangeEnd,
  })  : visibleColumnCount = visibleColumnCount ?? columnCount,
        id = id ?? const Uuid().v4();

  Deck copyWith({
    String? id,
    String? name,
    int? columnCount,
    int? visibleColumnCount,
    List<String>? columnHeaders,
    List<FlashcardCard>? cards,
    int? lastLearningRangeStart,
    int? lastLearningRangeEnd,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      columnCount: columnCount ?? this.columnCount,
      visibleColumnCount: visibleColumnCount ?? this.visibleColumnCount,
      columnHeaders: columnHeaders != null ? List.from(columnHeaders) : List.from(this.columnHeaders),
      cards: cards != null ? List.from(cards) : List.from(this.cards),
      lastLearningRangeStart: lastLearningRangeStart ?? this.lastLearningRangeStart,
      lastLearningRangeEnd: lastLearningRangeEnd ?? this.lastLearningRangeEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'columnCount': columnCount,
      'visibleColumnCount': visibleColumnCount,
      'columnHeaders': columnHeaders,
      'cards': cards.map((card) => card.toJson()).toList(),
      'lastLearningRangeStart': lastLearningRangeStart,
      'lastLearningRangeEnd': lastLearningRangeEnd,
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    final columnCount = json['columnCount'] as int? ?? 2;
    // Clamp visibleColumnCount to valid range to prevent dropdown crash
    final rawVisible = json['visibleColumnCount'] as int?;
    final safeVisible = rawVisible == null
        ? columnCount
        : rawVisible.clamp(1, columnCount);

    return Deck(
      id: json['id'] as String,
      name: json['name'] as String,
      columnCount: columnCount,
      visibleColumnCount: safeVisible,
      columnHeaders: json['columnHeaders'] != null
          ? List<String>.from(json['columnHeaders'])
          : ['no', 'kata'],
      cards: (json['cards'] as List<dynamic>?)
              ?.map((cardJson) => FlashcardCard.fromJson(cardJson as Map<String, dynamic>))
              .toList() ??
          [],
      lastLearningRangeStart: json['lastLearningRangeStart'] as int?,
      lastLearningRangeEnd: json['lastLearningRangeEnd'] as int?,
    );
  }

  int get totalCards => cards.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deck && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Reorder column headers and reorganize all cards data accordingly.
  /// [oldIndex] is the current position of the column.
  /// [newIndex] is the target position.
  Deck reorderColumn(int oldIndex, int newIndex) {
    if (oldIndex == newIndex || oldIndex >= columnHeaders.length || newIndex >= columnHeaders.length) {
      return this;
    }

    // Reorder column headers
    final newHeaders = List<String>.from(columnHeaders);
    final movedHeader = newHeaders.removeAt(oldIndex);
    newHeaders.insert(newIndex, movedHeader);

    // Reorganize all cards
    final newCards = cards.map((card) {
      return card.reorderColumn(oldIndex, newIndex, columnCount);
    }).toList();

    return copyWith(
      columnHeaders: newHeaders,
      cards: newCards,
    );
  }

  /// Updates a specific card in the deck based on its id.
  Deck updateCard(FlashcardCard updatedCard) {
    final newCards = cards.map((card) {
      if (card.id == updatedCard.id) {
        return updatedCard;
      }
      return card;
    }).toList();

    return copyWith(cards: newCards);
  }

  /// Adds a new card to the deck.
  Deck addCard(FlashcardCard newCard) {
    final newCards = List<FlashcardCard>.from(cards)..add(newCard);
    return copyWith(cards: newCards);
  }

  /// Removes a card from the deck by its id.
  Deck removeCard(String cardId) {
    final newCards = cards.where((card) => card.id != cardId).toList();
    return copyWith(cards: newCards);
  }

  /// Upgrades the deck's column count and pads existing cards with empty strings if necessary.
  Deck upgradeColumnCount(int newCount, List<String> newHeaders) {
    if (newCount <= columnCount) return this;

    final updatedCards = cards.map((card) {
      if (card.columns.length >= newCount) return card;
      final newColumns = List<String>.from(card.columns);
      while (newColumns.length < newCount) {
        newColumns.add('');
      }
      return card.copyWith(columns: newColumns);
    }).toList();

    return copyWith(
      columnCount: newCount,
      visibleColumnCount: newCount,
      columnHeaders: newHeaders,
      cards: updatedCards,
    );
  }
}

