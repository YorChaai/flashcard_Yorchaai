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
    String? col2,
    String? col3,
    String? col4,
    String? col5,
    String? col6,
    int? columnCount,
    bool? known,
  }) {
    return FlashcardCard(
      col1: col1 ?? this.col1,
      col2: col2 ?? this.col2,
      col3: col3 ?? this.col3,
      col4: col4 ?? this.col4,
      col5: col5 ?? this.col5,
      col6: col6 ?? this.col6,
      columnCount: columnCount ?? this.columnCount,
      known: known ?? this.known,
    );
  }

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
    List<String> cols = [col1];
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
}
