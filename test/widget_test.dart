import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yor_flashcard/providers/theme_provider.dart';
import 'package:yor_flashcard/providers/app_providers.dart';
import 'package:yor_flashcard/screens/home_screen.dart';

void main() {
  testWidgets('YorFlashCard app should load without errors', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => DeckProvider()),
          ChangeNotifierProvider(create: (_) => LearningSessionProvider()),
        ],
        child: MaterialApp(
          home: HomeScreen(
            key: const ValueKey('home_screen'),
          ),
        ),
      ),
    );

    expect(find.text('YorFlashCard'), findsOneWidget);
  });
}
