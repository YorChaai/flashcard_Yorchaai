import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../models/flashcard_card.dart' as flashcard_models;
import '../services/prompt_service.dart';
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
    final deck = context.read<DeckProvider>().selectedDeck;
    final currentCard = sessionProvider.currentCard;

    if (currentCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada kata untuk dibuatkan prompt.'),
          duration: Duration(seconds: 2),
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
      const SnackBar(
        content: Text('Prompt berhasil disalin ke clipboard!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<LearningSessionProvider>();
    final currentCard = sessionProvider.currentCard;

    if (currentCard == null) {
      return const Scaffold(
        body: Center(child: Text('No cards available')),
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
            tooltip: 'Copy Prompt',
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
                    label: const Text('Tidak Tahu'),
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
                    label: const Text('Tahu'),
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
                    label: const Text('Previous'),
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
                      isLastCard ? 'Finish' : 'Next',
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
            const Text(
              'Tap to reveal',
              style: TextStyle(
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Latihan Menulis',
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
        _buildScoreBadge(card.score),
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

  Widget _buildScoreBadge(int score) {
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
        'Skor: $score',
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
    final fontSize23 = fontSizeSettings.currentFontSize23;
    final fontSize45 = fontSizeSettings.currentFontSize45;
    final fontSize6 = fontSizeSettings.currentFontSize6;

    return Stack(
      children: [
        Center(
          child: Padding(
        padding: const EdgeInsets.all(24.0),
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

            // Extra columns (Kolom 2-6) dengan divider
            if (extraCols.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: dividerColor,
              ),
              const SizedBox(height: 12),

              // Layout berdasarkan jumlah extra columns
              _buildExtraColumnsLayout(extraCols, columnCount, fontSize23, fontSize45, fontSize6),
            ],
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

  Widget _buildExtraColumnsLayout(List<String> extraCols, int columnCount, double fontSize23, double fontSize45, double fontSize6) {
    if (extraCols.isEmpty) return const SizedBox.shrink();

    List<Widget> rows = [];
    for (int i = 0; i < extraCols.length; i += 2) {
      // Tentukan ukuran font berdasarkan baris
      double currentFontSize;
      if (i == 0) {
        currentFontSize = fontSize23;
      } else if (i == 2) {
        currentFontSize = fontSize45;
      } else {
        currentFontSize = fontSize6;
      }

      // Tambahkan divider jika ini bukan baris pertama
      if (i > 0) {
        rows.add(const SizedBox(height: 8));
        rows.add(Container(
          height: 1,
          color: Colors.black.withValues(alpha: 0.5),
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
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Latihan Menulis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Tutup',
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
                      'Kata yang harus ditulis:',
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
                  labelText: 'Ketik kata di sini...',
                  hintText: 'Tuliskan jawaban...',
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
                          _isCorrect! ? 'Benar' : 'Salah, coba lagi',
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
                      child: const Text('Tutup'),
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
                      child: const Text('Cek Jawaban'),
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
