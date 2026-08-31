import '../models/deck.dart';
import '../models/flashcard_card.dart';

class WordTypeInfo {
  final String key;
  final String singular;
  final String plural;
  final String translation;
  final int priority;

  const WordTypeInfo({
    required this.key,
    required this.singular,
    required this.plural,
    required this.translation,
    required this.priority,
  });
}

class PromptService {
  static const Map<String, WordTypeInfo> _knownTypes = {
    'noun': WordTypeInfo(
      key: 'noun',
      singular: 'noun',
      plural: 'nouns',
      translation: 'kata benda',
      priority: 1,
    ),
    'verb': WordTypeInfo(
      key: 'verb',
      singular: 'verb',
      plural: 'verbs',
      translation: 'kata kerja',
      priority: 2,
    ),
    'adjective': WordTypeInfo(
      key: 'adjective',
      singular: 'adjective',
      plural: 'adjectives',
      translation: 'kata sifat',
      priority: 3,
    ),
    'adverb': WordTypeInfo(
      key: 'adverb',
      singular: 'adverb',
      plural: 'adverbs',
      translation: 'kata keterangan',
      priority: 4,
    ),
    'pronoun': WordTypeInfo(
      key: 'pronoun',
      singular: 'pronoun',
      plural: 'pronouns',
      translation: 'kata ganti',
      priority: 5,
    ),
    'preposition': WordTypeInfo(
      key: 'preposition',
      singular: 'preposition',
      plural: 'prepositions',
      translation: 'kata depan',
      priority: 6,
    ),
    'conjunction': WordTypeInfo(
      key: 'conjunction',
      singular: 'conjunction',
      plural: 'conjunctions',
      translation: 'kata hubung',
      priority: 7,
    ),
    'interjection': WordTypeInfo(
      key: 'interjection',
      singular: 'interjection',
      plural: 'interjections',
      translation: 'kata seru',
      priority: 8,
    ),
    'determiner': WordTypeInfo(
      key: 'determiner',
      singular: 'determiner',
      plural: 'determiners',
      translation: 'kata penentu',
      priority: 9,
    ),
    'auxiliary': WordTypeInfo(
      key: 'auxiliary',
      singular: 'auxiliary verb',
      plural: 'auxiliary verbs',
      translation: 'kata kerja bantu',
      priority: 10,
    ),
    'particle': WordTypeInfo(
      key: 'particle',
      singular: 'particle',
      plural: 'particles',
      translation: 'partikel',
      priority: 11,
    ),
    'question word': WordTypeInfo(
      key: 'question word',
      singular: 'question word',
      plural: 'question words',
      translation: 'kata tanya',
      priority: 12,
    ),
    'phrase': WordTypeInfo(
      key: 'phrase',
      singular: 'phrase',
      plural: 'phrases',
      translation: 'frasa',
      priority: 13,
    ),
    'idiom': WordTypeInfo(
      key: 'idiom',
      singular: 'idiom',
      plural: 'idioms',
      translation: 'idiom',
      priority: 14,
    ),
  };

  /// Normalizes a type token (e.g. 'nouns', 'NOUN (Tech)', 'v', 'adj', 'GRAMMAR (AUX)') to a canonical WordTypeInfo.
  static WordTypeInfo normalizeType(String rawType) {
    final lower = rawType.trim().toLowerCase();

    // Check grammar patterns e.g. "GRAMMAR (AUX)", "GRAMMAR (ADP)"
    if (lower.contains('adp')) {
      return _knownTypes['preposition']!;
    }
    if (lower.contains('aux')) {
      return _knownTypes['auxiliary']!;
    }
    if (lower.contains('cconj') || lower.contains('sconj')) {
      return _knownTypes['conjunction']!;
    }
    if (lower.contains('det')) {
      return _knownTypes['determiner']!;
    }
    if (lower.contains('part')) {
      return _knownTypes['particle']!;
    }
    if (lower.contains('pron')) {
      return _knownTypes['pronoun']!;
    }
    if (lower.contains('question word') || lower.contains('question')) {
      return _knownTypes['question word']!;
    }

    // Strip parenthetical text e.g. "NOUN (Brand/Name)" -> "noun"
    var clean = rawType.replaceAll(RegExp(r'\(.*?\)'), '').trim().toLowerCase();
    
    // Check aliases
    if (clean == 'n' || clean == 'n.' || clean == 'noun' || clean == 'nouns' || clean == 'kata benda') {
      return _knownTypes['noun']!;
    }
    if (clean == 'v' || clean == 'v.' || clean == 'verb' || clean == 'verbs' || clean == 'kata kerja') {
      return _knownTypes['verb']!;
    }
    if (clean == 'adj' || clean == 'adj.' || clean == 'adjective' || clean == 'adjectives' || clean == 'kata sifat') {
      return _knownTypes['adjective']!;
    }
    if (clean == 'adv' || clean == 'adv.' || clean == 'adverb' || clean == 'adverbs' || clean == 'kata keterangan') {
      return _knownTypes['adverb']!;
    }
    if (clean == 'pron' || clean == 'pron.' || clean == 'pronoun' || clean == 'pronouns' || clean == 'kata ganti') {
      return _knownTypes['pronoun']!;
    }
    if (clean == 'prep' || clean == 'prep.' || clean == 'preposition' || clean == 'prepositions' || clean == 'kata depan') {
      return _knownTypes['preposition']!;
    }
    if (clean == 'conj' || clean == 'conj.' || clean == 'conjunction' || clean == 'conjunctions' || clean == 'kata hubung') {
      return _knownTypes['conjunction']!;
    }
    if (clean == 'interj' || clean == 'interj.' || clean == 'interjection' || clean == 'interjections' || clean == 'kata seru') {
      return _knownTypes['interjection']!;
    }
    if (clean == 'phrase' || clean == 'phrases' || clean == 'frasa') {
      return _knownTypes['phrase']!;
    }
    if (clean == 'idiom' || clean == 'idioms') {
      return _knownTypes['idiom']!;
    }

    if (_knownTypes.containsKey(clean)) {
      return _knownTypes[clean]!;
    }

    final plural = clean.endsWith('s') ? clean : '${clean}s';
    return WordTypeInfo(
      key: clean,
      singular: clean,
      plural: plural,
      translation: clean,
      priority: 99,
    );
  }

  /// Detect the column index for type/POS in a deck.
  static int? getTypeColumnIndex(Deck? deck) {
    if (deck == null || deck.columnHeaders.isEmpty) return null;
    for (int i = 0; i < deck.columnHeaders.length; i++) {
      final h = deck.columnHeaders[i].trim().toLowerCase();
      if (h == 'type' ||
          h == 'tipe' ||
          h == 'pos' ||
          h == 'part of speech' ||
          h == 'kelas kata' ||
          h == 'jenis kata' ||
          h == 'kategori' ||
          h == 'category' ||
          h == 'class') {
        return i;
      }
    }
    return null;
  }

  /// Extract word and type from card.
  static ({String word, String type}) extractCardWordAndType(
    FlashcardCard card,
    int? typeColIndex,
  ) {
    final word = card.columns.isNotEmpty ? card.columns[0].trim() : '';

    String rawType = '';
    if (typeColIndex != null && typeColIndex < card.columns.length) {
      rawType = card.columns[typeColIndex].trim();
    } else if (card.columns.length > 2) {
      // If column 2 looks like a type, check it
      final candidate = card.columns[2].trim().toLowerCase();
      if (_knownTypes.containsKey(candidate) ||
          candidate == 'adj' ||
          candidate == 'adv' ||
          candidate == 'noun' ||
          candidate == 'verb') {
        rawType = candidate;
      }
    } else if (card.columns.length > 1) {
      final candidate = card.columns[1].trim().toLowerCase();
      if (_knownTypes.containsKey(candidate) ||
          candidate == 'adj' ||
          candidate == 'adv' ||
          candidate == 'noun' ||
          candidate == 'verb') {
        rawType = candidate;
      }
    }

    return (word: word, type: rawType);
  }

  /// Generates the dynamic AI prompt based on session cards and deck metadata.
  static String generatePrompt({
    required List<FlashcardCard> cards,
    Deck? deck,
  }) {
    if (cards.isEmpty) {
      return '';
    }

    final int? typeColIdx = getTypeColumnIndex(deck);

    // Group words by their canonical WordTypeInfo
    final Map<String, ({WordTypeInfo typeInfo, List<String> words})> groups = {};
    final List<String> untypedWords = [];

    final Set<String> uniqueWords = {};

    for (final card in cards) {
      final extracted = extractCardWordAndType(card, typeColIdx);
      if (extracted.word.isEmpty) continue;
      uniqueWords.add(extracted.word);

      if (extracted.type.isEmpty) {
        if (!untypedWords.contains(extracted.word)) {
          untypedWords.add(extracted.word);
        }
      } else {
        // Split comma-separated types and assign word to each category
        final rawTokens = extracted.type
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);

        for (final token in rawTokens) {
          final typeInfo = normalizeType(token);
          if (!groups.containsKey(typeInfo.key)) {
            groups[typeInfo.key] = (typeInfo: typeInfo, words: []);
          }
          if (!groups[typeInfo.key]!.words.contains(extracted.word)) {
            groups[typeInfo.key]!.words.add(extracted.word);
          }
        }
      }
    }

    // Sort groups by priority, then key
    final sortedGroups = groups.values.toList()
      ..sort((a, b) {
        if (a.typeInfo.priority != b.typeInfo.priority) {
          return a.typeInfo.priority.compareTo(b.typeInfo.priority);
        }
        return a.typeInfo.key.compareTo(b.typeInfo.key);
      });

    final int totalWords = uniqueWords.isNotEmpty
        ? uniqueWords.length
        : (sortedGroups.fold<int>(0, (sum, g) => sum + g.words.length) +
            untypedWords.length);

    final StringBuffer headerBuffer = StringBuffer();

    // 1. Build Header & Word List
    if (sortedGroups.isEmpty && untypedWords.isNotEmpty) {
      // All untyped
      headerBuffer.writeln('Di sini saya ingin belajar $totalWords kata bahasa Inggris: ${untypedWords.join(', ')}');
    } else if (sortedGroups.length == 1 && untypedWords.isEmpty) {
      // Single type
      final g = sortedGroups.first;
      final count = g.words.length;
      final typeText = count == 1 ? g.typeInfo.singular : g.typeInfo.plural;
      final translation = g.typeInfo.translation;
      final wordsList = g.words.join(', ');

      headerBuffer.writeln('Di sini saya ingin belajar $count kata bahasa Inggris.\n');
      headerBuffer.writeln('* $count $typeText ($translation): $wordsList');
    } else {
      // Multiple types (or mixed with untyped)
      headerBuffer.writeln('Di sini saya ingin belajar $totalWords kata bahasa Inggris, terbagi dalam:\n');
      for (final g in sortedGroups) {
        final count = g.words.length;
        final typeText = count == 1 ? g.typeInfo.singular : g.typeInfo.plural;
        final translation = g.typeInfo.translation;
        final wordsList = g.words.join(', ');
        headerBuffer.writeln('* $count $typeText ($translation): $wordsList');
      }
      if (untypedWords.isNotEmpty) {
        headerBuffer.writeln('* ${untypedWords.length} kata lainnya: ${untypedWords.join(', ')}');
      }
    }

    // 2. Build Dynamic Point 3 (dialog math)
    final String point3Text;
    final int totalDialogs = sortedGroups.fold<int>(
          0,
          (sum, g) => sum + g.words.length * 2,
        ) +
        (untypedWords.length * 2);

    if (sortedGroups.isEmpty) {
      point3Text = '3. berarti terdapat 1 kata 2 dialog, dan total ada $totalDialogs dialog';
    } else if (sortedGroups.length == 1 && untypedWords.isEmpty) {
      final g = sortedGroups.first;
      final count = g.words.length;
      final typeText = count == 1 ? g.typeInfo.singular : g.typeInfo.plural;
      final dialogCount = count * 2;
      point3Text = '3. berarti terdapat 1 kata 2 dialog jadi kalo ada $count $typeText berarti ada $dialogCount dialog, dan total ada $totalDialogs dialog';
    } else {
      final first = sortedGroups.first;
      final firstTypeCount = first.words.length;
      final firstTypeText = firstTypeCount == 1 ? first.typeInfo.singular : first.typeInfo.plural;
      final firstDialogCount = firstTypeCount * 2;

      final subsequentParts = <String>[];
      for (int i = 1; i < sortedGroups.length; i++) {
        final g = sortedGroups[i];
        final count = g.words.length;
        final typeText = count == 1 ? g.typeInfo.singular : g.typeInfo.plural;
        final dCount = count * 2;
        subsequentParts.add('$typeText $dCount dialog');
      }
      if (untypedWords.isNotEmpty) {
        subsequentParts.add('kata lainnya ${untypedWords.length * 2} dialog');
      }

      final subsequentStr = subsequentParts.isNotEmpty ? ', di tambah ada ${subsequentParts.join(', ')}' : '';
      point3Text = '3. berarti terdapat 1 kata 2 dialog jadi kalo ada $firstTypeCount $firstTypeText berarti ada $firstDialogCount dialog$subsequentStr, dan total ada $totalDialogs dialog';
    }

    // 3. Assemble Full Prompt
    return '''<aside>
✏️

${headerBuffer.toString().trim()}

Tugasmu:

1. Untuk **setiap kata**, buatlah **5 contoh dialog dimana dialog itu menghasilkan 2 kalimat saja(yang dimana kalimat sehari hari) dan boleh ada kata kerja v1,v2,v3,ving**.
2. utamakan noun dulu, baru verbs, baru adjective, intinya sebaris di kasih tahu
$point3Text
4. Cantumkan keterangan **kelas kata** (noun/verb/adjective) di samping setiap kata.
5. dibawahnya jika kamu sudah bikin kalimatnya tambahin internasional phonectic alfabet dari kalimat yang kamu bikin
6. tambahin bahasa translate ke indonesia di bawah IPA
7. Susun balasan dengan format:

strukturnya :
[Kata] (kelas kata) (heading1)

Dialog 1 (heading2)
A: …
B: …
(IPA)
(ARTI)

Dialog 2
A: …
B: …
(IPA)
(ARTI)

---

Contoh hasil:

("number") area (noun)

Dialog 1
A: This area of the park is always shaded.
B: It’s perfect for a picnic.
(IPA)
/ðɪs ˈɛəriə əv ðə pɑːrk ɪz ˈɔːlweɪz ˈʃeɪdɪd/
/ɪts ˈpɜːrfɪkt fɔːr ə ˈpɪknɪk/
(ARTI)
Area taman ini selalu teduh.
Cocok untuk piknik.

Dialog 2
A: Did you see the new seating area inside the library?
B: Yes, they expanded it last month.
(IPA)
/dɪd juː siː ðə njuː ˈsiːtɪŋ ˈɛəriə ɪnˈsaɪd ðə ˈlaɪbrəri/
/jɛs ðeɪ ɪkˈspændɪd ɪt læst mʌnθ/
(ARTI)
Apakah kamu melihat area tempat duduk baru di dalam perpustakaan?
Ya, mereka memperluasnya bulan lalu.

---

("number") book (noun)

Dialog 1
A: I just finished reading that book you lent me.
B: How did you like the ending?
(IPA)
/aɪ dʒəst ˈfɪnɪʃt ˈriːdɪŋ ðæt bʊk juː lɛnt miː/
/haʊ dɪd juː laɪk ði ˈɛndɪŋ/
(ARTI)
Saya baru saja selesai membaca buku yang kamu pinjamkan.
Bagaimana menurutmu akhir ceritanya?

Dialog 2
A: Can you pass me the book on the shelf?
B: Sure, here it is.
(IPA)
/kæn juː pæs miː ðə bʊk ɒn ðə ʃɛlf/
/ʃʊr hɪər ɪt ɪz/
(ARTI)
Bisakah kamu memberiku buku di rak itu?
Tentu, ini dia.

</aside>''';
  }
}
