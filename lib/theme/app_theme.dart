import 'package:flutter/material.dart';

class AppColors {
  // Dark backgrounds
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF141420);
  static const card = Color(0xFF1C1C2E);
  static const cardAlt = Color(0xFF1E1E30);

  // Light backgrounds
  static const lightBackground = Color(0xFFF7F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardAlt = Color(0xFFF1F1F7);
  static const lightBorder = Color(0xFFE5E7EB);

  // Brand
  static const primary = Color(0xFF7C3AED);   // violet (slightly deeper for light contrast)
  static const primaryDark = Color(0xFF6D28D9);
  static const primaryLight = Color(0xFFA78BFA);
  static const accent = Color(0xFFF59E0B);     // amber
  static const accentGreen = Color(0xFF10B981); // emerald
  static const accentRed = Color(0xFFEF4444);
  static const accentBlue = Color(0xFF3B82F6);

  // Dark text
  static const textPrimary = Color(0xFFF8F8FF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF4B5563);

  // Light text
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF475569);
  static const lightTextMuted = Color(0xFF94A3B8);

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
  // iOS: SF Pro (system). Android: Roboto Flex fallback via system.
  static const String _fontFamily = '.SF Pro Display';
  static const String _fontFamilyFallback = 'SF Pro Display';

  /// Typography scale — bumped up one step across the board for readability.
  /// Line heights and letter spacing tuned to feel like a premium modern app.
  static TextTheme _buildTextTheme(Color bodyColor, Color displayColor) {
    return TextTheme(
      // Display — hero numbers, onboarding headlines
      displayLarge: TextStyle(
        fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.0,
        height: 1.1, color: displayColor,
      ),
      displayMedium: TextStyle(
        fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8,
        height: 1.12, color: displayColor,
      ),
      displaySmall: TextStyle(
        fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.6,
        height: 1.15, color: displayColor,
      ),
      // Headlines — screen titles
      headlineLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        height: 1.2, color: displayColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4,
        height: 1.25, color: displayColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3,
        height: 1.3, color: displayColor,
      ),
      // Titles — section headers, cards
      titleLarge: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2,
        height: 1.3, color: displayColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.1,
        height: 1.35, color: displayColor,
      ),
      titleSmall: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0,
        height: 1.4, color: displayColor,
      ),
      // Body — main reading text
      bodyLarge: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0.1,
        height: 1.5, color: bodyColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.1,
        height: 1.5, color: bodyColor,
      ),
      bodySmall: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.15,
        height: 1.45, color: bodyColor,
      ),
      // Labels — buttons, chips, captions
      labelLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1,
        height: 1.3, color: bodyColor,
      ),
      labelMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2,
        height: 1.3, color: bodyColor,
      ),
      labelSmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.3,
        height: 1.3, color: bodyColor,
      ),
    ).apply(
      fontFamily: _fontFamily,
      fontFamilyFallback: const [_fontFamilyFallback, 'Roboto'],
    );
  }

  static ThemeData get light {
    final textTheme = _buildTextTheme(
      AppColors.lightTextPrimary,
      AppColors.lightTextPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      fontFamilyFallback: const [_fontFamilyFallback, 'Roboto'],
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightCardAlt,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        onPrimary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: const [_fontFamilyFallback, 'Roboto'],
          color: AppColors.lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCardAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        labelStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextMuted,
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextMuted,
        selectedLabelStyle:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final textTheme = _buildTextTheme(
      AppColors.textPrimary,
      AppColors.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      fontFamilyFallback: const [_fontFamilyFallback, 'Roboto'],
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.cardAlt,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        outline: AppColors.textMuted,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: const [_fontFamilyFallback, 'Roboto'],
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A3E),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.textMuted, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.textMuted, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
        selectedLabelStyle:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
