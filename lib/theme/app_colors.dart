// lib/theme/app_colors.dart
//
// Semantic color aliases for Quiet OS.
// Use these names in atoms and screens — never reference raw ColorTokens
// directly in UI code. Two static classes, one per brightness, so the
// compiler catches missing cases.
//
// Usage in a widget:
//   final c = QColors.of(context);
//   Container(color: c.surface)

import 'package:flutter/material.dart';
import 'tokens.dart';

// ---------------------------------------------------------------------------
// SEMANTIC SETS
// ---------------------------------------------------------------------------

@immutable
final class QColorSet {
  const QColorSet({
    required this.appBg,
    required this.surface,
    required this.surfaceMuted,
    required this.selectedRow,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.accent,
    required this.accentPressed,
    required this.accentOnDark,   // lime on dark bg — always #C8FF00
    required this.success,
    required this.danger,
    required this.warn,
    required this.primaryButton,       // fill of the primary CTA
    required this.primaryButtonLabel,  // text on primary CTA
  });

  final Color appBg;
  final Color surface;
  final Color surfaceMuted;
  final Color selectedRow;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color accent;         // lime — context-dependent usage
  final Color accentPressed;
  final Color accentOnDark;
  final Color success;
  final Color danger;
  final Color warn;
  final Color primaryButton;
  final Color primaryButtonLabel;
}

// ---------------------------------------------------------------------------
// LIGHT PALETTE
// ---------------------------------------------------------------------------

const qLight = QColorSet(
  appBg:             ColorTokens.cream50,
  surface:           ColorTokens.cream0,
  surfaceMuted:      ColorTokens.ink100,
  selectedRow:       ColorTokens.ink100,
  border:            ColorTokens.ink300,
  textPrimary:       ColorTokens.ink900,
  textSecondary:     ColorTokens.ink500,
  textDisabled:      ColorTokens.ink300,
  // On light: lime is a SIGNAL only — dots, sparklines, today pill, next-arrow.
  // The primary button is ink.900 (not lime) for legibility.
  accent:            ColorTokens.lime500,
  accentPressed:     ColorTokens.lime700,
  accentOnDark:      ColorTokens.lime500,
  success:           ColorTokens.success,
  danger:            ColorTokens.danger,
  warn:              ColorTokens.warn,
  primaryButton:     ColorTokens.ink900,      // dark button on white bg
  primaryButtonLabel: ColorTokens.cream0,     // white text on dark button
);

// ---------------------------------------------------------------------------
// DARK PALETTE
// ---------------------------------------------------------------------------

const qDark = QColorSet(
  appBg:             ColorTokens.night950,
  surface:           ColorTokens.night900,
  surfaceMuted:      ColorTokens.night800,
  selectedRow:       ColorTokens.night800,
  border:            ColorTokens.night800,
  textPrimary:       ColorTokens.ink100,      // near-white
  textSecondary:     ColorTokens.ink500,
  textDisabled:      ColorTokens.ink700,
  // On dark: lime IS the primary action color.
  accent:            ColorTokens.lime500,
  accentPressed:     ColorTokens.lime700,
  accentOnDark:      ColorTokens.lime500,
  success:           ColorTokens.success,
  danger:            ColorTokens.danger,
  warn:              ColorTokens.warn,
  primaryButton:     ColorTokens.lime500,     // lime button on dark bg
  primaryButtonLabel: ColorTokens.ink900,     // dark text on lime button
);

// ---------------------------------------------------------------------------
// CONTEXT ACCESSOR
// ---------------------------------------------------------------------------

abstract final class QColors {
  /// Returns the correct semantic set for the current theme brightness.
  static QColorSet of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? qDark : qLight;
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
