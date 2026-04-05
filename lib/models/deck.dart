import 'package:uuid/uuid.dart';
import 'flashcard_card.dart';

class Deck {
  final String id;
  final String name;
  final int columnCount;
  final List<String> columnHeaders;
  final List<FlashcardCard> cards;

  Deck({
    String? id,
    required this.name,
    this.columnCount = 2,
    this.columnHeaders = const ['no', 'kata'],
    required this.cards,
  }) : id = id ?? const Uuid().v4();

  Deck copyWith({
    String? id,
    String? name,
    int? columnCount,
    List<String>? columnHeaders,
    List<FlashcardCard>? cards,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      columnCount: columnCount ?? this.columnCount,
      columnHeaders: columnHeaders ?? this.columnHeaders,
      cards: cards ?? List.from(this.cards),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'columnCount': columnCount,
      'columnHeaders': columnHeaders,
      'cards': cards.map((card) => card.toJson()).toList(),
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
      cards: (json['cards'] as List<dynamic>)
          .map((cardJson) => FlashcardCard.fromJson(cardJson))
          .toList(),
    );
  }

  int get totalCards => cards.length;
}
