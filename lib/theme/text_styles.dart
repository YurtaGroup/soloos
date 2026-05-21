// lib/theme/text_styles.dart
//
// Quiet OS type ramp.
// All styles use google_fonts so Inter + JetBrains Mono load from
// bundled assets (no network call at runtime).
//
// Usage:
//   Text('Total', style: TextStyles.displayLg(context))
//   MonoText('$4,200')   ← preferred shorthand for numbers/time

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// INTERNAL HELPERS
// ---------------------------------------------------------------------------

// Returns the foreground color from the ambient theme so callers don't need
// to pass a color every time. Call sites can always override via copyWith.
Color _fg(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface;

// ---------------------------------------------------------------------------
// DISPLAY
// ---------------------------------------------------------------------------

abstract final class TextStyles {
  /// display.lg — 28pt / 34 lh / -0.5 tracking / semibold
  static TextStyle displayLg(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 34 / 28,
        color: _fg(context),
      );

  /// display.md — 22pt / 28 lh / -0.3 tracking / semibold
  static TextStyle displayMd(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 28 / 22,
        color: _fg(context),
      );

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  /// body.lg — 16pt / 22 lh / regular
  static TextStyle bodyLg(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 22 / 16,
        color: _fg(context),
      );

  /// body.md — 14pt / 20 lh / regular  (DEFAULT for list items, descriptions)
  static TextStyle bodyMd(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: _fg(context),
      );

  /// body.sm — 13pt / 18 lh / regular
  static TextStyle bodySm(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: _fg(context),
      );

  // ---------------------------------------------------------------------------
  // LABEL  (section headers — rendered UPPERCASE by the SectionLabel atom)
  // ---------------------------------------------------------------------------

  /// label — 11pt / 14 lh / +0.6 tracking / medium / UPPERCASE
  /// Raw style; SectionLabel widget applies TextCapitalization for you.
  static TextStyle label(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        height: 14 / 11,
        color: _fg(context),
      );

  // ---------------------------------------------------------------------------
  // MONO  (numbers, time, code)
  // ---------------------------------------------------------------------------

  /// mono — 13pt / 18 lh / regular / tabular figures
  static TextStyle mono(BuildContext context) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: _fg(context),
      );

  // ---------------------------------------------------------------------------
  // STATIC VARIANTS (for use inside ThemeData where BuildContext is unavailable)
  // These carry no color — callers set color explicitly.
  // ---------------------------------------------------------------------------

  static TextStyle get displayLgStatic => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 34 / 28,
  );

  static TextStyle get displayMdStatic => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 28 / 22,
  );

  static TextStyle get bodyLgStatic => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 22 / 16,
  );

  static TextStyle get bodyMdStatic => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static TextStyle get bodySmStatic => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
  );

  static TextStyle get labelStatic => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    height: 14 / 11,
  );

  static TextStyle get monoStatic => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ---------------------------------------------------------------------------
  // FULL TEXT THEME (for ThemeData.textTheme)
  // Material slots mapped to the Quiet OS ramp. Slots not listed here fall
  // back to Material's defaults — they will be overridden per screen in Weeks 2-4.
  // ---------------------------------------------------------------------------

  static TextTheme buildTextTheme(Color bodyColor) {
    return TextTheme(
      displayLarge:  displayLgStatic.copyWith(color: bodyColor),
      displayMedium: displayMdStatic.copyWith(color: bodyColor),
      displaySmall:  displayMdStatic.copyWith(color: bodyColor),
      headlineLarge: displayLgStatic.copyWith(color: bodyColor),
      headlineMedium: displayMdStatic.copyWith(color: bodyColor),
      headlineSmall: displayMdStatic.copyWith(color: bodyColor),
      titleLarge:    bodyLgStatic.copyWith(fontWeight: FontWeight.w600, color: bodyColor),
      titleMedium:   bodyMdStatic.copyWith(fontWeight: FontWeight.w600, color: bodyColor),
      titleSmall:    bodySmStatic.copyWith(fontWeight: FontWeight.w600, color: bodyColor),
      bodyLarge:     bodyLgStatic.copyWith(color: bodyColor),
      bodyMedium:    bodyMdStatic.copyWith(color: bodyColor),
      bodySmall:     bodySmStatic.copyWith(color: bodyColor),
      labelLarge:    bodyMdStatic.copyWith(fontWeight: FontWeight.w500, color: bodyColor),
      labelMedium:   bodySmStatic.copyWith(fontWeight: FontWeight.w500, color: bodyColor),
      labelSmall:    labelStatic.copyWith(color: bodyColor),
    );
  }
}
