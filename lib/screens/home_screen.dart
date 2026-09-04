import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../models/deck.dart';
import '../models/font_size_settings.dart';
import '../services/excel_service.dart';
import '../services/storage_service.dart';
import '../utils/app_strings.dart';
import 'deck_detail_screen.dart';
import 'import_preview_screen.dart';
import 'export_mapping_dialog.dart';
import 'sheet_selection_dialog.dart';
import 'import_mapping_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Deck? _selectedDataset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<DeckProvider>();
      await provider.loadDecks();
      if (mounted && provider.decks.isNotEmpty) {
        final lastDeckId = await StorageService().getLastSelectedDeckId();
        Deck? savedDeck;
        if (lastDeckId != null) {
          try {
            savedDeck = provider.decks.firstWhere((d) => d.id == lastDeckId);
          } catch (_) {
            savedDeck = null;
          }
        }
        
        // If no saved deck or saved deck is 'Custom Mode', and there are other decks, prefer the second one
        savedDeck ??= provider.decks.firstWhere((d) => d.id != 'custom_mode_deck_default', orElse: () => provider.decks.first);

        setState(() {
          _selectedDataset = savedDeck;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProv = context.watch<LanguageProvider>();
    final lang = langProv.currentLanguage;

    return Scaffold(
      body: Consumer<DeckProvider>(
        builder: (context, deckProvider, child) {
          final decks = deckProvider.decks;
          final totalCards = decks.fold<int>(0, (sum, d) => sum + d.totalCards);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'asset/logo/logoapp.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Theme.of(context).primaryColor,
                                child: const Icon(
                                  Icons.menu_book,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'YorFlashCard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppStrings.smartLearningApp(lang),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stats Card
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Theme.of(context).cardColor,
                    elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: Theme.of(context).brightness == Brightness.dark
                          ? BorderSide(color: Colors.grey[700]!, width: 1)
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatCard(
                            icon: Icons.folder,
                            value: '${decks.length}',
                            label: AppStrings.datasets(lang),
                          ),
                          _StatCard(
                            icon: Icons.view_carousel,
                            value: '$totalCards',
                            label: AppStrings.totalCards(lang),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Action Button
                  ElevatedButton.icon(
                    onPressed: decks.isNotEmpty
                        ? () {
                            final targetDeck = _selectedDataset ?? deckProvider.selectedDeck ?? decks.first;
                            deckProvider.selectDeck(targetDeck);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DeckDetailScreen(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 24, color: Colors.white),
                    label: Text(
                      AppStrings.startLearning(lang),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Import Dataset Button
                  OutlinedButton.icon(
                    onPressed: _importDataset,
                    icon: Icon(
                      Icons.upload_file,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                    ),
                    label: Text(
                      AppStrings.importDataset(lang),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Settings Button
                  OutlinedButton.icon(
                    onPressed: () => _showSettingsDialog(context),
                    icon: Icon(
                      Icons.settings,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600],
                    ),
                    label: Text(
                      AppStrings.settings(lang),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600],
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[400]!,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Empty State
                  if (decks.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.noDatasets(lang),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.importExcelPrompt(lang),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _importDataset() async {
    final lang = context.read<LanguageProvider>().currentLanguage;
    debugPrint('>>> STEP 1: Starting import...');
    try {
      debugPrint('>>> STEP 2: Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      debugPrint('>>> STEP 3: File picker result: ${result?.files.length ?? 0} files');

      if (result == null || result.files.isEmpty) {
        debugPrint('>>> STEP 3a: User cancelled or no files');
        return;
      }

      final file = result.files.single;
      debugPrint('>>> STEP 4: File selected: ${file.name}');
      debugPrint('>>> STEP 5: File path: ${file.path}');
      debugPrint('>>> STEP 6: File bytes length: ${file.bytes?.length ?? 0}');

      final fileName = file.name;
      final filePath = file.path ?? '';
      List<int>? fileBytes;

      if (file.bytes != null && file.bytes!.isNotEmpty) {
        debugPrint('>>> STEP 7a: Using bytes from FilePicker...');
        fileBytes = file.bytes;
      } else if (file.path != null && file.path!.isNotEmpty) {
        debugPrint('>>> STEP 7b: Reading bytes from file path...');
        fileBytes = await File(file.path!).readAsBytes();
        debugPrint('>>> STEP 7c: Read ${fileBytes.length} bytes');
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        debugPrint('>>> ERROR: Could not read file bytes!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'id' ? 'Gagal membaca file. Silakan coba lagi.' : 'Unable to read file. Please try again.',
              ),
            ),
          );
        }
        return;
      }

      // Show loading dialog for initial processing
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(lang == 'id' ? 'Membaca file Excel...' : 'Reading Excel file...'),
                ),
              ],
            ),
          ),
        );
      }

      debugPrint('>>> STEP 8: Getting available sheets...');
      List<String> sheets = await ExcelService.getAvailableSheets(fileBytes);
      
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
      }

      if (sheets.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'id'
                    ? 'Gagal membaca file. Harap "Save As" ke file baru atau simpan sebagai CSV.'
                    : 'Failed to read file. Please "Save As" a new file or save as CSV.',
              ),
            ),
          );
        }
        return;
      }

      String? targetSheetName;
      List<int>? importOrder;
      FileMetadata? mappedMetadata;

      while (true) {
        if (sheets.length > 1) {
          if (!mounted) return;
          targetSheetName = await showDialog<String>(
            context: context,
            builder: (context) => SheetSelectionDialog(sheets: sheets),
          );
          if (targetSheetName == null) return; // User canceled
        } else {
          targetSheetName = sheets.first;
        }

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(lang == 'id' ? 'Membaca struktur sheet...' : 'Reading sheet structure...'),
                  ),
                ],
              ),
            ),
          );
        }

        debugPrint('>>> STEP 9: Getting file metadata from bytes...');
        FileMetadata rawMetadata;
        rawMetadata = await ExcelService.getFileMetadataFromBytes(fileBytes, fileName, targetSheetName: targetSheetName);

        if (mounted) {
          Navigator.of(context).pop(); // dismiss loading
        }

        if (!mounted) return;
        
        debugPrint('>>> STEP 10: Showing Import Mapping Dialog...');
        final result = await showDialog<dynamic>(
          context: context,
          builder: (context) => ImportMappingDialog(
            metadata: rawMetadata,
            showBackButton: sheets.length > 1,
          ),
        );
        
        if (result == null) return; // User canceled
        if (result == 'BACK') {
          continue; // Go back to sheet selection
        }
        
        importOrder = result as List<int>;
        
        // Apply mapping to metadata for preview
        mappedMetadata = rawMetadata.applyMapping(importOrder);
        break; // Exit loop and continue to preview
      }

      if (!mounted) return;

      debugPrint('>>> STEP 11: Navigating to preview screen...');
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ImportPreviewScreen(
            filePath: filePath,
            metadata: mappedMetadata!,
          ),
        ),
      );

      debugPrint('>>> STEP 12: Preview result: $confirmed');
      if (confirmed != true || !mounted) return;

      debugPrint('>>> STEP 13: Showing name input dialog...');
      final name = await _showNameInputDialog(context, mappedMetadata.fileName, lang);
      debugPrint('>>> STEP 14: Name input result: $name');
      if (name == null || name.isEmpty || !mounted) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(lang == 'id' ? 'Menyimpan dataset...' : 'Saving dataset...'),
                ),
              ],
            ),
          ),
        );
      }

      debugPrint('>>> STEP 15: Importing deck...');
      final deckProvider = context.read<DeckProvider>();
      final deck = await deckProvider.importDeckFromFileBytes(
        fileBytes,
        name,
        fileName: fileName,
        targetSheetName: targetSheetName,
        importOrder: importOrder,
      );

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
      }

      debugPrint('>>> STEP 15: Deck imported: ${deck?.name}');
      if (deck != null && mounted) {
        await deckProvider.addDeck(deck);
        debugPrint('>>> STEP 16: Deck added to provider');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'id' ? 'Dataset berhasil diimpor!' : 'Dataset imported successfully!',
              ),
            ),
          );
        }
        // Update selected dataset
        if (mounted) {
          setState(() {
            _selectedDataset = deckProvider.decks.isNotEmpty ? deckProvider.decks.last : null;
          });
          debugPrint('>>> STEP 17: UI updated');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('>>> !!! ERROR OCCURRED !!!');
      debugPrint('>>> Error type: ${e.runtimeType}');
      debugPrint('>>> Error message: $e');
      debugPrint('>>> Stack trace:\n$stackTrace');
      debugPrint('>>> !!! END ERROR !!!');
      if (mounted) {
        // Just in case loading dialog is still open
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showNameInputDialog(
      BuildContext context, String defaultName, String lang) async {
    final controller = TextEditingController(text: defaultName);

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(lang == 'id' ? 'Nama Dataset' : 'Dataset Name'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: lang == 'id' ? 'Masukkan nama dataset' : 'Enter dataset name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cancel(lang)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(AppStrings.save(lang)),
            ),
          ],
        ),
      );

      return result;
    } finally {
      Future.delayed(const Duration(milliseconds: 400), () {
        controller.dispose();
      });
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _SettingsDialog(
        themeProvider: context.read<ThemeProvider>(),
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  final ThemeProvider themeProvider;

  const _SettingsDialog({required this.themeProvider});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late String selectedPlatform;
  late TextEditingController fontSize1Controller;
  late TextEditingController fontSize2_5Controller;
  late TextEditingController fontSize6_9Controller;
  late TextEditingController fontSize10_12Controller;

  @override
  void initState() {
    super.initState();
    final fontSizeSettings = widget.themeProvider.fontSizeSettings;
    selectedPlatform = FontSizeSettings.isMobilePlatform() ? 'Mobile/HP' : 'PC/Desktop';
    fontSize1Controller = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentFontSize1),
    );
    fontSize2_5Controller = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentFontSize2_5),
    );
    fontSize6_9Controller = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentFontSize6_9),
    );
    fontSize10_12Controller = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentFontSize10_12),
    );
  }

  String _formatFontSize(double size) {
    if (size == size.toInt()) {
      return size.toInt().toString();
    }
    return size.toString();
  }

  double _parseFontSize(String input, double fallback) {
    final intValue = int.tryParse(input);
    if (intValue != null) return intValue.toDouble();
    return double.tryParse(input) ?? fallback;
  }

  @override
  void dispose() {
    fontSize1Controller.dispose();
    fontSize2_5Controller.dispose();
    fontSize6_9Controller.dispose();
    fontSize10_12Controller.dispose();
    super.dispose();
  }

  void updateControllersFromPlatform(String platform) {
    final fontSizeSettings = widget.themeProvider.fontSizeSettings;
    setState(() {
      selectedPlatform = platform;
      if (platform == 'Mobile/HP') {
        fontSize1Controller.text = _formatFontSize(fontSizeSettings.mobileFontSize1);
        fontSize2_5Controller.text = _formatFontSize(fontSizeSettings.mobileFontSize2_5);
        fontSize6_9Controller.text = _formatFontSize(fontSizeSettings.mobileFontSize6_9);
        fontSize10_12Controller.text = _formatFontSize(fontSizeSettings.mobileFontSize10_12);
      } else {
        fontSize1Controller.text = _formatFontSize(fontSizeSettings.pcFontSize1);
        fontSize2_5Controller.text = _formatFontSize(fontSizeSettings.pcFontSize2_5);
        fontSize6_9Controller.text = _formatFontSize(fontSizeSettings.pcFontSize6_9);
        fontSize10_12Controller.text = _formatFontSize(fontSizeSettings.pcFontSize10_12);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProv = context.watch<LanguageProvider>();
    final lang = langProv.currentLanguage;

    return AlertDialog(
      title: Text(AppStrings.settingsTitle(lang)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode
            Consumer<ThemeProvider>(
              builder: (context, themeProv, child) {
                return SwitchListTile(
                  title: Text(AppStrings.darkMode(lang)),
                  subtitle: Text(AppStrings.darkModeSubtitle(lang)),
                  value: themeProv.isDarkMode,
                  onChanged: (value) {
                    themeProv.toggleTheme();
                  },
                );
              },
            ),

            const Divider(height: 24),

            // Font Size Settings
            Text(
              AppStrings.fontSizeSettings(lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Platform Dropdown
            Row(
              children: [
                Text(AppStrings.platform(lang)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedPlatform,
                  items: const [
                    DropdownMenuItem(
                      value: 'PC/Desktop',
                      child: Text('PC/Desktop'),
                    ),
                    DropdownMenuItem(
                      value: 'Mobile/HP',
                      child: Text('Mobile/HP'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      updateControllersFromPlatform(value);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Font Size Inputs
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: fontSize1Controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      labelText: AppStrings.col1(lang),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fontSize2_5Controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      labelText: AppStrings.col2_5(lang),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fontSize6_9Controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      labelText: AppStrings.col6_9(lang),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fontSize10_12Controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: InputDecoration(
                      labelText: AppStrings.col10_12(lang),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Manage Files / Datasets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.manageFiles(lang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.manageFilesSubtitle(lang),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showManageFilesDialog(context),
                  icon: const Icon(Icons.folder_shared_rounded, size: 16),
                  label: Text(AppStrings.manageFilesButton(lang), style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // === Language Switch (Antara Manage Files dan Export Data) ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.language(lang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.languageSubtitle(lang),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: langProv.currentLanguage,
                  borderRadius: BorderRadius.circular(8),
                  items: const [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English 🇺🇸'),
                    ),
                    DropdownMenuItem(
                      value: 'id',
                      child: Text('Indonesia 🇮🇩'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      langProv.setLanguage(value);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Export Settings
            Text(
              AppStrings.exportData(lang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<DeckProvider>(
              builder: (context, deckProvider, child) {
                if (deckProvider.decks.isEmpty) {
                  return Text(AppStrings.noDeckToExport(lang));
                }
                return _ExportDeckWidget(decks: deckProvider.decks);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel(lang)),
        ),
        ElevatedButton(
          onPressed: () async {
            final fontSizeSettings = widget.themeProvider.fontSizeSettings;

            final newSize1 = _parseFontSize(fontSize1Controller.text, 40.0);
            final newSize2_5 = _parseFontSize(fontSize2_5Controller.text, 16.0);
            final newSize6_9 = _parseFontSize(fontSize6_9Controller.text, 13.0);
            final newSize10_12 = _parseFontSize(fontSize10_12Controller.text, 11.0);

            if (newSize1 <= 0 || newSize2_5 <= 0 || newSize6_9 <= 0 || newSize10_12 <= 0) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.fontSizeError(lang)),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            FontSizeSettings updatedSettings;
            if (selectedPlatform == 'Mobile/HP') {
              updatedSettings = fontSizeSettings.copyWith(
                mobileFontSize1: newSize1,
                mobileFontSize2_5: newSize2_5,
                mobileFontSize6_9: newSize6_9,
                mobileFontSize10_12: newSize10_12,
              );
            } else {
              updatedSettings = fontSizeSettings.copyWith(
                pcFontSize1: newSize1,
                pcFontSize2_5: newSize2_5,
                pcFontSize6_9: newSize6_9,
                pcFontSize10_12: newSize10_12,
              );
            }

            await widget.themeProvider.updateFontSizeSettings(updatedSettings);

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(AppStrings.save(lang)),
        ),
      ],
    );
  }

  void _showManageFilesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => const _ManageFilesDialog(),
    );
  }
}

class _ManageFilesDialog extends StatelessWidget {
  const _ManageFilesDialog();

  void _showRenameDialog(BuildContext context, Deck deck) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final controller = TextEditingController(text: deck.name);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Flexible(child: Text(lang == 'id' ? 'Ubah Nama File / Dataset' : 'Rename File / Dataset')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'id' ? 'Masukkan nama baru untuk dataset ini:' : 'Enter a new name for this dataset:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                labelText: lang == 'id' ? 'Nama Dataset' : 'Dataset Name',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(AppStrings.cancel(lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != deck.name) {
                final provider = context.read<DeckProvider>();
                await provider.renameDeck(deck.id, newName);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'id'
                            ? 'Nama dataset berhasil diubah menjadi "$newName"'
                            : 'Dataset name changed to "$newName" successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                Navigator.pop(dialogCtx);
              }
            },
            child: Text(AppStrings.save(lang)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Deck deck) {
    final lang = context.read<LanguageProvider>().currentLanguage;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Flexible(child: Text(lang == 'id' ? 'Hapus Dataset' : 'Delete Dataset')),
          ],
        ),
        content: Text(
          lang == 'id'
              ? 'Yakin ingin menghapus file/dataset "${deck.name}"?\n\nSeluruh ${deck.totalCards} kartu dalam dataset ini akan dihapus dari aplikasi.'
              : 'Are you sure you want to delete file/dataset "${deck.name}"?\n\nAll ${deck.totalCards} cards in this dataset will be deleted from the application.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(AppStrings.cancel(lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<DeckProvider>();
              await provider.deleteDeck(deck.id);
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang == 'id'
                          ? 'Dataset "${deck.name}" berhasil dihapus'
                          : 'Dataset "${deck.name}" deleted successfully',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppStrings.delete(lang), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_shared_rounded, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              AppStrings.manageFiles(lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width.clamp(320.0, 520.0),
        child: Consumer<DeckProvider>(
          builder: (context, provider, child) {
            final decks = provider.decks;
            if (decks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(lang == 'id' ? 'Belum ada dataset yang diimpor.' : 'No datasets imported yet.'),
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: decks.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  final isCustom = deck.id == 'custom_mode_deck_default';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isCustom
                          ? Colors.purple.withValues(alpha: 0.15)
                          : Colors.blue.withValues(alpha: 0.15),
                      child: Icon(
                        isCustom ? Icons.edit_calendar_rounded : Icons.description_rounded,
                        color: isCustom ? Colors.purple : Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      deck.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      softWrap: true,
                      maxLines: 2,
                    ),
                    subtitle: Text(
                      lang == 'id'
                          ? '${deck.totalCards} kartu • ${deck.columnCount} kolom'
                          : '${deck.totalCards} cards • ${deck.columnCount} columns',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                          tooltip: lang == 'id' ? 'Ubah Nama File' : 'Rename File',
                          onPressed: () => _showRenameDialog(context, deck),
                        ),
                        if (!isCustom)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            tooltip: lang == 'id' ? 'Hapus File' : 'Delete File',
                            onPressed: () => _showDeleteDialog(context, deck),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.close(lang)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ExportDeckWidget extends StatefulWidget {
  final List<Deck> decks;
  const _ExportDeckWidget({required this.decks});

  @override
  State<_ExportDeckWidget> createState() => _ExportDeckWidgetState();
}

class _ExportDeckWidgetState extends State<_ExportDeckWidget> {
  Deck? _selectedDeck;

  @override
  void initState() {
    super.initState();
    if (widget.decks.isNotEmpty) {
      _selectedDeck = widget.decks.first;
    }
  }

  Future<void> _exportDeck() async {
    if (_selectedDeck == null) return;
    
    // Show mapping dialog
    final result = await showDialog<ExportMappingResult>(
      context: context,
      builder: (context) => ExportMappingDialog(deck: _selectedDeck!),
    );

    if (result == null) return; // Canceled

    try {
      final bytes = await ExcelService.exportDeckToExcelBytes(_selectedDeck!, exportOrder: result.exportOrder);
      final fileName = result.fileName;

      if (Platform.isAndroid || Platform.isIOS) {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan File Excel',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: Uint8List.fromList(bytes),
        );
        if (savePath != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Berhasil diekspor: $fileName'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Windows / Desktop: Support both directory picker and saveFile dialog
        String? dir;
        try {
          dir = await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'Pilih Folder untuk Menyimpan File Excel',
          );
        } catch (_) {}

        if (dir != null) {
          final file = File('$dir/$fileName');
          await file.writeAsBytes(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Berhasil diekspor ke: ${file.path}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final savePath = await FilePicker.platform.saveFile(
            dialogTitle: 'Simpan File Excel',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['xlsx'],
            bytes: Uint8List.fromList(bytes),
          );
          if (savePath != null) {
            final file = File(savePath);
            if (!file.existsSync() || file.lengthSync() == 0) {
              await file.writeAsBytes(bytes);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Berhasil diekspor ke: $savePath'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<Deck>(
            isExpanded: true,
            value: _selectedDeck,
            items: widget.decks.map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text(d.name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedDeck = val);
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export'),
          onPressed: _exportDeck,
        ),
      ],
    );
  }
}
