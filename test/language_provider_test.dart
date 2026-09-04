import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yor_flashcard/providers/language_provider.dart';
import 'package:yor_flashcard/utils/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageProvider and AppStrings Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial language defaults to English', () async {
      final provider = LanguageProvider();
      expect(provider.currentLanguage, 'en');
      expect(provider.isEnglish, true);
      expect(provider.isIndonesian, false);
    });

    test('Changing language updates state and persists in SharedPreferences', () async {
      final provider = LanguageProvider();
      await provider.setLanguage('id');

      expect(provider.currentLanguage, 'id');
      expect(provider.isIndonesian, true);
      expect(provider.isEnglish, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('yorflashcard_language'), 'id');

      // Test toggle
      provider.toggleLanguage();
      expect(provider.currentLanguage, 'en');
      expect(provider.isEnglish, true);
    });

    test('AppStrings respects English and Indonesian with technical terms preserved', () {
      // English
      expect(AppStrings.startLearning('en'), 'START LEARNING');
      expect(AppStrings.settings('en'), 'SETTINGS');
      expect(AppStrings.importDataset('en'), 'IMPORT DATASET');
      expect(AppStrings.darkMode('en'), 'Dark Mode');
      expect(AppStrings.cancel('en'), 'Cancel');
      expect(AppStrings.save('en'), 'Save');

      // Indonesian
      expect(AppStrings.startLearning('id'), 'MULAI BELAJAR');
      expect(AppStrings.settings('id'), 'PENGATURAN');
      // Technical terms preserved:
      expect(AppStrings.importDataset('id'), 'IMPORT DATASET');
      expect(AppStrings.datasets('id'), 'Dataset');
      expect(AppStrings.darkMode('id'), 'Dark Mode');
      expect(AppStrings.exportData('id'), 'Export Data');
      expect(AppStrings.cancel('id'), 'Batal');
      expect(AppStrings.save('id'), 'Simpan');
    });
  });
}
