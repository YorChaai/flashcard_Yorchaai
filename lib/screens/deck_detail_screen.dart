import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../models/order_mode.dart';
import 'flashcard_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  OrderMode _selectedMode = OrderMode.normal;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: '1');
    _toController = TextEditingController();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckProvider>().selectedDeck;

    if (deck == null) {
      return const Scaffold(
        body: Center(child: Text('No deck selected')),
      );
    }

    if (_toController.text.isEmpty) {
      _toController.text = deck.totalCards.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      runSpacing: 16,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.format_list_numbered, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '${deck.totalCards}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Total Cards'),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(Icons.view_column, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              '${deck.columnCount}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Columns'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Column Headers:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: deck.columnHeaders.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(
                            '${entry.key + 1}. ${entry.value}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Learning Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available data: 1 - ${deck.totalCards}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fromController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'From',
                              hintText: '1',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _toController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'To',
                              hintText: deck.totalCards.toString(),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order Mode
            const Text(
              'Order Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Radio<OrderMode>(
                        // ignore: deprecated_member_use
                        value: OrderMode.normal,
                        // ignore: deprecated_member_use
                        groupValue: _selectedMode,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                            });
                          }
                        },
                      ),
                      title: const Text('Normal'),
                      subtitle: const Text('Original order (as in Excel)'),
                    ),
                    ListTile(
                      leading: Radio<OrderMode>(
                        // ignore: deprecated_member_use
                        value: OrderMode.reverse,
                        // ignore: deprecated_member_use
                        groupValue: _selectedMode,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                            });
                          }
                        },
                      ),
                      title: const Text('Reverse'),
                      subtitle: const Text('Reversed order'),
                    ),
                    ListTile(
                      leading: Radio<OrderMode>(
                        // ignore: deprecated_member_use
                        value: OrderMode.random,
                        // ignore: deprecated_member_use
                        groupValue: _selectedMode,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMode = value;
                            });
                          }
                        },
                      ),
                      title: const Text('Random'),
                      subtitle: const Text('Shuffled order'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Start Button
            ElevatedButton(
              onPressed: _startLearning,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Start Learning',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startLearning() {
    final deck = context.read<DeckProvider>().selectedDeck;
    if (deck == null || deck.cards.isEmpty) return;

    final from = int.tryParse(_fromController.text) ?? 1;
    final to = int.tryParse(_toController.text) ?? deck.totalCards;

    if (from < 1 || to < 1 || from > deck.totalCards || to > deck.totalCards) {
      _showRangeError('Range harus di antara 1 sampai ${deck.totalCards}.');
      return;
    }

    if (from > to) {
      _showRangeError('Nilai "From" tidak boleh lebih besar dari "To".');
      return;
    }

    final selectedCards = deck.cards.sublist(from - 1, to);
    if (selectedCards.isEmpty) {
      _showRangeError('Tidak ada data pada range yang dipilih.');
      return;
    }

    context.read<LearningSessionProvider>().startSession(
          selectedCards,
          _selectedMode,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FlashcardScreen(),
      ),
    );
  }

  void _showRangeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
