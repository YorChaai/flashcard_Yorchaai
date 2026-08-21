import 'package:uuid/uuid.dart';

class FlashcardCard {
  final String id;
  final List<String> columns;
  final bool known;
  final int score;

  FlashcardCard({
    String? id,
    required this.columns,
    this.known = false,
    this.score = 0,
  }) : id = id ?? const Uuid().v4();

  FlashcardCard copyWith({
    String? id,
    List<String>? columns,
    bool? known,
    int? score,
  }) {
    return FlashcardCard(
      id: id ?? this.id,
      columns: columns ?? List.from(this.columns),
      known: known ?? this.known,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'columns': columns,
      'known': known,
      'score': score,
      // Include columnCount for backward compatibility with old code if needed
      'columnCount': columns.length,
    };
  }

  factory FlashcardCard.fromJson(Map<String, dynamic> json) {
    List<String> parsedColumns = [];

    if (json.containsKey('columns')) {
      parsedColumns = List<String>.from(json['columns']);
    } else {
      // Backward compatibility for old col1..col6 structure
      if (json.containsKey('col1') && json['col1'] != null) parsedColumns.add(json['col1'] as String);
      if (json.containsKey('col2') && json['col2'] != null) parsedColumns.add(json['col2'] as String);
      if (json.containsKey('col3') && json['col3'] != null) parsedColumns.add(json['col3'] as String);
      if (json.containsKey('col4') && json['col4'] != null) parsedColumns.add(json['col4'] as String);
      if (json.containsKey('col5') && json['col5'] != null) parsedColumns.add(json['col5'] as String);
      if (json.containsKey('col6') && json['col6'] != null) parsedColumns.add(json['col6'] as String);
      
      // Ensure at least one column exists if it somehow failed
      if (parsedColumns.isEmpty) parsedColumns.add('');
    }

    return FlashcardCard(
      id: json['id'] as String? ?? const Uuid().v4(),
      columns: parsedColumns,
      known: json['known'] as bool? ?? false,
      score: json['score'] as int? ?? 0,
    );
  }

  int get columnCount => columns.length;

  List<String> get allColumns => List.unmodifiable(columns);

  List<String> get extraColumns {
    if (columns.length <= 1) return [];
    return columns.sublist(1);
  }

  FlashcardCard reorderColumn(int oldIndex, int newIndex, int totalColumns) {
    if (oldIndex == newIndex || oldIndex >= columns.length || newIndex >= columns.length) {
      return this;
    }

    final newColumns = List<String>.from(columns);
    final movedColumn = newColumns.removeAt(oldIndex);
    newColumns.insert(newIndex, movedColumn);

    return copyWith(columns: newColumns);
  }
}
