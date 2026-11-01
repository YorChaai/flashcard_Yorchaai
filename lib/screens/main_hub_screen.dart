import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard_app_mode.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_strings.dart';
import 'home_screen.dart';

/// Layar pembuka (Launcher Hub) untuk memilih antara:
/// 1. Flashcard Language (Belajar bahasa & Latihan Menulis)
/// 2. Flashcard All (Flashcard serbaguna / umum)
class MainHubScreen extends StatelessWidget {
  const MainHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProv = context.watch<LanguageProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final lang = langProv.currentLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Kontrol Global di Kanan Atas (Ganti Bahasa & Dark Mode)
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageToggle(context, langProv, lang, isDark),
                  const SizedBox(width: 8),
                  _buildThemeToggle(context, themeProv, isDark),
                ],
              ),
            ),

            // Konten Tengah
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeaderLogo(context, lang, isDark),
                      const SizedBox(height: 40),

                      // Card 1: Flashcard Language
                      _ModeSelectCard(
                        title: AppStrings.modeLanguageTitle(lang),
                        icon: Icons.translate_rounded,
                        accentColor: const Color(0xFF4F46E5),
                        onTap: () => _selectMode(context, FlashcardAppMode.language),
                      ),

                      const SizedBox(height: 18),

                      // Card 2: Flashcard All
                      _ModeSelectCard(
                        title: AppStrings.modeAllTitle(lang),
                        icon: Icons.school_rounded,
                        accentColor: const Color(0xFF0D9488),
                        onTap: () => _selectMode(context, FlashcardAppMode.all),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        'v2.0 • YorFlashCard Workspace',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectMode(BuildContext context, FlashcardAppMode mode) async {
    final deckProvider = context.read<DeckProvider>();
    final langProv = context.read<LanguageProvider>();
    final themeProv = context.read<ThemeProvider>();

    await langProv.setAppMode(mode);
    await themeProv.setAppMode(mode);
    await deckProvider.setMode(mode);

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Widget _buildLanguageToggle(
    BuildContext context,
    LanguageProvider langProv,
    String lang,
    bool isDark,
  ) {
    final isIndo = lang == 'id';
    return InkWell(
      onTap: () {
        langProv.setLanguageForBothModes(isIndo ? 'en' : 'id');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 16,
              color: isDark ? Colors.white70 : const Color(0xFF4A90E2),
            ),
            const SizedBox(width: 6),
            Text(
              isIndo ? 'ID' : 'EN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    ThemeProvider themeProv,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => themeProv.setThemeModeForBothModes(isDark ? ThemeMode.light : ThemeMode.dark),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 16,
              color: isDark ? Colors.amber : const Color(0xFFE67E22),
            ),
            const SizedBox(width: 6),
            Text(
              isDark ? 'Dark' : 'Light',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLogo(BuildContext context, String lang, bool isDark) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'asset/logo/logoapp.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Theme.of(context).primaryColor,
                child: const Icon(Icons.style, color: Colors.white, size: 44),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'YORFLASHCARD',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.hubSubtitle(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _ModeSelectCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeSelectCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ModeSelectCard> createState() => _ModeSelectCardState();
}

class _ModeSelectCardState extends State<_ModeSelectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(width: 18),

                // Title Only - Clean, Large & Never Wraps
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // Arrow Forward
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: widget.accentColor.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
