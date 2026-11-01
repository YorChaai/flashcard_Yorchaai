import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yor_flashcard/providers/theme_provider.dart';
import 'package:yor_flashcard/providers/language_provider.dart';
import 'package:yor_flashcard/providers/app_providers.dart';
import 'package:yor_flashcard/screens/main_hub_screen.dart';

void main() {
  testWidgets('YorFlashCard MainHubScreen should load with mode cards', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    final languageProvider = LanguageProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: languageProvider),
          ChangeNotifierProvider(create: (_) => DeckProvider()),
          ChangeNotifierProvider(create: (_) => LearningSessionProvider()),
        ],
        child: const MaterialApp(
          home: MainHubScreen(),
        ),
      ),
    );

    expect(find.text('YORFLASHCARD'), findsOneWidget);
    expect(find.text('Flashcard Language'), findsOneWidget);
    expect(find.text('Flashcard All'), findsOneWidget);
  });
}
