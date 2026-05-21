// lib/theme/atoms/app_pill.dart
//
// AppPill — small status chip.
// Variants: lime | neutral | success | danger | warn
// Radius: pill (999). The only atom allowed a full-pill radius per brand law.
// No shadow, no gradient.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens.dart';
import '../app_colors.dart';

enum AppPillVariant { lime, neutral, success, danger, warn }

class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.variant = AppPillVariant.neutral,
    this.leadingDot = false,
  });

  final String label;
  final AppPillVariant variant;
  // Show a 4px colored dot before the label (useful for status indicators).
  final bool leadingDot;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final isDark = QColors.isDark(context);

    // Pill fill + label color matrix
    final (bg, fg) = switch (variant) {
      AppPillVariant.lime => isDark
          ? (ColorTokens.lime500.withValues(alpha: 0.15), ColorTokens.lime500)
          : (ColorTokens.lime500.withValues(alpha: 0.12), ColorTokens.ink900),
      AppPillVariant.neutral => (
          c.surfaceMuted,
          c.textSecondary,
        ),
      AppPillVariant.success => (
          ColorTokens.success.withValues(alpha: 0.12),
          ColorTokens.success,
        ),
      AppPillVariant.danger => (
          // Light: deeper red bg tint to match the stronger dangerFg.
          // Dark: standard danger token (unchanged).
          isDark
              ? ColorTokens.danger.withValues(alpha: 0.12)
              : const Color(0xFFDC2626).withValues(alpha: 0.08),
          c.dangerFg,
        ),
      AppPillVariant.warn => (
          ColorTokens.warn.withValues(alpha: 0.12),
          ColorTokens.warn,
        ),
    };

    // Dot color matches foreground
    final dotColor = fg;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpaceTokens.s8,
        vertical: SpaceTokens.s4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: RadiusTokens.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              height: 14 / 11,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
