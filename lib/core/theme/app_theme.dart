import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// App theme configuration matching modern corporate aesthetics
abstract class AppTheme {
  static ThemeData get lightTheme {
    final TextTheme baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }

  static ThemeData get darkTheme {
    const background = Color(0xFF0F172A);
    const surface = Color(0xFF1E293B);
    const border = Color(0xFF334155);
    final TextTheme baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      dividerColor: border,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF94A3B8),
        surface: surface,
        error: AppColors.danger,
        onSurface: Color(0xFFF1F5F9),
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF1F5F9),
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF1F5F9),
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: const Color(0xFFF1F5F9)),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: const Color(0xFF94A3B8)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: Color(0xFFF1F5F9),
        iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
      ),
    );
  }
}
