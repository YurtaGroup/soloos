import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF141420);
  static const card = Color(0xFF1C1C2E);
  static const cardAlt = Color(0xFF1E1E30);

  // Brand
  static const primary = Color(0xFF8B5CF6);   // violet
  static const primaryDark = Color(0xFF6D28D9);
  static const primaryLight = Color(0xFFA78BFA);
  static const accent = Color(0xFFF59E0B);     // amber
  static const accentGreen = Color(0xFF10B981); // emerald
  static const accentRed = Color(0xFFEF4444);
  static const accentBlue = Color(0xFF3B82F6);

  // Text
  static const textPrimary = Color(0xFFF8F8FF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF4B5563);

  // Gradients
  static const gradientStart = Color(0xFF7C3AED);
  static const gradientEnd = Color(0xFF2563EB);

  // Module colors
  static const workColor = Color(0xFF3B82F6);
  static const healthColor = Color(0xFF10B981);
  static const financeColor = Color(0xFFF59E0B);
  static const ideasColor = Color(0xFF8B5CF6);
  static const aiColor = Color(0xFFEC4899);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5FA),
      colorScheme: const ColorScheme.light(
        surface: Colors.white,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1C1C2E),
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF1C1C2E),
        displayColor: const Color(0xFF1C1C2E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5FA),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF1C1C2E)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1C2E),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEEEF4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: '.SF Pro Text', // iOS system font; Android falls back to Roboto
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textMuted, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textMuted, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
