import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../models/deck.dart';
import '../models/font_size_settings.dart';
import '../services/excel_service.dart';
import 'deck_detail_screen.dart';
import 'import_preview_screen.dart';
import 'export_mapping_dialog.dart';
import 'sheet_selection_dialog.dart';
import 'import_mapping_dialog.dart';
import '../services/storage_service.dart';

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
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            size: 40,
                            color: Colors.white,
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
                          'Smart Learning App',
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
                            label: 'Datasets',
                          ),
                          _StatCard(
                            icon: Icons.view_carousel,
                            value: '$totalCards',
                            label: 'Total Cards',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dataset Selector
                  if (decks.isNotEmpty) ...[
                    Card(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: Theme.of(context).brightness == Brightness.dark
                            ? BorderSide(color: Colors.grey[700]!, width: 1)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Dataset',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Deck>(
                              isExpanded: true,
                              initialValue: _selectedDataset,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Theme.of(context).cardColor,
                              ),
                              items: decks.map((deck) {
                                return DropdownMenuItem(
                                  value: deck,
                                  child: Text(
                                    '${deck.name} (${deck.totalCards} cards)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedDataset = value;
                                  });
                                  StorageService().setLastSelectedDeckId(value.id);
                                }
                              },
                            ),
                            if (_selectedDataset != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Columns: ${_selectedDataset!.columnCount}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      deckProvider.selectDeck(_selectedDataset!);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const DeckDetailScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Edit'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Main Action Button
                  ElevatedButton.icon(
                    onPressed: decks.isNotEmpty
                        ? () {
                            if (_selectedDataset != null) {
                              deckProvider.selectDeck(_selectedDataset!);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DeckDetailScreen(),
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 24, color: Colors.white),
                    label: const Text(
                      'START LEARNING',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                      'IMPORT DATASET',
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
                      'SETTINGS',
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
                            'No datasets yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Import an Excel file to get started',
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
            const SnackBar(content: Text('Unable to read file. Please try again.')),
          );
        }
        return;
      }

      // Show loading dialog for initial processing
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text('Membaca file Excel...')),
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
            const SnackBar(content: Text('Gagal memperbaiki file. Harap "Save As" ke file baru atau simpan sebagai CSV.')),
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
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(child: Text('Membaca struktur sheet...')),
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
      final name = await _showNameInputDialog(context, mappedMetadata.fileName);
      debugPrint('>>> STEP 14: Name input result: $name');
      if (name == null || name.isEmpty || !mounted) return;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text('Menyimpan dataset...')),
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
            const SnackBar(content: Text('Dataset imported successfully!')),
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
      BuildContext context, String defaultName) async {
    final controller = TextEditingController(text: defaultName);

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dataset Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Enter dataset name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
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
  late TextEditingController fontSize23Controller;
  late TextEditingController fontSize45Controller;
  late TextEditingController fontSize6Controller;

  @override
  void initState() {
    super.initState();
    final fontSizeSettings = widget.themeProvider.fontSizeSettings;
    selectedPlatform = FontSizeSettings.isMobilePlatform() ? 'Mobile/HP' : 'PC/Desktop';
    fontSize1Controller = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentFontSize1),
    );
    fontSize23Controller = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentFontSize23),
    );
    fontSize45Controller = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentFontSize45),
    );
    fontSize6Controller = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentFontSize6),
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
    fontSize23Controller.dispose();
    fontSize45Controller.dispose();
    fontSize6Controller.dispose();
    super.dispose();
  }

  void updateControllersFromPlatform(String platform) {
    final fontSizeSettings = widget.themeProvider.fontSizeSettings;
    setState(() {
      selectedPlatform = platform;
      if (platform == 'Mobile/HP') {
        fontSize1Controller.text = _formatFontSize(fontSizeSettings.mobileFontSize1);
        fontSize23Controller.text = _formatFontSize(fontSizeSettings.mobileFontSize23);
        fontSize45Controller.text = _formatFontSize(fontSizeSettings.mobileFontSize45);
        fontSize6Controller.text = _formatFontSize(fontSizeSettings.mobileFontSize6);
      } else {
        fontSize1Controller.text = _formatFontSize(fontSizeSettings.pcFontSize1);
        fontSize23Controller.text = _formatFontSize(fontSizeSettings.pcFontSize23);
        fontSize45Controller.text = _formatFontSize(fontSizeSettings.pcFontSize45);
        fontSize6Controller.text = _formatFontSize(fontSizeSettings.pcFontSize6);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode
            Consumer<ThemeProvider>(
              builder: (context, themeProv, child) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle dark/light theme'),
                  value: themeProv.isDarkMode,
                  onChanged: (value) {
                    themeProv.toggleTheme();
                  },
                );
              },
            ),

            const Divider(height: 24),

            // Font Size Settings
            const Text(
              'Font Size Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Platform Dropdown
            Row(
              children: [
                const Text('Platform: '),
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
                    decoration: const InputDecoration(
                      labelText: 'Kolom 1 (Atas Tengah)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fontSize23Controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      labelText: 'Kolom 2 & 3',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fontSize45Controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      labelText: 'Kolom 4 & 5',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fontSize6Controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      labelText: 'Kolom 6 (Bawah)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            
            // Export Settings
            const Text(
              'Export Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<DeckProvider>(
              builder: (context, deckProvider, child) {
                if (deckProvider.decks.isEmpty) {
                  return const Text('Tidak ada deck untuk di-export.');
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final fontSizeSettings = widget.themeProvider.fontSizeSettings;

            final newSize1 = _parseFontSize(fontSize1Controller.text, 40.0);
            final newSize23 = _parseFontSize(fontSize23Controller.text, 16.0);
            final newSize45 = _parseFontSize(fontSize45Controller.text, 12.0);
            final newSize6 = _parseFontSize(fontSize6Controller.text, 12.0);

            if (newSize1 <= 0 || newSize23 <= 0 || newSize45 <= 0 || newSize6 <= 0) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Font size harus lebih dari 0'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            FontSizeSettings updatedSettings;
            if (selectedPlatform == 'Mobile/HP') {
              updatedSettings = fontSizeSettings.copyWith(
                mobileFontSize1: newSize1,
                mobileFontSize23: newSize23,
                mobileFontSize45: newSize45,
                mobileFontSize6: newSize6,
              );
            } else {
              updatedSettings = fontSizeSettings.copyWith(
                pcFontSize1: newSize1,
                pcFontSize23: newSize23,
                pcFontSize45: newSize45,
                pcFontSize6: newSize6,
              );
            }

            await widget.themeProvider.updateFontSizeSettings(updatedSettings);

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
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
    final exportOrder = await showDialog<List<int>>(
      context: context,
      builder: (context) => ExportMappingDialog(deck: _selectedDeck!),
    );

    if (exportOrder == null) return; // Canceled

    try {
      final bytes = await ExcelService.exportDeckToExcelBytes(_selectedDeck!, exportOrder: exportOrder);
      String? dir;
      try {
        dir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Directory to Save Excel File',
        );
      } catch (e) {
        // Fallback or ignore if platform doesn't support directory picker
      }
      
      if (dir != null) {
        final file = File('$dir/Export_${_selectedDeck!.name}.xlsx');
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
        // Just standard saveFile if directory picker returns null or unsupported
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Excel File',
          fileName: 'Export_${_selectedDeck!.name}.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: Uint8List.fromList(bytes),
        );
        if (savePath != null) {
          final file = File(savePath);
          await file.writeAsBytes(bytes);
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
