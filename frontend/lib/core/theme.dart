import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TeamUp visual identity, ported from the React mockup.
class AppTheme {
  /// Selectable accent colors (Theme Color screen). Name -> seed.
  static const Map<String, Color> themeColors = {
    'Indigo': Color(0xFF6366F1),
    'Blue': Color(0xFF3B82F6),
    'Emerald': Color(0xFF10B981),
    'Rose': Color(0xFFF43F5E),
    'Amber': Color(0xFFF59E0B),
    'Purple': Color(0xFF8B5CF6),
    'Cyan': Color(0xFF06B6D4),
    'Slate': Color(0xFF64748B),
  };

  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  static const Color primaryHover = Color(0xFF4F46E5);
  static const Color itemHoverBg = Color(0xFFEEF2FF);
  static const Color itemBorderHover = Color(0xFFC7D2FE);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);

  // Gradient used by avatars (indigo-400 -> purple-500).
  static const List<Color> avatarGradient = [Color(0xFF818CF8), Color(0xFFA855F7)];

  /// Returns (background, foreground) colors for a post/notification type badge.
  static (Color, Color) typeColors(String type) {
    switch (type) {
      case 'project_launch': return (Color(0xFFE0E7FF), Color(0xFF4F46E5));
      case 'team_update':    return (Color(0xFFD1FAE5), Color(0xFF059669));
      case 'looking_for':    return (Color(0xFFFEF3C7), Color(0xFFD97706));
      case 'milestone':      return (Color(0xFFF3E8FF), Color(0xFF9333EA));
      case 'team_join':      return (Color(0xFFD1FAE5), Color(0xFF059669));
      case 'message':        return (Color(0xFFD1FAE5), Color(0xFF059669));
      case 'application':    return (Color(0xFFE0E7FF), Color(0xFF4F46E5));
      case 'project_update': return (Color(0xFFFEF3C7), Color(0xFFD97706));
      case 'mention':        return (Color(0xFFF3E8FF), Color(0xFF9333EA));
      default:               return (Color(0xFFF1F5F9), Color(0xFF475569));
    }
  }

  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      useMaterial3: true,
    );

    final bodyFont = GoogleFonts.ibmPlexSansTextTheme(base.textTheme);
    final headingFont = GoogleFonts.outfitTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: bodyFont.copyWith(
        displayLarge: headingFont.displayLarge,
        displayMedium: headingFont.displayMedium,
        displaySmall: headingFont.displaySmall,
        headlineLarge: headingFont.headlineLarge,
        headlineMedium: headingFont.headlineMedium,
        headlineSmall: headingFont.headlineSmall,
        titleLarge: headingFont.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: headingFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
