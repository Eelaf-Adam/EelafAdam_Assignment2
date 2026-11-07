import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours used across the whole app (based on the Rapport UI inspiration).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF00122B); // deep navy
  static const Color card = Color(0xFF262626); // dark grey cards
  static const Color accent = Color(0xFF1EB6F0); // cyan / sky blue
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8C4); // soft grey
}

/// The app-wide theme: dark navy background, cyan accent, Poppins font.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      // Poppins becomes the default font for every Text in the app.
      fontFamily: GoogleFonts.poppins().fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
        primary: AppColors.accent,
        surface: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.card,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
