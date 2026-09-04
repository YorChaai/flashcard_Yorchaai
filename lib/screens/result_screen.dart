import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../utils/app_strings.dart';
import 'home_screen.dart';
import 'deck_detail_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final sessionProvider = context.watch<LearningSessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.learningResults(lang)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // Completion Icon
            Icon(
              Icons.emoji_events,
              size: 100,
              color: sessionProvider.progressPercent >= 70
                  ? Colors.amber
                  : Colors.grey,
            ),

            const SizedBox(height: 24),

            Text(
              AppStrings.sessionComplete(lang),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Statistics Cards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      runSpacing: 16,
                      children: [
                        _StatItem(
                          icon: Icons.format_list_numbered,
                          label: AppStrings.totalStat(lang),
                          value: sessionProvider.totalCards.toString(),
                          color: Colors.blue,
                        ),
                        _StatItem(
                          icon: Icons.check_circle,
                          label: AppStrings.knownStat(lang),
                          value: sessionProvider.knownCount.toString(),
                          color: Colors.green,
                        ),
                        _StatItem(
                          icon: Icons.cancel,
                          label: AppStrings.unknownStat(lang),
                          value: sessionProvider.unknownCount.toString(),
                          color: Colors.red,
                        ),
                        _StatItem(
                          icon: Icons.skip_next,
                          label: AppStrings.skipStat(lang),
                          value: sessionProvider.skipCount.toString(),
                          color: Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Progress Bar
                    Column(
                      children: [
                        Text(
                          '${sessionProvider.progressPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: sessionProvider.progressPercent / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            sessionProvider.progressPercent >= 70
                                ? Colors.green
                                : Colors.orange,
                          ),
                          minHeight: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      sessionProvider.resetSession();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(AppStrings.home(lang)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Retrieve the deck ID BEFORE resetting the session
                      final savedDeckId = sessionProvider.currentDeckId;

                      // Reset session state
                      sessionProvider.resetSession();

                      if (savedDeckId != null) {
                        // Navigate deterministically: go to HomeScreen then
                        // immediately open the DeckDetailScreen for the saved deck.
                        final deckProvider = context.read<DeckProvider>();
                        final deck = deckProvider.decks.firstWhere(
                          (d) => d.id == savedDeckId,
                          orElse: () => deckProvider.decks.first,
                        );
                        deckProvider.selectDeck(deck);

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const DeckDetailScreen(),
                            settings: const RouteSettings(name: 'DeckDetailScreen'),
                          ),
                          (route) => route.isFirst,
                        );
                      } else {
                        // Fallback: pop until reaching DeckDetailScreen
                        Navigator.of(context).popUntil((route) {
                          final name = route.settings.name ?? '';
                          return name != 'FlashcardScreen' && name != 'ResultScreen';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(AppStrings.reviewAgain(lang)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
