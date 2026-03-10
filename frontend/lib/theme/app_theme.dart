import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const beige     = Color(0xFFF0EBE3);
  static const cream     = Color(0xFFFAF7F2);
  static const sand      = Color(0xFFE2D9CC);
  static const stone     = Color(0xFFB0A698);
  static const charcoal  = Color(0xFF2E2B28);
  static const ink       = Color(0xFF1A1815);
  static const gray      = Color(0xFF8A8480);
  static const accent    = Color(0xFFC9B99A);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme.light(
        primary:    AppColors.ink,
        secondary:  AppColors.accent,
        surface:    AppColors.cream,
        onPrimary:  AppColors.cream,
        onSecondary: AppColors.ink,
        onSurface:  AppColors.charcoal,
      ),
      textTheme: TextTheme(
        // Display — Cormorant Garamond (títulos grandes)
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 64, fontWeight: FontWeight.w300,
          color: AppColors.ink, height: 1.0,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 48, fontWeight: FontWeight.w300,
          color: AppColors.ink, height: 1.05,
        ),
        displaySmall: GoogleFonts.cormorantGaramond(
          fontSize: 36, fontWeight: FontWeight.w300,
          color: AppColors.ink, height: 1.1,
        ),
        // Headline — Syne (nombres de producto, precio)
        headlineLarge: GoogleFonts.syne(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: AppColors.ink, letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.syne(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        headlineSmall: GoogleFonts.syne(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        // Body — DM Mono (UI, etiquetas)
        bodyLarge: GoogleFonts.dmMono(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: AppColors.charcoal,
        ),
        bodyMedium: GoogleFonts.dmMono(
          fontSize: 11, fontWeight: FontWeight.w300,
          color: AppColors.gray,
        ),
        bodySmall: GoogleFonts.dmMono(
          fontSize: 10, fontWeight: FontWeight.w300,
          color: AppColors.stone, letterSpacing: 0.12,
        ),
        labelLarge: GoogleFonts.dmMono(
          fontSize: 11, fontWeight: FontWeight.w400,
          color: AppColors.cream, letterSpacing: 0.15,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: AppColors.ink, letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.charcoal),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.cream,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.dmMono(
            fontSize: 11, letterSpacing: 0.15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          side: const BorderSide(color: AppColors.charcoal),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.dmMono(fontSize: 11, letterSpacing: 0.15),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.sand,
        thickness: 1,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.sand),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.sand),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.charcoal),
        ),
        hintStyle: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
