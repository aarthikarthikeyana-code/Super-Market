import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NummaColors {
  // Brand Greens
  static const Color primaryGreen = Color(0xFF087A46);
  static const Color darkGreen = Color(0xFF075C38);
  static const Color lightGreen = Color(0xFFEAF7EF);
  static const Color lightGreenCard = Color(0xFFF1FAF4);

  // Background & Surfaces
  static const Color creamBg = Color(0xFFFFF9ED);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Grocery Accents
  static const Color orangeAccent = Color(0xFFFF9D21);
  static const Color yellowAccent = Color(0xFFFFC83D);

  // Status Colors
  static const Color success = Color(0xFF20A464);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE84C4C);
  static const Color blueProcessing = Color(0xFF4285F4);

  // Text Hierarchy
  static const Color textMain = Color(0xFF18212F);
  static const Color textSecondary = Color(0xFF687385);
  static const Color textMuted = Color(0xFF9AA4B2);

  // Borders & Dividers
  static const Color border = Color(0xFFE7E9ED);
  static const Color borderLight = Color(0xFFF0F2F5);

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF18212F).withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryGreen.withOpacity(0.25),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
}

class NummaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NummaColors.creamBg,
      primaryColor: NummaColors.primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: NummaColors.primaryGreen,
        secondary: NummaColors.orangeAccent,
        surface: NummaColors.white,
        background: NummaColors.creamBg,
        error: NummaColors.error,
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: NummaColors.textMain,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: NummaColors.textMain,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NummaColors.textMain,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: NummaColors.textMain,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: NummaColors.textSecondary,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: NummaColors.textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: NummaColors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: NummaColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NummaColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NummaColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NummaColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NummaColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NummaColors.primaryGreen, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: NummaColors.textMuted,
        ),
      ),
    );
  }
}

