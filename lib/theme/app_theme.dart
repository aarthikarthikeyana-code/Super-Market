import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep forest dark green theme
  static const Color background = Color(0xFF09120D);
  static const Color backgroundCard = Color(0xFF132219);
  static const Color surface = Color(0xFF16281D);
  static const Color surfaceLight = Color(0xFF1F382A);
  static const Color surfaceBorder = Color(0xFF244431);
  static const Color surfaceBorderLight = Color(0xFF335C43);

  // Vibrant Emerald Green
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryGreenLight = Color(0xFF34D399);
  static const Color primaryGreenDark = Color(0xFF059669);

  // Warm Peach / Coral CTA Accent
  static const Color accentCoral = Color(0xFFEB7A5D);
  static const Color accentCoralDark = Color(0xFFD66447);
  static const Color accentCoralLight = Color(0xFFF3967C);

  // Elegant Gold / Champagne
  static const Color goldAccent = Color(0xFFE9D5A1);
  static const Color goldMuted = Color(0xFFC7B682);

  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textGreen = Color(0xFF6EE7B7);

  // Badges & Status
  static const Color badgeBg = Color(0x3310B981);
  static const Color badgeText = Color(0xFF34D399);
  static const Color outOfStockBg = Color(0x33EF4444);
  static const Color outOfStockText = Color(0xFFF87171);

  // Common Product Theme Tokens
  static const Color productCardBg = Color(0xFF132219);
  static const Color productImageBg = Color(0xFF182C20);
  static const Color productCardBorder = Color(0xFF244431);
  static const Color productCardBorderHover = Color(0xFF335C43);
  static const Color productChipActiveBg = Color(0xFF065F46);
  static const Color productChipActiveBorder = Color(0xFF10B981);
  static const Color productChipInactiveBg = Color(0xFF193023);
  static const Color productChipInactiveBorder = Color(0xFF244431);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F1E15),
      Color(0xFF08100C),
    ],
  );

  static const LinearGradient coralButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFF28567),
      Color(0xFFE56A49),
    ],
  );

  static const LinearGradient greenCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF182D21),
      Color(0xFF101F17),
    ],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B3626),
      Color(0xFF0E2016),
    ],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentCoral,
        surface: AppColors.surface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
    );
  }
}

