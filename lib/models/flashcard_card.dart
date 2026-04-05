class FlashcardCard {
  final String col1;
  final String? col2;
  final String? col3;
  final String? col4;
  final String? col5;
  final String? col6;
  final int columnCount;
  final bool known;

  FlashcardCard({
    required this.col1,
    this.col2,
    this.col3,
    this.col4,
    this.col5,
    this.col6,
    this.columnCount = 1,
    this.known = false,
  });

  FlashcardCard copyWith({
    String? col1,
    Object? col2 = _sentinel,
    Object? col3 = _sentinel,
    Object? col4 = _sentinel,
    Object? col5 = _sentinel,
    Object? col6 = _sentinel,
    int? columnCount,
    bool? known,
  }) {
    return FlashcardCard(
      col1: col1 ?? this.col1,
      col2: col2 == _sentinel ? this.col2 : col2 as String?,
      col3: col3 == _sentinel ? this.col3 : col3 as String?,
      col4: col4 == _sentinel ? this.col4 : col4 as String?,
      col5: col5 == _sentinel ? this.col5 : col5 as String?,
      col6: col6 == _sentinel ? this.col6 : col6 as String?,
      columnCount: columnCount ?? this.columnCount,
      known: known ?? this.known,
    );
  }

  static const Object _sentinel = Object();

  Map<String, dynamic> toJson() {
    return {
      'col1': col1,
      'col2': col2,
      'col3': col3,
      'col4': col4,
      'col5': col5,
      'col6': col6,
      'columnCount': columnCount,
      'known': known,
    };
  }

  factory FlashcardCard.fromJson(Map<String, dynamic> json) {
    return FlashcardCard(
      col1: json['col1'] as String,
      col2: json['col2'] as String?,
      col3: json['col3'] as String?,
      col4: json['col4'] as String?,
      col5: json['col5'] as String?,
      col6: json['col6'] as String?,
      columnCount: json['columnCount'] as int? ?? 1,
      known: json['known'] as bool? ?? false,
    );
  }

  List<String> get allColumns {
    final cols = <String>[col1];
    if (columnCount >= 2 && col2 != null) cols.add(col2!);
    if (columnCount >= 3 && col3 != null) cols.add(col3!);
    if (columnCount >= 4 && col4 != null) cols.add(col4!);
    if (columnCount >= 5 && col5 != null) cols.add(col5!);
    if (columnCount >= 6 && col6 != null) cols.add(col6!);
    return cols;
  }

  List<String> get extraColumns {
    return allColumns.sublist(1);
  }

  /// Reorder columns in the card data.
  /// [oldIndex] is the current position of the column (0-based).
  /// [newIndex] is the target position (0-based).
  /// [totalColumns] is the total number of columns in this card.
  FlashcardCard reorderColumn(int oldIndex, int newIndex, int totalColumns) {
    if (oldIndex == newIndex || oldIndex >= totalColumns || newIndex >= totalColumns) {
      return this;
    }

    // Get all columns including nulls to preserve positions
    final columns = <String?>[col1, col2, col3, col4, col5, col6]
        .take(totalColumns)
        .toList();

    // Reorder the columns
    final movedColumn = columns.removeAt(oldIndex);
    columns.insert(newIndex, movedColumn);

    // Rebuild the card with reordered columns
    return copyWith(
      col1: columns[0] ?? col1,
      col2: columns.length > 1 ? columns[1] : null,
      col3: columns.length > 2 ? columns[2] : null,
      col4: columns.length > 3 ? columns[3] : null,
      col5: columns.length > 4 ? columns[4] : null,
      col6: columns.length > 5 ? columns[5] : null,
    );
  }
}
