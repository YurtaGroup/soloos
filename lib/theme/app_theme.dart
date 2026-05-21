// lib/theme/app_theme.dart
//
// Quiet OS — Week 1 rebrand.
// Builds Material 3 ThemeData from the design-system tokens.
//
// BACKWARD COMPAT: existing screens import AppColors + AppTheme from this
// file. Both classes are preserved. AppColors retains its old static names
// so callers compile without modification. New code should use QColors
// (app_colors.dart) instead of AppColors.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';
import 'text_styles.dart';

// ---------------------------------------------------------------------------
// AppColors — legacy surface. Kept for backward compat with existing screens.
// Maps old violet-primary brand to the new ink/lime token set.
// New atoms and screens should use QColors.of(context) instead.
// ---------------------------------------------------------------------------

class AppColors {
  // ---- Dark backgrounds (legacy names) ------------------------------------
  static const background     = ColorTokens.night950;
  static const surface        = ColorTokens.night900;
  static const card           = ColorTokens.night900;
  static const cardAlt        = ColorTokens.night800;

  // ---- Light backgrounds (legacy names) ------------------------------------
  static const lightBackground = ColorTokens.cream50;
  static const lightSurface    = ColorTokens.cream0;
  static const lightCard       = ColorTokens.cream0;
  static const lightCardAlt    = ColorTokens.ink100;
  static const lightBorder     = ColorTokens.ink300;

  // ---- Brand (mapped to new ink/lime; violet removed) ---------------------
  // primary is now ink.900 on light, lime.500 on dark.
  // For legacy callers that just need "a primary color", ink.900 is safe.
  static const primary      = ColorTokens.ink900;
  static const primaryDark  = ColorTokens.ink700;
  static const primaryLight = ColorTokens.ink500;
  static const accent       = ColorTokens.lime500;
  static const accentGreen  = ColorTokens.success;
  static const accentRed    = ColorTokens.danger;
  static const accentBlue   = ColorTokens.ink700; // closest neutral for legacy

  // ---- Dark text (legacy names) -------------------------------------------
  static const textPrimary   = ColorTokens.ink100;
  static const textSecondary = ColorTokens.ink500;
  static const textMuted     = ColorTokens.ink700;

  // ---- Light text (legacy names) ------------------------------------------
  static const lightTextPrimary   = ColorTokens.ink900;
  static const lightTextSecondary = ColorTokens.ink500;
  static const lightTextMuted     = ColorTokens.ink300;

  // ---- Gradients (neutralized — reserved for photo scrims only) -----------
  static const gradientStart = ColorTokens.ink900;
  static const gradientEnd   = ColorTokens.ink700;

  // ---- Module accent colors (kept for gamification / health screens) -------
  static const workColor    = ColorTokens.ink700;
  static const healthColor  = ColorTokens.success;
  static const financeColor = ColorTokens.lime500;
  static const ideasColor   = ColorTokens.ink500;
  static const aiColor      = ColorTokens.warn;
}

// ---------------------------------------------------------------------------
// AppTheme — the ThemeData factory. Wire into MaterialApp via AppTheme.light
// and AppTheme.dark exactly as before.
// ---------------------------------------------------------------------------

class AppTheme {
  // Spec: 1px hairline border, no elevation.
  static const _borderSideLight = BorderSide(
    color: ColorTokens.ink300,
    width: 1,
  );
  static const _borderSideDark = BorderSide(
    color: ColorTokens.night800,
    width: 1,
  );

  // -------------------------------------------------------------------------
  // LIGHT
  // -------------------------------------------------------------------------

  static ThemeData get light {
    final textTheme = TextStyles.buildTextTheme(ColorTokens.ink900);
    final cs = ColorScheme.light(
      surface:                   ColorTokens.cream0,
      surfaceContainerHighest:   ColorTokens.ink100,
      // On light mode the primary action (buttons) is ink, not lime.
      primary:                   ColorTokens.ink900,
      onPrimary:                 ColorTokens.cream0,
      secondary:                 ColorTokens.lime500,
      onSecondary:               ColorTokens.ink900,
      error:                     ColorTokens.danger,
      onError:                   ColorTokens.cream0,
      onSurface:                 ColorTokens.ink900,
      outline:                   ColorTokens.ink300,
      outlineVariant:            ColorTokens.ink100,
      surfaceTint:               Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: ColorTokens.cream50,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // AppBar — no elevation, no tint, left-aligned title
      appBarTheme: AppBarTheme(
        backgroundColor: ColorTokens.cream50,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ColorTokens.ink900),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: ColorTokens.ink900,
        ),
      ),

      // Card — 1px border, 8px radius, no shadow
      cardTheme: const CardThemeData(
        color: ColorTokens.cream0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.mdAll,
          side: _borderSideLight,
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider — hairline
      dividerTheme: const DividerThemeData(
        color: ColorTokens.ink300,
        thickness: 1,
        space: 1,
      ),

      // Input — 4px radius, hairline border, no fill color on focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.cream0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.s16,
          vertical: SpaceTokens.s12,
        ),
        border: const OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: _borderSideLight,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: _borderSideLight,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: BorderSide(
            color: ColorTokens.lime500,
            width: 1.5,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: BorderSide(color: ColorTokens.danger, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: BorderSide(color: ColorTokens.danger, width: 1.5),
        ),
        hintStyle: TextStyles.bodyMdStatic.copyWith(color: ColorTokens.ink300),
        labelStyle: TextStyles.bodyMdStatic.copyWith(color: ColorTokens.ink500),
      ),

      // Elevated button — ink fill, white label, 4px radius
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.ink900,
          foregroundColor: ColorTokens.cream0,
          disabledBackgroundColor: ColorTokens.ink300,
          disabledForegroundColor: ColorTokens.ink500,
          padding: const EdgeInsets.symmetric(
            horizontal: SpaceTokens.s24,
            vertical: SpaceTokens.s12,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: RadiusTokens.smAll,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          animationDuration: MotionTokens.duration,
        ),
      ),

      // Outlined button — ink border, ink label
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.ink900,
          side: const BorderSide(color: ColorTokens.ink300, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: SpaceTokens.s24,
            vertical: SpaceTokens.s12,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: RadiusTokens.smAll,
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          animationDuration: MotionTokens.duration,
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.ink900,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          animationDuration: MotionTokens.duration,
        ),
      ),

      // FAB — uses lime on light (signal, positive action)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.lime500,
        foregroundColor: ColorTokens.ink900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.smAll,
        ),
      ),

      // Bottom navigation — no elevation, no indicator tint
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorTokens.cream0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: ColorTokens.lime500.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ColorTokens.ink900, size: 22);
          }
          return const IconThemeData(color: ColorTokens.ink500, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColorTokens.ink900,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: ColorTokens.ink500,
          );
        }),
      ),

      // Legacy BottomNavigationBar (some screens still use it)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ColorTokens.cream0,
        selectedItemColor: ColorTokens.ink900,
        unselectedItemColor: ColorTokens.ink500,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Dialog — 8px radius, hairline border, no tint
      dialogTheme: const DialogThemeData(
        backgroundColor: ColorTokens.cream0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.mdAll,
          side: _borderSideLight,
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorTokens.cream0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: RadiusTokens.lg),
        ),
      ),

      // Checkbox / Radio
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ColorTokens.ink900;
          return Colors.transparent;
        }),
        side: const BorderSide(color: ColorTokens.ink300, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: RadiusTokens.smAll,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ColorTokens.ink900;
          return ColorTokens.ink300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ColorTokens.lime500;
          return ColorTokens.ink100;
        }),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),

      // Page transitions — 180ms, no springs
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // DARK
  // -------------------------------------------------------------------------

  static ThemeData get dark {
    final textTheme = TextStyles.buildTextTheme(ColorTokens.ink100);
    final cs = ColorScheme.dark(
      surface:                   ColorTokens.night900,
      surfaceContainerHighest:   ColorTokens.night800,
      // On dark mode lime is the primary action color.
      primary:                   ColorTokens.lime500,
      onPrimary:                 ColorTokens.ink900,
      secondary:                 ColorTokens.lime500,
      onSecondary:               ColorTokens.ink900,
      error:                     ColorTokens.danger,
      onError:                   ColorTokens.cream0,
      onSurface:                 ColorTokens.ink100,
      outline:                   ColorTokens.night800,
      outlineVariant:            ColorTokens.ink700,
      surfaceTint:               Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: ColorTokens.night950,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: ColorTokens.night950,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ColorTokens.ink100),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: ColorTokens.ink100,
        ),
      ),

      cardTheme: const CardThemeData(
        color: ColorTokens.night900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.mdAll,
          side: _borderSideDark,
        ),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: ColorTokens.night800,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.night900,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.s16,
          vertical: SpaceTokens.s12,
        ),
        border: const OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: _borderSideDark,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: _borderSideDark,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: BorderSide(
            color: ColorTokens.lime500,
            width: 1.5,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: BorderSide(color: ColorTokens.danger, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: RadiusTokens.smAll,
          borderSide: BorderSide(color: ColorTokens.danger, width: 1.5),
        ),
        hintStyle: TextStyles.bodyMdStatic.copyWith(color: ColorTokens.ink700),
        labelStyle: TextStyles.bodyMdStatic.copyWith(color: ColorTokens.ink500),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.lime500,
          foregroundColor: ColorTokens.ink900,
          disabledBackgroundColor: ColorTokens.ink700,
          disabledForegroundColor: ColorTokens.ink500,
          padding: const EdgeInsets.symmetric(
            horizontal: SpaceTokens.s24,
            vertical: SpaceTokens.s12,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: RadiusTokens.smAll,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          animationDuration: MotionTokens.duration,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.ink100,
          side: const BorderSide(color: ColorTokens.night800, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: SpaceTokens.s24,
            vertical: SpaceTokens.s12,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: RadiusTokens.smAll,
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          animationDuration: MotionTokens.duration,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.lime500,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          animationDuration: MotionTokens.duration,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.lime500,
        foregroundColor: ColorTokens.ink900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.smAll,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ColorTokens.night900,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: ColorTokens.lime500.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ColorTokens.lime500, size: 22);
          }
          return const IconThemeData(color: ColorTokens.ink500, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColorTokens.lime500,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: ColorTokens.ink500,
          );
        }),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ColorTokens.night900,
        selectedItemColor: ColorTokens.lime500,
        unselectedItemColor: ColorTokens.ink500,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: ColorTokens.night900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.mdAll,
          side: _borderSideDark,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorTokens.night900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: RadiusTokens.lg),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ColorTokens.lime500;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(ColorTokens.ink900),
        side: const BorderSide(color: ColorTokens.ink700, width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: RadiusTokens.smAll,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ColorTokens.ink900;
          return ColorTokens.ink500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ColorTokens.lime500;
          return ColorTokens.night800;
        }),
        trackOutlineColor:
            WidgetStateProperty.all(Colors.transparent),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
