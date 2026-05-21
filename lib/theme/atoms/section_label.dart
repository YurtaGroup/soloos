// lib/theme/atoms/section_label.dart
//
// SectionLabel — small-caps uppercase section header.
// Spec: 11pt / 14 lh / +0.6 tracking / medium / UPPERCASE.
// Used to head every list section: "TODAY", "PIPELINE", "THIS WEEK".
// No background, no border — just typography.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens.dart';
import '../app_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.color,
    // Pass a bottom pad to space it from the content that follows.
    this.bottomPadding = SpaceTokens.s8,
  });

  final String text;
  final Color? color;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
          height: 14 / 11,
          color: color ?? c.textSecondary,
        ),
      ),
    );
  }
}
