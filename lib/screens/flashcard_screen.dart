import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../models/flashcard_card.dart' as flashcard_models;
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
  late double _mainFontSize;
  late double _subFontSize;

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
    // Read font sizes once at init (won't change during session)
    _loadFontSizes();
  }

  void _loadFontSizes() {
    final deck = context.read<DeckProvider>().selectedDeck;
    final fontSizeSettings = context.read<ThemeProvider>().fontSizeSettings;
    _mainFontSize = deck?.mainFontSize ?? fontSizeSettings.currentMainFontSize;
    _subFontSize = deck?.subFontSize ?? fontSizeSettings.currentSubFontSize;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title:
            Text('${sessionProvider.currentIndex + 1} / ${sessionProvider.totalCards}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResultScreen(),
                  settings: const RouteSettings(name: 'ResultScreen'),
                ),
              );
            },
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
                      sessionProvider.markKnown(false);
                      _showNextCardOrResult(sessionProvider);
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
                      sessionProvider.markKnown(true);
                      _showNextCardOrResult(sessionProvider);
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
                    onPressed:
                        sessionProvider.currentIndex <
                                sessionProvider.totalCards - 1
                            ? () {
                                sessionProvider.nextCard();
                              }
                            : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
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

  void _showNextCardOrResult(
    LearningSessionProvider sessionProvider,
  ) {
    if (sessionProvider.currentIndex < sessionProvider.totalCards - 1) {
      // Reset flip animation
      _animationController.reset();
      setState(() {
        _isShowingBack = false;
      });
      sessionProvider.nextCard();
    } else {
      // Navigate immediately without reset on last card
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ResultScreen(),
            settings: const RouteSettings(name: 'ResultScreen'),
          ),
        );
      }
    }
  }

  Widget _buildCardFront(flashcard_models.FlashcardCard card) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.col1,
              style: TextStyle(
                fontSize: _mainFontSize * 1.2, // Front is slightly larger
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
    );
  }

  Widget _buildCardBack(flashcard_models.FlashcardCard card) {
    final extraCols = card.extraColumns;
    final columnCount = card.columnCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: _dividerOpacity)
        : Colors.black.withValues(alpha: _dividerOpacity);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kolom 1 - MAIN WORD (dynamic font size)
            Text(
              card.col1,
              style: TextStyle(
                fontSize: _mainFontSize,
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
              _buildExtraColumnsLayout(extraCols, columnCount, _subFontSize),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtraColumnsLayout(List<String> extraCols, int columnCount, double fontSize) {
    int count = extraCols.length;

    if (count == 1) {
      // 2 kolom total: 1 extra (centered)
      return Text(
        extraCols[0],
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      );
    } else if (count == 2) {
      // 3 kolom total: 2 extras horizontal
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: extraCols.map((col) {
          return Expanded(
            child: Text(
              col,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      );
    } else if (count == 3) {
      // 4 kolom total: 2 + 1 dengan divider
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: extraCols.sublist(0, 2).map((col) {
              return Expanded(
                child: Text(
                  col,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            extraCols[2],
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (count >= 4) {
      // 5-6 kolom total: 2 + 2 dengan divider (dan extra jika ada)
      List<Widget> rows = [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: extraCols.sublist(0, 2).map((col) {
            return Expanded(
              child: Text(
                col,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ];

      if (count >= 5) {
        rows.add(const SizedBox(height: 8));
        rows.add(Container(
          height: 1,
          color: Colors.black.withValues(alpha: 0.5),
        ));
        rows.add(const SizedBox(height: 8));

        // Row 2: kolom 4 & 5
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: extraCols.sublist(2, count > 4 ? 4 : count).map((col) {
            return Expanded(
              child: Text(
                col,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ));
      }

      // Jika ada kolom 6 (count == 5, extraCols[4])
      if (count == 5) {
        rows.add(const SizedBox(height: 8));
        rows.add(Text(
          extraCols[4],
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ));
      }

      return Column(children: rows);
    }

    return const SizedBox.shrink();
  }
}
