import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic colors that vary by brightness. Accent-ish colors (hovers, item
/// highlights) are derived from the active seed so the chosen Theme Color
/// flows through the whole app. Registered on [ThemeData.extensions].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textMuted;
  final Color slate100; // subtle fills / dividers
  final Color slate200; // borders
  final Color primaryHover; // darker accent (selected text/icons)
  final Color itemHoverBg; // selected row background
  final Color itemBorderHover; // selected icon chip background

  const AppPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textMuted,
    required this.slate100,
    required this.slate200,
    required this.primaryHover,
    required this.itemHoverBg,
    required this.itemBorderHover,
  });

  factory AppPalette.from(Brightness brightness, Color seed) {
    final dark = brightness == Brightness.dark;
    return AppPalette(
      background: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      surface: dark ? const Color(0xFF1E293B) : Colors.white,
      textPrimary: dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      textMuted: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      slate100: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      slate200: dark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
      primaryHover: dark ? _lighten(seed, 0.08) : _darken(seed, 0.08),
      itemHoverBg: seed.withValues(alpha: dark ? 0.22 : 0.12),
      itemBorderHover: seed.withValues(alpha: dark ? 0.45 : 0.30),
    );
  }

  static Color _darken(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textMuted,
    Color? slate100,
    Color? slate200,
    Color? primaryHover,
    Color? itemHoverBg,
    Color? itemBorderHover,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      slate100: slate100 ?? this.slate100,
      slate200: slate200 ?? this.slate200,
      primaryHover: primaryHover ?? this.primaryHover,
      itemHoverBg: itemHoverBg ?? this.itemHoverBg,
      itemBorderHover: itemBorderHover ?? this.itemBorderHover,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      slate100: Color.lerp(slate100, other.slate100, t)!,
      slate200: Color.lerp(slate200, other.slate200, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      itemHoverBg: Color.lerp(itemHoverBg, other.itemHoverBg, t)!,
      itemBorderHover: Color.lerp(itemBorderHover, other.itemBorderHover, t)!,
    );
  }
}

/// Sugar so widgets read `context.palette.textMuted` etc.
extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Pushed routes fade in while sliding up a few pixels, and the outgoing
/// route fades out — a calm "modern app" page transition on every platform.
class _FadeSlideTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final inCurve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final outCurve = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic);
    return FadeTransition(
      opacity: inCurve,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.6).animate(outCurve),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
              .animate(inCurve),
          child: child,
        ),
      ),
    );
  }
}

/// TeamUp visual identity, ported from the React mockup.
class AppTheme {
  static const Color primary = Color(0xFF6366F1); // Indigo (default seed)
  static const Color background = Color(0xFFF8FAFC); // light default (legacy const refs)
  static const Color surface = Colors.white;

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

  // Gradient used by avatars (indigo-400 -> purple-500) — brand, fixed in both modes.
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

  /// Back-compat: the original light theme with the default indigo seed.
  static ThemeData get light => build(brightness: Brightness.light, seed: primary);

  static ThemeData build({required Brightness brightness, required Color seed}) {
    final palette = AppPalette.from(brightness, seed);
    final base = ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        primary: seed,
        brightness: brightness,
        surface: palette.surface,
      ),
      scaffoldBackgroundColor: palette.background,
      useMaterial3: true,
      extensions: [palette],
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _FadeSlideTransitionsBuilder(),
        TargetPlatform.iOS: _FadeSlideTransitionsBuilder(),
        TargetPlatform.windows: _FadeSlideTransitionsBuilder(),
        TargetPlatform.macOS: _FadeSlideTransitionsBuilder(),
        TargetPlatform.linux: _FadeSlideTransitionsBuilder(),
        TargetPlatform.fuchsia: _FadeSlideTransitionsBuilder(),
      }),
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
      ).apply(bodyColor: palette.textPrimary, displayColor: palette.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: seed, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.slate200),
        ),
      ),
    );
  }
}
