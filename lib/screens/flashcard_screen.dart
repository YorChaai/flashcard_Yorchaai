import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../models/flashcard_card.dart' as flashcard_models;
import '../services/prompt_service.dart';
import '../utils/app_strings.dart';
import 'result_screen.dart';

// Shadow and divider constants
const _shadowColorLight = Color(0x1A000000);
const _dividerOpacity = 0.5;

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  bool _isShowingBack = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyPrompt(BuildContext context, LearningSessionProvider sessionProvider) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final deck = context.read<DeckProvider>().selectedDeck;
    final currentCard = sessionProvider.currentCard;

    if (currentCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.noWordForPrompt(lang)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final prompt = PromptService.generatePrompt(
      cards: [currentCard],
      deck: deck,
    );

    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.promptCopied(lang)),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final sessionProvider = context.watch<LearningSessionProvider>();
    final currentCard = sessionProvider.currentCard;

    if (currentCard == null) {
      return Scaffold(
        body: Center(child: Text(AppStrings.noCardsAvailable(lang))),
      );
    }

    final isLastCard =
        sessionProvider.currentIndex >= sessionProvider.totalCards - 1;

    return Scaffold(
      appBar: AppBar(
        title:
            Text('${sessionProvider.currentIndex + 1} / ${sessionProvider.totalCards}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: AppStrings.copyPrompt(lang),
            onPressed: () => _copyPrompt(context, sessionProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: sessionProvider.progressPercent / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),

          // Flashcard with responsive height
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: GestureDetector(
                onTap: () {
                  if (_isShowingBack) {
                    _animationController.reverse();
                  } else {
                    _animationController.forward();
                  }
                  setState(() {
                    _isShowingBack = !_isShowingBack;
                  });
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight,
                        maxWidth: constraints.maxWidth,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _shadowColorLight,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final value = _flipAnimation.value;
                          final showBack = value >= 0.5;
                          final rotation = value * pi;
                          final transform = Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(rotation);

                          return Transform(
                            alignment: Alignment.center,
                            transform: transform,
                            child: showBack
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.rotationY(pi),
                                    child: _buildCardBack(currentCard),
                                  )
                                : _buildCardFront(currentCard),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Knowledge Buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Tidak Tahu: reset display → 1 kolom, record, maju ke NEXT
                      _animationController.reset();
                      setState(() => _isShowingBack = false);
                      if (isLastCard) {
                        sessionProvider.markKnown(false, onCardUpdated: (c) {
                          final dp = context.read<DeckProvider>();
                          if (dp.selectedDeck != null) dp.updateCardInDeck(dp.selectedDeck!.id, c);
                        });
                        _goToResultScreen();
                      } else {
                        sessionProvider.markKnownAndNext(false, onCardUpdated: (c) {
                          final dp = context.read<DeckProvider>();
                          if (dp.selectedDeck != null) dp.updateCardInDeck(dp.selectedDeck!.id, c);
                        });
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: Text(AppStrings.dontKnow(lang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Tahu: reset display → 1 kolom, record, maju ke NEXT
                      _animationController.reset();
                      setState(() => _isShowingBack = false);
                      if (isLastCard) {
                        sessionProvider.markKnown(true, onCardUpdated: (c) {
                          final dp = context.read<DeckProvider>();
                          if (dp.selectedDeck != null) dp.updateCardInDeck(dp.selectedDeck!.id, c);
                        });
                        _goToResultScreen();
                      } else {
                        sessionProvider.markKnownAndNext(true, onCardUpdated: (c) {
                          final dp = context.read<DeckProvider>();
                          if (dp.selectedDeck != null) dp.updateCardInDeck(dp.selectedDeck!.id, c);
                        });
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: Text(AppStrings.know(lang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation Buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: sessionProvider.currentIndex > 0
                        ? () {
                            // Previous: KEEP current display mode as-is
                            sessionProvider.previousCard();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(AppStrings.previous(lang)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (isLastCard) {
                        // Finish on last card: go to result (no skip increment; handled per-card)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResultScreen(),
                            settings: const RouteSettings(name: 'ResultScreen'),
                          ),
                        );
                      } else {
                        // Next: KEEP current display mode as-is
                        sessionProvider.nextCard();
                      }
                    },
                    icon: Icon(
                      isLastCard ? Icons.done_all : Icons.arrow_forward,
                    ),
                    label: Text(
                      isLastCard ? AppStrings.finish(lang) : AppStrings.next(lang),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _goToResultScreen() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ResultScreen(),
        settings: const RouteSettings(name: 'ResultScreen'),
      ),
    );
  }

  Widget _buildCardFront(flashcard_models.FlashcardCard card) {
    // Read font sizes from global settings only (Settings = source of truth)
    final fontSizeSettings = context.watch<ThemeProvider>().fontSizeSettings;
    final mainFontSize = fontSizeSettings.currentFontSize1;
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return Stack(
      children: [
        Center(
          child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.columns.isNotEmpty ? card.columns[0] : '',
              style: TextStyle(
                fontSize: mainFontSize * 1.2, // Front is slightly larger
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.tapToReveal(lang),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _buildScoreAndPracticeAction(card),
        ),
      ],
    );
  }

  Widget _buildScoreAndPracticeAction(flashcard_models.FlashcardCard card) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: AppStrings.writingPractice(lang),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showWritingPracticeDialog(context, card),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: Colors.amber.shade800,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildScoreBadge(card.score, lang),
      ],
    );
  }

  void _showWritingPracticeDialog(
    BuildContext context,
    flashcard_models.FlashcardCard card,
  ) {
    final expectedWord = card.columns.isNotEmpty ? card.columns[0] : '';

    showDialog(
      context: context,
      builder: (context) => _WritingPracticeDialog(expectedWord: expectedWord),
    );
  }

  Widget _buildScoreBadge(int score, String lang) {
    final color = score > 0
        ? Colors.green
        : (score < 0 ? Colors.red : Colors.grey);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        AppStrings.scoreLabel(lang, score),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardBack(flashcard_models.FlashcardCard card) {
    final deck = context.read<DeckProvider>().selectedDeck;
    int visibleColumnCount = deck?.visibleColumnCount ?? card.columnCount;
    if (visibleColumnCount > card.columnCount) visibleColumnCount = card.columnCount;
    if (visibleColumnCount < 1) visibleColumnCount = 1;

    final allExtraCols = card.extraColumns;
    final int maxExtra = visibleColumnCount - 1;
    List<String> extraCols = allExtraCols.length > maxExtra ? allExtraCols.sublist(0, maxExtra).toList() : allExtraCols.toList();
    
    // Remove trailing empty columns so they don't break the layout pairing
    while (extraCols.isNotEmpty && extraCols.last.trim().isEmpty) {
      extraCols.removeLast();
    }
    
    final columnCount = visibleColumnCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: _dividerOpacity)
        : Colors.black.withValues(alpha: _dividerOpacity);

    // Read font sizes from global settings only (Settings = source of truth)
    final fontSizeSettings = context.watch<ThemeProvider>().fontSizeSettings;
    final fontSize1 = fontSizeSettings.currentFontSize1;
    final fontSize2_5 = fontSizeSettings.currentFontSize2_5;
    final fontSize6_9 = fontSizeSettings.currentFontSize6_9;
    final fontSize10_12 = fontSizeSettings.currentFontSize10_12;

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Kolom 1 - MAIN WORD (dynamic font size)
                  Text(
                    card.columns.isNotEmpty ? card.columns[0] : '',
                    style: TextStyle(
                      fontSize: fontSize1,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Extra columns (Kolom 2-12) dengan divider
                  if (extraCols.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: dividerColor,
                    ),
                    const SizedBox(height: 12),

                    // Layout berdasarkan jumlah extra columns (hingga 12 kolom)
                    _buildExtraColumnsLayout(
                      extraCols,
                      columnCount,
                      fontSize2_5,
                      fontSize6_9,
                      fontSize10_12,
                      dividerColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _buildScoreAndPracticeAction(card),
        ),
      ],
    );
  }

  Widget _buildExtraColumnsLayout(
    List<String> extraCols,
    int columnCount,
    double fontSize2_5,
    double fontSize6_9,
    double fontSize10_12,
    Color dividerColor,
  ) {
    if (extraCols.isEmpty) return const SizedBox.shrink();

    List<Widget> rows = [];
    for (int i = 0; i < extraCols.length; i += 2) {
      // Tentukan ukuran font berdasarkan baris (4 mode: 1, 2-5, 6-9, 10-12)
      double currentFontSize;
      if (i <= 2) {
        // Kolom 2-3 (i=0) & Kolom 4-5 (i=2)
        currentFontSize = fontSize2_5;
      } else if (i <= 6) {
        // Kolom 6-7 (i=4) & Kolom 8-9 (i=6)
        currentFontSize = fontSize6_9;
      } else {
        // Kolom 10-11 (i=8) & Kolom 12 (i=10)
        currentFontSize = fontSize10_12;
      }

      // Tambahkan divider jika ini bukan baris pertama
      if (i > 0) {
        rows.add(const SizedBox(height: 8));
        rows.add(Container(
          height: 1,
          color: dividerColor,
        ));
        rows.add(const SizedBox(height: 8));
      }

      // Render sepasang kolom (atau 1 kolom jika ganjil di akhir)
      if (i + 1 < extraCols.length) {
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Text(
                extraCols[i],
                style: TextStyle(
                  fontSize: currentFontSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                extraCols[i + 1],
                style: TextStyle(
                  fontSize: currentFontSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ));
      } else {
        rows.add(
          SizedBox(
            width: double.infinity,
            child: Text(
              extraCols[i],
              style: TextStyle(
                fontSize: currentFontSize,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    return Column(children: rows);
  }
}

class _WritingPracticeDialog extends StatefulWidget {
  final String expectedWord;

  const _WritingPracticeDialog({required this.expectedWord});

  @override
  State<_WritingPracticeDialog> createState() => _WritingPracticeDialogState();
}

class _WritingPracticeDialogState extends State<_WritingPracticeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool? _isCorrect;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final input = _controller.text.trim();
    final expected = widget.expectedWord.trim();

    setState(() {
      _isCorrect = input == expected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Judul & Tombol Close (X)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppStrings.writingPractice(lang),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    tooltip: AppStrings.close(lang),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Target Word display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      AppStrings.wordToWritePrompt(lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.expectedWord,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input field (Unicode compliant, auto-focus)
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppStrings.typeWordHere(lang),
                  hintText: AppStrings.writeAnswerHere(lang),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _checkAnswer(),
                onChanged: (_) {
                  if (_isCorrect != null) {
                    setState(() => _isCorrect = null);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Feedback status
              if (_isCorrect != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isCorrect!
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isCorrect! ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCorrect! ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect! ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isCorrect! ? AppStrings.correct(lang) : AppStrings.incorrectTryAgain(lang),
                          style: TextStyle(
                            color: _isCorrect! ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(AppStrings.close(lang)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _checkAnswer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(AppStrings.checkAnswer(lang)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
