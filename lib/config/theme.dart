import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppColors — Single source of truth for every color in the app
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // ── Dark Palette ──────────────────────────────────────────────────────────
  static const Color darkBg         = Color(0xFF0B0B14);
  static const Color darkSurface    = Color(0xFF13132A);
  static const Color darkSurfaceAlt = Color(0xFF1C1C3A);
  static const Color darkCard       = Color(0x1AFFFFFF);
  static const Color darkBorder     = Color(0xFF2A2A4A);
  static const Color darkTextPrimary   = Color(0xFFF1F1F8);
  static const Color darkTextSecondary = Color(0xFF9B9BB8);
  static const Color darkTextTertiary  = Color(0xFF64648A);
  static const Color darkShimmerBase      = Color(0xFF1C1C3A);
  static const Color darkShimmerHighlight = Color(0xFF2A2A4A);

  // ── Light Palette ─────────────────────────────────────────────────────────
  static const Color lightBg         = Color(0xFFF7F7FC);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF0F0F8);
  static const Color lightCard       = Color(0x0D000000);
  static const Color lightBorder     = Color(0xFFE2E2EF);
  static const Color lightTextPrimary   = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B8A);
  static const Color lightTextTertiary  = Color(0xFF9B9BB8);
  static const Color lightShimmerBase      = Color(0xFFEEEEF4);
  static const Color lightShimmerHighlight = Color(0xFFF5F5FB);

  // ── Accent Palette (shared) ───────────────────────────────────────────────
  static const Color accent       = Color(0xFF7C3AED);
  static const Color accentLight  = Color(0xFF9F67FF);
  static const Color accentDark   = Color(0xFF5B21B6);
  static const Color accentMuted  = Color(0x337C3AED);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ── Tag Colors ────────────────────────────────────────────────────────────
  static const Map<String, Color> tagColors = {
    'notes':      Color(0xFF3B82F6),
    'pyq':        Color(0xFFF59E0B),
    'slides':     Color(0xFF10B981),
    'links':      Color(0xFF8B5CF6),
    'important':  Color(0xFFEF4444),
    'assignment': Color(0xFFEC4899),
    'lab':        Color(0xFF06B6D4),
    'other':      Color(0xFF6B7280),
  };

  static Color getTagColor(String tag) =>
      tagColors[tag.toLowerCase()] ?? tagColors['other']!;

  /// Generate a unique accent color for a given string (class name, etc.)
  static Color hashColor(String text) {
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
    ];
    return colors[text.hashCode.abs() % colors.length];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AppTheme — ThemeData builders + design tokens
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ── Design Tokens ─────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  static const Duration animFast   = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow   = Duration(milliseconds: 600);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.accent, AppColors.accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [AppColors.darkBg, AppColors.darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [AppColors.lightBg, AppColors.lightSurfaceAlt],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> glowShadow({Color? color}) => [
        BoxShadow(
          color: (color ?? AppColors.accent).withOpacity(0.35),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Glass Decoration ──────────────────────────────────────────────────────
  static BoxDecoration glassDecoration({
    required Brightness brightness,
    double borderRadius = radiusLg,
    Color? color,
  }) {
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.darkCard : AppColors.lightCard),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
            .withOpacity(0.5),
        width: 1,
      ),
    );
  }

  // ── Background gradient for current brightness ────────────────────────────
  static LinearGradient bgGradient(Brightness brightness) =>
      brightness == Brightness.dark ? darkGradient : lightGradient;

  // ── Color helpers that resolve to current brightness ──────────────────────
  static Color bg(Brightness b)           => b == Brightness.dark ? AppColors.darkBg : AppColors.lightBg;
  static Color surface(Brightness b)      => b == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface;
  static Color surfaceAlt(Brightness b)   => b == Brightness.dark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
  static Color card(Brightness b)         => b == Brightness.dark ? AppColors.darkCard : AppColors.lightCard;
  static Color border(Brightness b)       => b == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder;
  static Color textPrimary(Brightness b)  => b == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  static Color textSecondary(Brightness b)=> b == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  static Color textTertiary(Brightness b) => b == Brightness.dark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

  // ═══════════════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD THEME — shared logic
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bgColor  = bg(brightness);
    final surfColor = surface(brightness);
    final altColor  = surfaceAlt(brightness);
    final borderColor   = border(brightness);
    final textP    = textPrimary(brightness);
    final textS    = textSecondary(brightness);
    final textT    = textTertiary(brightness);

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      primaryColor: AppColors.accent,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentLight,
        onSecondary: Colors.white,
        surface: surfColor,
        onSurface: textP,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 34, fontWeight: FontWeight.w700, color: textP, letterSpacing: -1.2,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28, fontWeight: FontWeight.w700, color: textP, letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 24, fontWeight: FontWeight.w600, color: textP,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 20, fontWeight: FontWeight.w600, color: textP,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textP,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: textP,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w400, color: textP,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: textS,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: textT,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: textP,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: textS,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20, fontWeight: FontWeight.w600, color: textP,
        ),
        iconTheme: IconThemeData(color: textP),
      ),
      cardTheme: CardThemeData(
        color: surfColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: altColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: textT, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textS, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfColor,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: textT,
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: altColor,
        contentTextStyle: GoogleFonts.inter(color: textP, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: altColor,
        selectedColor: AppColors.accent.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        side: BorderSide(color: borderColor),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accent,
        unselectedLabelColor: textT,
        indicatorColor: AppColors.accent,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
    );
  }
}
