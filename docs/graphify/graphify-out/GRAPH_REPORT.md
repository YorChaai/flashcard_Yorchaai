# Graph Report - flashcard  (2026-09-04)

## Corpus Check
- 82 files · ~2,494,445 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1284 nodes · 1554 edges · 90 communities (68 shown, 14 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e798ce5c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- learning_preview_screen.dart
- app_providers.dart
- deck.dart
- swipeable_notification.dart
- storage_service.dart
- excel_service.dart
- home_screen.dart
- deck_detail_screen.dart
- package:flutter_test/flutter_test.dart
- import_mapping_dialog.dart
- prompt_service.dart
- flashcard_screen.dart
- deleted_data_screen.dart
- deck_config.dart
- export_mapping_dialog.dart
- font_size_settings.dart
- DeckProvider
- result_screen.dart
- main.dart
- ThemeProvider
- LanguageProvider
- sort_mode.dart
- import_preview_screen.dart
- app_strings.dart
- planpeubahan apliaski 2.0.md
- 📋 PLAN 3.0 - Flashcard Layout Update
- YorFlashCard - Flashcard Learning App
- 🚀 Cara Jalankan YorFlashCard v3.0
- 🎉 YorFlashCard 2.0 - What's New
- YorFlashCard - Quick Start Guide
- aplikasiflash.md
- 📖 Penjelasan Error Git Push: File Ukuran Besar (>100MB)
- theme_provider.dart
- YorFlashCard -- Specification Compliance Report
- SORT
- plan3.md
- language_provider.dart
- 📋 PLAN - UI Fix: Stats Card & Button Consistency
- 📋 PLAN - Fix Column Structure Chip Colors
- Panduan Penggunaan Graphify pada Proyek Flutter Flashcard
- State
- 🐛 Bug Fix Summary - YorFlashCard 2.0
- 2. Rincian Kronologi Langkah & Masalah yang Ditemukan
- flashcard_FINAL_CLEAN_223a6f10.md
- flashcard_FINAL_WITH_PROMPT_V4_060c6555.md
- flashcard_FINAL_WITH_PROMPT_V4_aa4202d2.md
- flashcard_FINAL_WITH_PROMPT_V4 - Copy_47a7354b.md
- flashcard_KOREAN_FINAL_88ce939b.md
- Panduan Instalasi Graphify di Windows & Google Antigravity
- plan4.md
- plan.md
- Laporan Perbaikan Error "VM Snapshot Invalid"
- Panduan Lengkap Graphify (Knowledge Graph untuk Codebase)
- **3. Layout Flashcard Berdasarkan Jumlah Kolom**
- **8. Urutan Implementasi**
- ✅ Yang Sudah Dibikin:
- docs/graphify.md
- Cheat Sheet Perintah Graphify CLI
- ✅ **Yang Sudah Ditambahkan:**
- language_provider_test.dart
- **1. Perubahan Struktur Data**
- **6. File yang Perlu Dibuat/Dimodifikasi**
- flashcard_20260405_0142_2c314edf.md
- rules/graphify.md
- workflows/graphify.md
- Summary
- Dataset_Chinese_63d9eee8.md
- flashcard_KOREAN_POC_f3800d77.md
- sample_2columns_247beb5d.md
- sample_3columns_0eae476e.md
- sample_4columns_654ef044.md
- sample_5columns_57af1eb3.md
- sample_6columns_3b039e64.md
- sample_vocabulary_7454069e.md
- OrderMode
- deck_column_helper.dart
- package:flutter/material.dart
- StatelessWidget
- _startLearning
- deck_config_persistence_test.dart
- List
- _LearningPreviewScreenState

## God Nodes (most connected - your core abstractions)
1. `LanguageProvider` - 62 edges
2. `DeckProvider` - 42 edges
3. `YorFlashCard -- Specification Compliance Report` - 15 edges
4. `ThemeProvider` - 13 edges
5. `YorFlashCard - Quick Start Guide` - 12 edges
6. `YorFlashCard - Flashcard Learning App` - 12 edges
7. `LearningSessionProvider` - 11 edges
8. `📋 PLAN 3.0 - Flashcard Layout Update` - 11 edges
9. `🐛 Bug Fix Summary - YorFlashCard 2.0` - 10 edges
10. `🎉 YorFlashCard 2.0 - What's New` - 9 edges

## Surprising Connections (you probably didn't know these)
- `_getCurrentDeck` --references--> `DeckProvider`  [EXTRACTED]
  lib/screens/deleted_data_screen.dart → lib/providers/app_providers.dart
- `build` --references--> `LanguageProvider`  [EXTRACTED]
  lib/screens/deleted_data_screen.dart → lib/providers/language_provider.dart
- `build` --references--> `LanguageProvider`  [EXTRACTED]
  lib/screens/export_mapping_dialog.dart → lib/providers/language_provider.dart
- `_onExport` --references--> `LanguageProvider`  [EXTRACTED]
  lib/screens/export_mapping_dialog.dart → lib/providers/language_provider.dart
- `_buildScoreAndPracticeAction` --references--> `LanguageProvider`  [EXTRACTED]
  lib/screens/flashcard_screen.dart → lib/providers/language_provider.dart

## Import Cycles
- None detected.

## Communities (90 total, 14 thin omitted)

### Community 0 - "learning_preview_screen.dart"
Cohesion: 0.04
Nodes (50): deleted_data_screen.dart, _ActiveFilterItem, _allCards, _allCefrLevels, _allColumnUniqueValues, _allUniqueTypes, _applyFilterAndSort, _cardOriginalNumbers (+42 more)

### Community 1 - "app_providers.dart"
Cohesion: 0.04
Nodes (48): Deck? get, FlashcardCard? get, addDeck, _applyMark, currentCard, _currentDeckId, _currentIndex, _deckConfigs (+40 more)

### Community 2 - "deck.dart"
Cohesion: 0.05
Nodes (41): flashcard_card.dart, int?, int get, addCard, cards, columnCount, columnHeaders, copyWith (+33 more)

### Community 3 - "swipeable_notification.dart"
Cohesion: 0.05
Nodes (41): dart:async, Duration, GlobalKey, actionLabel, _animateDismiss, _animController, AppNotification, _autoDismissTimer (+33 more)

### Community 4 - "storage_service.dart"
Cohesion: 0.10
Nodes (20): addDeck, _clearCorruptedData, _deckConfigsPrefix, _decksKey, deleteDeck, getDeckConfig, getLastSelectedDeckId, _getPrefs (+12 more)

### Community 5 - "excel_service.dart"
Cohesion: 0.05
Nodes (36): import pandas as, import sys, applyMapping, attemptPythonRepair, _buildDeckFromDecoder, bytes, columnCount, columnHeaders (+28 more)

### Community 6 - "home_screen.dart"
Cohesion: 0.08
Nodes (25): export_mapping_dialog.dart, import_mapping_dialog.dart, import_preview_screen.dart, createState, decks, dispose, _exportDeck, fontSize1Controller (+17 more)

### Community 7 - "deck_detail_screen.dart"
Cohesion: 0.08
Nodes (25): flashcard_screen.dart, Key, learning_preview_screen.dart, _AddCustomCardRowItem, _addRow, artiController, createState, currentDeck (+17 more)

### Community 8 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.10
Nodes (18): dart:io, package:flutter_test/flutter_test.dart, package:yor_flashcard/models/deck.dart, package:yor_flashcard/models/flashcard_card.dart, package:yor_flashcard/services/excel_service.dart, package:yor_flashcard/services/prompt_service.dart, package:yor_flashcard/utils/app_strings.dart, return (+10 more)

### Community 9 - "import_mapping_dialog.dart"
Cohesion: 0.15
Nodes (12): build, createState, _getPreviewText, initState, metadata, _numFlashcardColumns, _onProceed, _selectedExcelColumns (+4 more)

### Community 10 - "prompt_service.dart"
Cohesion: 0.13
Nodes (14): extractCardWordAndType, generatePrompt, getTypeColumnIndex, key, _knownTypes, normalizeType, plural, priority (+6 more)

### Community 11 - "flashcard_screen.dart"
Cohesion: 0.08
Nodes (26): Animation, AnimationController, dart:math, _animationController, _buildExtraColumnsLayout, _buildScoreAndPracticeAction, _buildScoreBadge, _checkAnswer (+18 more)

### Community 12 - "deleted_data_screen.dart"
Cohesion: 0.09
Nodes (23): build, _buildDataTableCard, _buildPaginationControls, _cardOriginalNumbers, columnHeaders, _createDataRow, createState, _currentPage (+15 more)

### Community 13 - "deck_config.dart"
Cohesion: 0.09
Nodes (21): bool?, cefrSortAscending, columnFilters, copyWith, DeckConfig, deckId, fromJson, orderMode (+13 more)

### Community 14 - "export_mapping_dialog.dart"
Cohesion: 0.09
Nodes (23): build, createState, deck, dispose, ExportColumnItem, ExportMappingDialog, _ExportMappingDialogState, ExportMappingResult (+15 more)

### Community 15 - "font_size_settings.dart"
Cohesion: 0.10
Nodes (19): double get, copyWith, currentFontSize1, currentFontSize23, currentFontSize45, currentFontSize6, fromJson, getCurrentPlatformLabel (+11 more)

### Community 16 - "DeckProvider"
Cohesion: 0.13
Nodes (15): DeckProvider, didChangeDependencies, _handleSave, _handleRefreshRow, _importDataset, initState, _showDeleteDialog, _confirmDelete (+7 more)

### Community 17 - "result_screen.dart"
Cohesion: 0.22
Nodes (8): Color?, deck_detail_screen.dart, home_screen.dart, IconData?, color, icon, label, value

### Community 18 - "main.dart"
Cohesion: 0.17
Nodes (11): build, _buildDarkTheme, _buildLightTheme, languageProvider, loadLanguage, loadTheme, main, themeProvider (+3 more)

### Community 19 - "ThemeProvider"
Cohesion: 0.25
Nodes (8): ThemeProvider, _showColumnEditDialog, _buildCardBack, _buildCardFront, FlashcardScreen, _FlashcardScreenState, _showSettingsDialog, SingleTickerProviderStateMixin

### Community 20 - "LanguageProvider"
Cohesion: 0.12
Nodes (19): ChangeNotifier, LearningSessionProvider, LanguageProvider, build, _showJumpToPageDialog, build, _showRenameDialog, _buildActionButtons (+11 more)

### Community 21 - "sort_mode.dart"
Cohesion: 0.50
Nodes (3): highestScore, SortMode, original,
  lowestScore,

### Community 22 - "import_preview_screen.dart"
Cohesion: 0.14
Nodes (13): build, _buildActionButtons, _buildColumnStructureCard, _buildDataPreviewTable, _buildFileInformationCard, _buildInfoRow, _buildPreviewRows, _buildSummary (+5 more)

### Community 25 - "app_strings.dart"
Cohesion: 0.01
Nodes (165): activeDataset, activeFilter, addCustomCard, addNewWords, addRow, allColumns, applyFilter, applyRange (+157 more)

### Community 26 - "planpeubahan apliaski 2.0.md"
Cohesion: 0.06
Nodes (30): **10. Breaking Changes**, **11. Estimasi Kompleksitas**, **1. Perubahan Struktur Data**, **2 Kolom:**, **2. User Flow Import (UPDATE TOTAL)**, **3 Kolom:**, **3. Layout Flashcard Berdasarkan Jumlah Kolom**, **4. Home Screen (UPDATE)** (+22 more)

### Community 27 - "📋 PLAN 3.0 - Flashcard Layout Update"
Cohesion: 0.07
Nodes (28): **2 Kolom:**, **3 Kolom:**, **4 Kolom:**, **5 Kolom:**, **6 Kolom:**, **Card Model:**, **CREATE:**, 📦 **Data Structure Update:** (+20 more)

### Community 28 - "YorFlashCard - Flashcard Learning App"
Cohesion: 0.08
Nodes (25): 1. Import a Dataset, 2. Configure Learning Session, 3. Study with Flashcards, 4. View Results, App doesn't import Excel file, Building for Production, Cards not showing, Data lost after restart (+17 more)

### Community 29 - "🚀 Cara Jalankan YorFlashCard v3.0"
Cohesion: 0.08
Nodes (25): 📱 ANDROID, Android Build Error:, Android (Build Release):, Android (Development):, App Not Opening:, Build Release:, 🚀 Cara Jalankan YorFlashCard v3.0, 🎯 Command Cepat (Copy-Paste) (+17 more)

### Community 30 - "🎉 YorFlashCard 2.0 - What's New"
Cohesion: 0.08
Nodes (24): 1. **Dynamic Columns (2-6 Kolom)**, 2. **Dark/Light Theme**, **2 Kolom:**, **3 Kolom:**, 3. **Layout Flashcard Dinamis**, 4. **Home Screen Update**, **4 Kolom:**, 5. **Import Flow Baru** (+16 more)

### Community 31 - "YorFlashCard - Quick Start Guide"
Cohesion: 0.10
Nodes (19): ⚙️ Build Commands, 🎮 Controls, 🎨 Customization, Data not saving, Development, 📋 Excel File Format, 📊 Features Implemented, Flashcard Screen (+11 more)

### Community 32 - "aplikasiflash.md"
Cohesion: 0.11
Nodes (18): **10. Breaking Changes**, **11. Estimasi Kompleksitas**, **2. User Flow Import (UPDATE TOTAL)**, **4. Home Screen (UPDATE)**, **5. Dataset Detail Screen (UPDATE)**, **7. Validasi Excel**, **9. Sample Excel yang Perlu Dibuat**, 📦 **Cara Menjalankan:** (+10 more)

### Community 33 - "📖 Penjelasan Error Git Push: File Ukuran Besar (>100MB)"
Cohesion: 0.11
Nodes (18): 1. File Build/Generated Masuk ke Git, 1. Pastikan `.gitignore` Benar, 2. GitHub Punya Batas Keras 100MB, 2. Workflow Aman Sebelum Commit, 3. Git Menyimpan Semua Riwayat (History), 3. Gunakan `git rm --cached` jika Terlanjur, 🔍 Apa yang Terjadi?, 🛡️ Cara Mencegah di Masa Depan (+10 more)

### Community 34 - "theme_provider.dart"
Cohesion: 0.11
Nodes (17): dart:convert, FontSizeSettings get, FontSizeSettings, _fontSizeKey, _fontSizeSettings, _getPrefs, isDarkMode, loadTheme (+9 more)

### Community 35 - "YorFlashCard -- Specification Compliance Report"
Cohesion: 0.13
Nodes (15): 10. Multi-dataset -- Can store multiple Excel files as Decks, 11. Dataset Management -- Rename, Delete, Select dataset, 12. Local Storage -- Uses SharedPreferences, 13. No AI, login, cloud sync, multiplayer, 14. Animations limited -- Only flip animation and smooth transitions, 1. Import Excel -- User can upload .xlsx file with columns "no" and "kata", 2. Filter Range -- User inputs start_no and end_no, 3. Mode Urutan -- Normal (asc), Reverse (desc), Random (shuffle) (+7 more)

### Community 36 - "SORT"
Cohesion: 0.13
Nodes (14): Arti, CEFR, FILTER, Filter CEFR, Filter Score, Filter Type, IPA, Kata (+6 more)

### Community 37 - "plan3.md"
Cohesion: 0.13
Nodes (14): 10. Hal yang Harus Dipastikan, 1. Refresh di Custom Database, 2. Delete Jangan Menghapus Data Secara Permanen, 3. Tombol Deleted Data, 4. Halaman Deleted Data, 5. Tombol Aksi di Deleted Data, 6. Masalah Nomor / No, 7. Sinkronisasi Import Database dan Deleted Data (+6 more)

### Community 38 - "language_provider.dart"
Cohesion: 0.14
Nodes (13): bool get, _currentLanguage, _getPrefs, isEnglish, isIndonesian, _languageKey, loadLanguage, _prefs (+5 more)

### Community 39 - "📋 PLAN - UI Fix: Stats Card & Button Consistency"
Cohesion: 0.15
Nodes (12): **1. Stats Card - Tambah Border & Background Terang di Dark Mode**, 1. **Stats Card Terlalu Gelap (Dark Mode)**, **2. Button Konsistensi - Semuanya Filled dengan Warna Sama**, 2. **Button Tidak Konsisten**, **Button Hierarchy (After Fix):**, ✅ **Checklist Implementasi:**, **File: `lib/screens/home_screen.dart`**, 🎯 **Masalah yang Ditemukan:** (+4 more)

### Community 40 - "📋 PLAN - Fix Column Structure Chip Colors"
Cohesion: 0.17
Nodes (11): 1. **Light Mode**, 2. **Dark Mode**, ✅ **Checklist Implementasi:**, **Dark Mode:**, **File: `lib/screens/import_preview_screen.dart`**, **Light Mode:**, 🎯 **Masalah yang Ditemukan:**, **Metode: `_buildColumnStructureCard`** (+3 more)

### Community 41 - "Panduan Penggunaan Graphify pada Proyek Flutter Flashcard"
Cohesion: 0.17
Nodes (11): 1. Menyiapkan File `.graphifyignore` (Sangat Disarankan), 2. Membuat Knowledge Graph Codebase Pertama Kali, 3. Melihat Visualisasi Graf di Browser, 4. Query Kode Melalui Terminal, 5. Memperbarui Graf Ketika Ada Perubahan Kode, 6. Mengaktifkan Otomasi Git Hook (Opsional), A. Menjelaskan Suatu Komponen / Model, Apa yang Terjadi Saat Perintah Berjalan? (+3 more)

### Community 42 - "State"
Cohesion: 0.16
Nodes (17): _AddCustomCardDialog, _AddCustomCardDialogState, DeckDetailScreen, _DeckDetailScreenState, _ExportDeckWidget, _ExportDeckWidgetState, HomeScreen, _HomeScreenState (+9 more)

### Community 43 - "🐛 Bug Fix Summary - YorFlashCard 2.0"
Cohesion: 0.18
Nodes (10): ✅ **ALL 27 ISSUES FIXED!**, 🐛 Bug Fix Summary - YorFlashCard 2.0, 📈 **Build Status:**, 🔴 CRITICAL (3/3 Fixed), 📊 **Final Result:**, 🟠 HIGH (5/5 Fixed), 🟢 LOW (9/9 Fixed), 🟡 MEDIUM (10/10 Fixed) (+2 more)

### Community 44 - "2. Rincian Kronologi Langkah & Masalah yang Ditemukan"
Cohesion: 0.18
Nodes (10): 1. Diagram Alur Proses & Troubleshooting, 2. Rincian Kronologi Langkah & Masalah yang Ditemukan, 3. Rumus Praktis untuk Proyek Antigravity Lainnya, Catatan Belajar: Alur Kerja, Masalah/Error, dan Solusi Pemasangan Graphify, Tahap 1: Pengecekan Lingkungan (Environment Check), Tahap 2: Pemasangan Paket Inti Graphify, Tahap 3: Integrasi dengan Google Antigravity IDE, Tahap 4: Ekstraksi Graf Pertama Kali & Error API Key (+2 more)

### Community 45 - "flashcard_FINAL_CLEAN_223a6f10.md"
Cohesion: 0.18
Nodes (10): area (noun - Level A1 atau B2), Dialog 1, Dialog 1, Dialog 2, [KATA] ([TYPE] - Level Cerf Target Saya), Sheet: ai, Sheet: Grammar (Original), Sheet: Grammar (Wuthuring) (+2 more)

### Community 46 - "flashcard_FINAL_WITH_PROMPT_V4_060c6555.md"
Cohesion: 0.18
Nodes (10): area (noun - Level A1 atau B2), Dialog 1, Dialog 1, Dialog 2, [KATA] ([TYPE] - Level Cerf Target Saya), Sheet: ai, Sheet: Grammar (Original), Sheet: Grammar (Wuthuring) (+2 more)

### Community 47 - "flashcard_FINAL_WITH_PROMPT_V4_aa4202d2.md"
Cohesion: 0.18
Nodes (10): area (noun - Level A1 atau B2), Dialog 1, Dialog 1, Dialog 2, [KATA] ([TYPE] - Level Cerf Target Saya), Sheet: ai, Sheet: Grammar (Original), Sheet: Grammar (Wuthuring) (+2 more)

### Community 48 - "flashcard_FINAL_WITH_PROMPT_V4 - Copy_47a7354b.md"
Cohesion: 0.18
Nodes (10): area (noun - Level A1 atau B2), Dialog 1, Dialog 1, Dialog 2, [KATA] ([TYPE] - Level Cerf Target Saya), Sheet: ai, Sheet: Grammar (Original), Sheet: Grammar (Wuthuring) (+2 more)

### Community 49 - "flashcard_KOREAN_FINAL_88ce939b.md"
Cohesion: 0.18
Nodes (10): area (noun - Level A1 atau B2), Dialog 1, Dialog 1, Dialog 2, [KATA] ([TYPE] - Level Cerf Target Saya), Sheet: ai, Sheet: Grammar (Original), Sheet: Grammar (Wuthuring) (+2 more)

### Community 50 - "Panduan Instalasi Graphify di Windows & Google Antigravity"
Cohesion: 0.20
Nodes (9): 1. Prasyarat Sistem, 2. Catatan Penting Mengenai Nama Paket, 3. Langkah Instalasi, 4. Integrasi ke Google Antigravity, 5. Catatan Khusus Pengguna PowerShell Windows, 6. Mengabaikan File Output di Git (.gitignore), Opsi A: Menggunakan `uv` (Sangat Direkomendasikan), Opsi B: Menggunakan `pip` Langsung (+1 more)

### Community 51 - "plan4.md"
Cohesion: 0.20
Nodes (9): 1. Sort & Filter harus persistent per file, 2. Order Mode harus mengikuti Sort yang sudah dibuat, 3. Tambahkan Range pada Sort, 4. Range dari Sort harus terhubung dengan Learning Range, 5. Jangan membuat dua state Range yang saling bertentangan, 6. State yang harus dipertahankan, 7. Urutan proses data, Contoh behaviour yang saya inginkan (+1 more)

### Community 52 - "plan.md"
Cohesion: 0.25
Nodes (7): 1. Fitur Edit di Library Preview, 2. Perbedaan Import Database dan Custom Database, 3. Sort dan Filter, 4. Rencana Pengembangan Berikutnya, 5. Referensi Implementasi Sort dan Filter, Edit, Refresh

### Community 53 - "Laporan Perbaikan Error "VM Snapshot Invalid""
Cohesion: 0.25
Nodes (7): 1. `android/build.gradle.kts`, 2. `android/app/src/main/AndroidManifest.xml`, 3. Clear Cache & Re-build, 🔍 Analisis Penyebab Utama (Root Cause), 🐛 Gejala Error (Symptom), Laporan Perbaikan Error "VM Snapshot Invalid", 🛠️ Perbaikan yang Dilakukan (Fixes)

### Community 54 - "Panduan Lengkap Graphify (Knowledge Graph untuk Codebase)"
Cohesion: 0.29
Nodes (6): 1. Apa itu Graphify?, 2. Mengapa Graphify Berbeda dari RAG / Vector Biasa?, 3. Apa yang Dihasilkan Setelah Graphify Dijalankan?, 4. Dukungan untuk Proyek Ini (Dart / Flutter), 5. Indeks Dokumentasi di Folder Ini, Panduan Lengkap Graphify (Knowledge Graph untuk Codebase)

### Community 55 - "**3. Layout Flashcard Berdasarkan Jumlah Kolom**"
Cohesion: 0.33
Nodes (6): **2 Kolom:**, **3 Kolom:**, **3. Layout Flashcard Berdasarkan Jumlah Kolom**, **4 Kolom:**, **5 Kolom:**, **6 Kolom:**

### Community 56 - "**8. Urutan Implementasi**"
Cohesion: 0.33
Nodes (6): **8. Urutan Implementasi**, **Phase 1: Data Model & Services** (Backend), **Phase 2: Import Flow** (UI), **Phase 3: Display** (UI), **Phase 4: Flashcard Layout** (UI + Animation), **Phase 5: Testing**

### Community 57 - "✅ Yang Sudah Dibikin:"
Cohesion: 0.33
Nodes (6): **Cara Menjalankan:**, **File Penting:**, **Fitur Utama:**, **Lokasi App yang Sudah Dibuild:**, **Struktur Project:**, ✅ Yang Sudah Dibikin:

### Community 58 - "docs/graphify.md"
Cohesion: 0.33
Nodes (5): .claudeignore graph.json graphify-out/, .graphifyignore node_modules/ dist/ _.generated.py # only index src/, ignore everything else _ !src/ !src/\*\*, NOTE: / # WHY: comments and ADR/RFC citations become first-class nodes linked to the code, query the graph from the terminal graphify query "show the auth flow" graphify query "what connects DigestAuth to Response?" --graph graphify-out/graph.json # expose the graph as an MCP server (for repeated tool-call access) python -m graphify.serve graphify-out/graph.json python -m graphify.serve --graph graphify-out/graph.json # --graph flag also accepted # register with Kimi Code: kimi mcp add --transport stdio graphify -- python -m graphify.serve graphify-out/graph.json # or serve over HTTP so a whole team points at one URL (no local graphify needed): python -m graphify.serve graphify-out/graph.json --transport http --port 8080 python -m graphify.serve graphify-out/graph.json --transport http --host 0.0.0.0 --api-key "$SECRET", Recommended (isolated env; if 'graphify' isn't found after, run: uv tool update-shell): uv tool install graphifyy # Alternatives: pipx install graphifyy pip install graphifyy # may need PATH setup — see note below

### Community 59 - "Cheat Sheet Perintah Graphify CLI"
Cohesion: 0.33
Nodes (5): 1. Membangun & Memperbarui Graf, 2. Query & Penelusuran Kode, 3. Integrasi & Asisten AI, 4. Ekspor Graf ke Format Lain, Cheat Sheet Perintah Graphify CLI

### Community 60 - "✅ **Yang Sudah Ditambahkan:**"
Cohesion: 0.40
Nodes (5): **1. Dynamic Columns (2-6 Kolom)**, **2. Dark/Light Theme**, **3. Sample Files**, **4. Documentation**, ✅ **Yang Sudah Ditambahkan:**

### Community 61 - "language_provider_test.dart"
Cohesion: 0.50
Nodes (3): package:shared_preferences/shared_preferences.dart, package:yor_flashcard/providers/language_provider.dart, main

### Community 62 - "**1. Perubahan Struktur Data**"
Cohesion: 0.67
Nodes (3): **1. Perubahan Struktur Data**, **Model Card (Update)**, **Model Deck (Update)**

### Community 63 - "**6. File yang Perlu Dibuat/Dimodifikasi**"
Cohesion: 0.67
Nodes (3): **6. File yang Perlu Dibuat/Dimodifikasi**, **Modified Files:**, **New Files:**

### Community 83 - "deck_column_helper.dart"
Cohesion: 0.14
Nodes (13): artiAliases, buildStandardCustomColumns, cefrAliases, DeckColumnHelper, getValueByHeaderAliases, ipaAliases, kataAliases, sanitizeAndAlignCustomDeck (+5 more)

### Community 84 - "package:flutter/material.dart"
Cohesion: 0.27
Nodes (8): package:flutter/material.dart, package:provider/provider.dart, package:yor_flashcard/providers/app_providers.dart, package:yor_flashcard/providers/theme_provider.dart, package:yor_flashcard/screens/flashcard_screen.dart, package:yor_flashcard/screens/home_screen.dart, main, main

### Community 85 - "StatelessWidget"
Cohesion: 0.29
Nodes (7): YorFlashCardApp, _ManageFilesDialog, _StatCard, ImportPreviewScreen, _StatItem, SheetSelectionDialog, StatelessWidget

### Community 86 - "_startLearning"
Cohesion: 0.40
Nodes (5): _previewLearning, _startLearning, build, build, MaterialPageRoute

### Community 87 - "deck_config_persistence_test.dart"
Cohesion: 0.50
Nodes (3): package:yor_flashcard/models/deck_config.dart, package:yor_flashcard/models/order_mode.dart, main

### Community 88 - "List"
Cohesion: 0.33
Nodes (5): build, sheets, List, ../providers/language_provider.dart, ../utils/app_strings.dart

## Knowledge Gaps
- **925 isolated node(s):** `themeProvider`, `languageProvider`, `main`, `loadTheme`, `loadLanguage` (+920 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1000 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `LanguageProvider` connect `LanguageProvider` to `learning_preview_screen.dart`, `language_provider.dart`, `deck_detail_screen.dart`, `home_screen.dart`, `import_mapping_dialog.dart`, `State`, `flashcard_screen.dart`, `deleted_data_screen.dart`, `export_mapping_dialog.dart`, `DeckProvider`, `result_screen.dart`, `main.dart`, `ThemeProvider`, `StatelessWidget`, `_startLearning`, `import_preview_screen.dart`, `List`, `_LearningPreviewScreenState`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **Why does `DeckProvider` connect `DeckProvider` to `learning_preview_screen.dart`, `app_providers.dart`, `home_screen.dart`, `deck_detail_screen.dart`, `State`, `flashcard_screen.dart`, `deleted_data_screen.dart`, `result_screen.dart`, `ThemeProvider`, `LanguageProvider`, `StatelessWidget`, `_startLearning`, `_LearningPreviewScreenState`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `Deck` connect `deck.dart` to `learning_preview_screen.dart`, `app_providers.dart`, `home_screen.dart`, `deck_detail_screen.dart`, `deleted_data_screen.dart`, `export_mapping_dialog.dart`?**
  _High betweenness centrality (0.008) - this node is a cross-community bridge._
- **What connects `themeProvider`, `languageProvider`, `main` to the rest of the system?**
  _925 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `learning_preview_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `app_providers.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._
- **Should `deck.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.048726467331118496 - nodes in this community are weakly interconnected._