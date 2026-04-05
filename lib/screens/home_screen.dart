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
        setState(() {
          _selectedDataset = provider.decks.first;
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

      debugPrint('>>> STEP 8: Getting file metadata from bytes...');
      FileMetadata metadata;
      try {
        metadata = await ExcelService.getFileMetadataFromBytes(fileBytes, fileName);
      } catch (e) {
        debugPrint('>>> STEP 8 ERROR: Excel parsing failed. Trying fallback parser...');
        metadata = await ExcelService.getFileMetadataFallback(fileBytes, fileName);
      }

      debugPrint('>>> STEP 9: Metadata retrieved:');
      debugPrint('   - File: ${metadata.fileName}');
      debugPrint('   - Sheet: ${metadata.sheetName}');
      debugPrint('   - Columns: ${metadata.columnCount}');
      debugPrint('   - Total rows: ${metadata.totalRows}');

      if (!mounted) return;

      debugPrint('>>> STEP 10: Navigating to preview screen...');
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ImportPreviewScreen(
            filePath: filePath,
            metadata: metadata,
          ),
        ),
      );

      debugPrint('>>> STEP 11: Preview result: $confirmed');
      if (confirmed != true || !mounted) return;

      debugPrint('>>> STEP 12: Showing name input dialog...');
      final name = await _showNameInputDialog(context, metadata.fileName);
      debugPrint('>>> STEP 13: Name input result: $name');
      if (name == null || name.isEmpty || !mounted) return;

      debugPrint('>>> STEP 14: Importing deck...');
      final deckProvider = context.read<DeckProvider>();
      final deck = await deckProvider.importDeckFromFileBytes(
        fileBytes,
        name,
        fileName: fileName,
      );

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
      controller.dispose();
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
  late TextEditingController mainFontSizeController;
  late TextEditingController subFontSizeController;

  @override
  void initState() {
    super.initState();
    final fontSizeSettings = widget.themeProvider.fontSizeSettings;
    selectedPlatform = FontSizeSettings.isMobilePlatform() ? 'Mobile/HP' : 'PC/Desktop';
    mainFontSizeController = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentMainFontSize),
    );
    subFontSizeController = TextEditingController(
      text: _formatFontSize(fontSizeSettings.currentSubFontSize),
    );
  }

  String _formatFontSize(double size) {
    // Remove .0 for integer values
    if (size == size.toInt()) {
      return size.toInt().toString();
    }
    return size.toString();
  }

  double _parseFontSize(String input) {
    // Try parsing as int first, then as double
    final intValue = int.tryParse(input);
    if (intValue != null) return intValue.toDouble();
    return double.tryParse(input) ?? 40.0;
  }

  @override
  void dispose() {
    mainFontSizeController.dispose();
    subFontSizeController.dispose();
    super.dispose();
  }

  void updateControllersFromPlatform(String platform) {
    final fontSizeSettings = widget.themeProvider.fontSizeSettings;
    setState(() {
      selectedPlatform = platform;
      if (platform == 'Mobile/HP') {
        mainFontSizeController.text = _formatFontSize(fontSizeSettings.mobileMainFontSize);
        subFontSizeController.text = _formatFontSize(fontSizeSettings.mobileSubFontSize);
      } else {
        mainFontSizeController.text = _formatFontSize(fontSizeSettings.pcMainFontSize);
        subFontSizeController.text = _formatFontSize(fontSizeSettings.pcSubFontSize);
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
                    controller: mainFontSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Main Column (Kolom 1)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subFontSizeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Sub Columns (Kolom 2-6)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
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

            // Parse font sizes - support both int and float input
            final newMainFontSize = _parseFontSize(mainFontSizeController.text);
            final newSubFontSize = _parseFontSize(subFontSizeController.text);

            // Validate
            if (newMainFontSize <= 0 || newSubFontSize <= 0) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Font size harus lebih dari 0'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Update settings based on selected platform
            FontSizeSettings updatedSettings;
            if (selectedPlatform == 'Mobile/HP') {
              updatedSettings = fontSizeSettings.copyWith(
                mobileMainFontSize: newMainFontSize,
                mobileSubFontSize: newSubFontSize,
              );
            } else {
              updatedSettings = fontSizeSettings.copyWith(
                pcMainFontSize: newMainFontSize,
                pcSubFontSize: newSubFontSize,
              );
            }

            // Save
            await widget.themeProvider.updateFontSizeSettings(updatedSettings);

            // Close dialog if still mounted
            if (mounted) {
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
