import '../models/deck.dart';
import '../models/flashcard_card.dart';

class DeckColumnHelper {
  static const List<String> standardCustomHeaders = [
    'Kata',
    'Arti',
    'Source File',
    'IPA',
    'Type',
    'CEFR',
    'Top',
  ];

  static const List<String> kataAliases = [
    'kata',
    'word',
    'term',
    'vocab',
    'vocabulary',
  ];

  static const List<String> artiAliases = [
    'arti',
    'meaning',
    'translation',
    'terjemahan',
    'definisi',
    'definition',
  ];

  static const List<String> ipaAliases = [
    'ipa',
    'phonetic',
    'pronunciation',
    'pelafalan',
    'lafal',
  ];

  static const List<String> typeAliases = [
    'type',
    'tipe',
    'pos',
    'part of speech',
    'kelas kata',
    'jenis kata',
    'category',
  ];

  static const List<String> cefrAliases = [
    'cerf',
    'cefr',
    'level',
  ];

  static const List<String> topAliases = [
    'top',
    'rank',
    'ranking',
    'frequency',
    'freq',
  ];

  /// Mengambil nilai kolom dari sebuah kartu berdasarkan kemungkinan alias nama headernya
  static String getValueByHeaderAliases(
    FlashcardCard card,
    List<String> headers,
    List<String> aliases,
  ) {
    for (final alias in aliases) {
      for (int i = 0; i < headers.length; i++) {
        if (headers[i].trim().toLowerCase() == alias.toLowerCase()) {
          if (i < card.columns.length) {
            final val = card.columns[i].trim();
            if (val.isNotEmpty) return val;
          }
        }
      }
    }
    return '';
  }

  /// Membangun kolom terstandarisasi untuk Custom Deck
  static List<String> buildStandardCustomColumns({
    required String kata,
    required String arti,
    required String sourceName,
    FlashcardCard? sourceCard,
    List<String>? sourceHeaders,
  }) {
    String resolvedArti = arti.trim();
    String ipa = '';
    String type = '';
    String cefr = '';
    String top = '';

    if (sourceCard != null && sourceHeaders != null) {
      if (resolvedArti.isEmpty) {
        resolvedArti = getValueByHeaderAliases(
          sourceCard,
          sourceHeaders,
          artiAliases,
        );
      }
      ipa = getValueByHeaderAliases(sourceCard, sourceHeaders, ipaAliases);
      type = getValueByHeaderAliases(sourceCard, sourceHeaders, typeAliases);
      cefr = getValueByHeaderAliases(sourceCard, sourceHeaders, cefrAliases);
      top = getValueByHeaderAliases(sourceCard, sourceHeaders, topAliases);
    }

    return [
      kata.trim(),
      resolvedArti,
      sourceName.trim(),
      ipa,
      type,
      cefr,
      top,
    ];
  }

  /// Menyelaraskan kartu-kartu yang sudah ada di Custom Deck agar header dan kolomnya rapi
  static Deck sanitizeAndAlignCustomDeck(
    Deck customDeck,
    List<Deck> otherDecks,
  ) {
    List<FlashcardCard> newCards = [];

    for (final card in customDeck.cards) {
      final kata = card.columns.isNotEmpty ? card.columns[0].trim() : '';
      if (kata.isEmpty) {
        newCards.add(card);
        continue;
      }

      // Deteksi apakah ada source card di deck lain
      Deck? matchingDeck;
      FlashcardCard? matchingCard;

      for (final deck in otherDecks) {
        if (deck.id == customDeck.id) continue;
        for (final c in deck.cards) {
          // Cari kata di kolom pertama
          if (c.columns.isNotEmpty &&
              c.columns[0].trim().toLowerCase() == kata.toLowerCase()) {
            matchingDeck = deck;
            matchingCard = c;
            break;
          }
        }
        if (matchingCard != null) break;
      }

      // Cek apakah ada arti manual yang pernah diisi user
      String userArti = '';
      if (card.columns.length > 1) {
        final rawCol1 = card.columns[1].trim();
        // Pastikan bukan lafal IPA yang salah tempat
        if (!rawCol1.startsWith('/') && !rawCol1.endsWith('/')) {
          userArti = rawCol1;
        }
      }

      final standardCols = buildStandardCustomColumns(
        kata: kata,
        arti: userArti,
        sourceName: matchingDeck?.name ?? (card.columns.length > 2 && card.columns[2].isNotEmpty ? card.columns[2] : 'Manual/Custom'),
        sourceCard: matchingCard,
        sourceHeaders: matchingDeck?.columnHeaders,
      );

      newCards.add(card.copyWith(columns: standardCols));
    }

    // Lakukan hal yang sama untuk deletedCards jika ada
    List<FlashcardCard> newDeletedCards = [];
    for (final card in customDeck.deletedCards) {
      final kata = card.columns.isNotEmpty ? card.columns[0].trim() : '';
      if (kata.isEmpty) {
        newDeletedCards.add(card);
        continue;
      }

      Deck? matchingDeck;
      FlashcardCard? matchingCard;

      for (final deck in otherDecks) {
        if (deck.id == customDeck.id) continue;
        for (final c in deck.cards) {
          if (c.columns.isNotEmpty &&
              c.columns[0].trim().toLowerCase() == kata.toLowerCase()) {
            matchingDeck = deck;
            matchingCard = c;
            break;
          }
        }
        if (matchingCard != null) break;
      }

      final standardCols = buildStandardCustomColumns(
        kata: kata,
        arti: card.columns.length > 1 ? card.columns[1] : '',
        sourceName: matchingDeck?.name ?? 'Manual/Custom',
        sourceCard: matchingCard,
        sourceHeaders: matchingDeck?.columnHeaders,
      );

      newDeletedCards.add(card.copyWith(columns: standardCols));
    }

    return customDeck.copyWith(
      columnCount: standardCustomHeaders.length,
      visibleColumnCount: standardCustomHeaders.length,
      columnHeaders: standardCustomHeaders,
      cards: newCards,
      deletedCards: newDeletedCards,
    );
  }
}
