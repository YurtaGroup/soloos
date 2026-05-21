// lib/theme/tokens.dart
//
// Quiet OS design-system — Week 1 foundation.
// Every value here is const. Nothing ships outside this file
// without a token name. Screens reference semantic aliases in
// app_colors.dart; only theme builders touch raw tokens directly.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// COLOR TOKENS
// ---------------------------------------------------------------------------

abstract final class ColorTokens {
  // Ink scale — monochrome base
  static const ink900 = Color(0xFF0A0A0B);
  static const ink700 = Color(0xFF2A2A2C);
  static const ink500 = Color(0xFF6B6B70);
  static const ink300 = Color(0xFFC9C9CB);
  static const ink100 = Color(0xFFEDEDEA);

  // Cream — light-mode surfaces
  static const cream50 = Color(0xFFFAFAF9); // app background (light)
  static const cream0 = Color(0xFFFFFFFF);  // card surface (light)

  // Night — dark-mode surfaces
  static const night950 = Color(0xFF0A0A0B); // app background (dark)
  static const night900 = Color(0xFF111113); // card surface (dark)
  static const night800 = Color(0xFF161617); // selected row (dark)

  // Accent
  static const lime500 = Color(0xFFC8FF00); // electric lime — signal on light, action on dark
  static const lime700 = Color(0xFF9CC900); // pressed state

  // Signals
  static const success = Color(0xFF00B86B);
  static const danger  = Color(0xFFE5484D);
  static const warn    = Color(0xFFF5A524);
}

// ---------------------------------------------------------------------------
// RADIUS TOKENS
// ---------------------------------------------------------------------------

abstract final class RadiusTokens {
  static const sm   = Radius.circular(4);
  static const md   = Radius.circular(8);
  static const lg   = Radius.circular(12);
  static const pill = Radius.circular(999);

  static const smAll   = BorderRadius.all(sm);
  static const mdAll   = BorderRadius.all(md);
  static const lgAll   = BorderRadius.all(lg);
  static const pillAll = BorderRadius.all(pill);
}

// ---------------------------------------------------------------------------
// SPACING TOKENS  (4-grid)
// ---------------------------------------------------------------------------

abstract final class SpaceTokens {
  static const s4  = 4.0;
  static const s8  = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;
}

// ---------------------------------------------------------------------------
// MOTION TOKENS
// ---------------------------------------------------------------------------

abstract final class MotionTokens {
  static const duration = Duration(milliseconds: 180);
  // Spec: cubic-bezier(0.2, 0, 0, 1) — no spring, no bounce.
  static const curve = Cubic(0.2, 0.0, 0.0, 1.0);
}

// ---------------------------------------------------------------------------
// TYPE TOKENS
// ---------------------------------------------------------------------------

// Font families. google_fonts variants live in text_styles.dart.
// These constants are referenced as fallbacks in ThemeData.
abstract final class FontTokens {
  static const uiFamily   = 'Inter';
  static const monoFamily = 'JetBrainsMono';
}
