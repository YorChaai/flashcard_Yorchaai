import '../models/order_mode.dart';

class DeckConfig {
  final String deckId;
  final int? sortColumnIndex;
  final bool sortAscending;
  final List<String> typeSortPriority;
  final bool? cefrSortAscending;
  final bool? scoreSortAscending;
  final Set<String> selectedFilterTypes;
  final Set<String> selectedFilterCefr;
  final Set<String> selectedFilterScore;
  final int? rangeStart;
  final int? rangeEnd;
  final OrderMode orderMode;

  DeckConfig({
    required this.deckId,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.typeSortPriority = const [],
    this.cefrSortAscending,
    this.scoreSortAscending,
    this.selectedFilterTypes = const {},
    this.selectedFilterCefr = const {},
    this.selectedFilterScore = const {},
    this.rangeStart,
    this.rangeEnd,
    this.orderMode = OrderMode.normal,
  });

  DeckConfig copyWith({
    String? deckId,
    int? sortColumnIndex,
    bool? sortAscending,
    List<String>? typeSortPriority,
    bool? cefrSortAscending,
    bool? scoreSortAscending,
    Set<String>? selectedFilterTypes,
    Set<String>? selectedFilterCefr,
    Set<String>? selectedFilterScore,
    int? rangeStart,
    int? rangeEnd,
    OrderMode? orderMode,
    bool clearSortColumn = false,
    bool clearCefrSort = false,
    bool clearScoreSort = false,
    bool clearRange = false,
  }) {
    return DeckConfig(
      deckId: deckId ?? this.deckId,
      sortColumnIndex: clearSortColumn ? null : (sortColumnIndex ?? this.sortColumnIndex),
      sortAscending: sortAscending ?? this.sortAscending,
      typeSortPriority: typeSortPriority ?? List.from(this.typeSortPriority),
      cefrSortAscending: clearCefrSort ? null : (cefrSortAscending ?? this.cefrSortAscending),
      scoreSortAscending: clearScoreSort ? null : (scoreSortAscending ?? this.scoreSortAscending),
      selectedFilterTypes: selectedFilterTypes != null ? Set.from(selectedFilterTypes) : Set.from(this.selectedFilterTypes),
      selectedFilterCefr: selectedFilterCefr != null ? Set.from(selectedFilterCefr) : Set.from(this.selectedFilterCefr),
      selectedFilterScore: selectedFilterScore != null ? Set.from(selectedFilterScore) : Set.from(this.selectedFilterScore),
      rangeStart: clearRange ? null : (rangeStart ?? this.rangeStart),
      rangeEnd: clearRange ? null : (rangeEnd ?? this.rangeEnd),
      orderMode: orderMode ?? this.orderMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deckId': deckId,
      'sortColumnIndex': sortColumnIndex,
      'sortAscending': sortAscending,
      'typeSortPriority': typeSortPriority,
      'cefrSortAscending': cefrSortAscending,
      'scoreSortAscending': scoreSortAscending,
      'selectedFilterTypes': selectedFilterTypes.toList(),
      'selectedFilterCefr': selectedFilterCefr.toList(),
      'selectedFilterScore': selectedFilterScore.toList(),
      'rangeStart': rangeStart,
      'rangeEnd': rangeEnd,
      'orderMode': orderMode.name,
    };
  }

  factory DeckConfig.fromJson(Map<String, dynamic> json) {
    OrderMode parsedMode = OrderMode.normal;
    final modeName = json['orderMode'] as String?;
    if (modeName != null) {
      parsedMode = OrderMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => OrderMode.normal,
      );
    }

    return DeckConfig(
      deckId: json['deckId'] as String? ?? '',
      sortColumnIndex: json['sortColumnIndex'] as int?,
      sortAscending: json['sortAscending'] as bool? ?? true,
      typeSortPriority: (json['typeSortPriority'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cefrSortAscending: json['cefrSortAscending'] as bool?,
      scoreSortAscending: json['scoreSortAscending'] as bool?,
      selectedFilterTypes: (json['selectedFilterTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      selectedFilterCefr: (json['selectedFilterCefr'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      selectedFilterScore: (json['selectedFilterScore'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      rangeStart: json['rangeStart'] as int?,
      rangeEnd: json['rangeEnd'] as int?,
      orderMode: parsedMode,
    );
  }
}
