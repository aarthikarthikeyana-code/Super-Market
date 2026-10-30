import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NummaCustomerColors {
  // Brand Palette
  static const Color darkGreen = Color(0xFF006B3C); // Main colour: Dark Grocery Green
  static const Color secondaryGreen = Color(0xFF07894F);
  static const Color lightGreen = Color(0xFFEAF7EE);
  static const Color creamBg = Color(0xFFFFF9EC); // Background Cream
  static const Color warmCream = Color(0xFFFFF1CF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color orangeAccent = Color(0xFFFF650F);
  static const Color yellowAccent = Color(0xFFFFBE35);
  static const Color errorRed = Color(0xFFE53935);
  static const Color darkText = Color(0xFF152019);
  static const Color secondaryText = Color(0xFF68736D);
  static const Color border = Color(0xFFE4E8E5);

  // Status & Accents
  static const Color success = Color(0xFF20A464);
  static const Color warning = Color(0xFFF5A623);
  static const Color blueProcessing = Color(0xFF4285F4);

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
}

class NummaCustomerTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: NummaCustomerColors.creamBg,
      primaryColor: NummaCustomerColors.darkGreen,
      colorScheme: const ColorScheme.light(
        primary: NummaCustomerColors.darkGreen,
        secondary: NummaCustomerColors.secondaryGreen,
        surface: NummaCustomerColors.white,
        background: NummaCustomerColors.creamBg,
        error: NummaCustomerColors.errorRed,
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: NummaCustomerColors.darkText,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: NummaCustomerColors.darkText,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NummaCustomerColors.darkText,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: NummaCustomerColors.darkText,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: NummaCustomerColors.secondaryText,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: NummaCustomerColors.darkText,
        ),
        iconTheme: const IconThemeData(color: NummaCustomerColors.darkGreen),
      ),
      cardTheme: CardThemeData(
        color: NummaCustomerColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NummaCustomerColors.border, width: 1),
        ),
      ),
    );
  }
}
