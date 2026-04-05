import 'package:uuid/uuid.dart';
import 'flashcard_card.dart';

class Deck {
  final String id;
  final String name;
  final int columnCount;
  final List<String> columnHeaders;
  final List<FlashcardCard> cards;
  final double mainFontSize;
  final double subFontSize;

  Deck({
    String? id,
    required this.name,
    this.columnCount = 2,
    this.columnHeaders = const ['no', 'kata'],
    required this.cards,
    this.mainFontSize = 40.0,
    this.subFontSize = 8.0,
  }) : id = id ?? const Uuid().v4();

  Deck copyWith({
    String? id,
    String? name,
    int? columnCount,
    List<String>? columnHeaders,
    List<FlashcardCard>? cards,
    double? mainFontSize,
    double? subFontSize,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      columnCount: columnCount ?? this.columnCount,
      columnHeaders: columnHeaders != null ? List.from(columnHeaders) : List.from(this.columnHeaders),
      cards: cards != null ? List.from(cards) : List.from(this.cards),
      mainFontSize: mainFontSize ?? this.mainFontSize,
      subFontSize: subFontSize ?? this.subFontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'columnCount': columnCount,
      'columnHeaders': columnHeaders,
      'cards': cards.map((card) => card.toJson()).toList(),
      'mainFontSize': mainFontSize,
      'subFontSize': subFontSize,
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as String,
      name: json['name'] as String,
      columnCount: json['columnCount'] as int? ?? 2,
      columnHeaders: json['columnHeaders'] != null
          ? List<String>.from(json['columnHeaders'])
          : ['no', 'kata'],
      cards: (json['cards'] as List<dynamic>?)
              ?.map((cardJson) => FlashcardCard.fromJson(cardJson as Map<String, dynamic>))
              .toList() ??
          [],
      mainFontSize: (json['mainFontSize'] as num?)?.toDouble() ?? 40.0,
      subFontSize: (json['subFontSize'] as num?)?.toDouble() ?? 8.0,
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
}
