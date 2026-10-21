import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF24574C);
  static const clay = Color(0xFF8F4F2B);
  static const amber = Color(0xFFF1B85B);
  static const parchment = Color(0xFFFAF7F0);
  static const ink = Color(0xFF25312B);
  static const muted = Color(0xFF64716B);
  static const softGreen = Color(0xFFE7EFE8);
  static const paleGreen = Color(0xFFF0F3ED);
  static const border = Color(0xFFDFE5DE);
  static const chevron = Color(0xFF909891);
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.forest,
          surface: AppColors.parchment,
        ).copyWith(
          primary: AppColors.forest,
          onPrimary: Colors.white,
          secondary: AppColors.clay,
          onSecondary: Colors.white,
          surface: AppColors.parchment,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.muted,
          primaryContainer: AppColors.softGreen,
          onPrimaryContainer: AppColors.forest,
          secondaryContainer: const Color(0xFFF4E8DC),
          outline: AppColors.border,
          surfaceContainerLowest: Colors.white,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
        ),
      ),
    );
  }
}
