import 'package:flutter/material.dart';

/// Enum representasi dua mode aplikasi Flashcard:
/// 1. [language] - Khusus pembelajaran bahasa (fitur Writing Practice aktif).
/// 2. [all] - Flashcard serbaguna untuk semua subjek (tanpa Writing Practice).
enum FlashcardAppMode {
  language,
  all;

  String get id => name;

  /// Prefix unik untuk penyimpanan database di SharedPreferences
  String get storagePrefix {
    switch (this) {
      case FlashcardAppMode.language:
        return 'yorflashcard_lang_';
      case FlashcardAppMode.all:
        return 'yorflashcard_all_';
    }
  }

  /// Menentukan apakah fitur Writing Practice (Latihan Menulis) aktif
  bool get enableWritingPractice {
    switch (this) {
      case FlashcardAppMode.language:
        return true;
      case FlashcardAppMode.all:
        return false;
    }
  }

  /// Icon representasi visual untuk launcher card
  IconData get icon {
    switch (this) {
      case FlashcardAppMode.language:
        return Icons.translate_rounded;
      case FlashcardAppMode.all:
        return Icons.school_rounded;
    }
  }

  /// Warna aksen utama untuk tema visual mode
  Color get primaryAccentColor {
    switch (this) {
      case FlashcardAppMode.language:
        return const Color(0xFF4338CA); // Indigo
      case FlashcardAppMode.all:
        return const Color(0xFF0F766E); // Teal / Emerald
    }
  }

  /// Warna latar kartu di Hub launcher
  Color get cardBackgroundColor {
    switch (this) {
      case FlashcardAppMode.language:
        return const Color(0xFF4F46E5);
      case FlashcardAppMode.all:
        return const Color(0xFF0D9488);
    }
  }
}

