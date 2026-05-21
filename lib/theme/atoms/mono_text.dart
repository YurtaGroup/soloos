// lib/theme/atoms/mono_text.dart
//
// MonoText — pre-styled JetBrains Mono widget.
// Use for: dollar amounts, times, percentages, counts.
// Tabular figures always on so columns align without manual kerning.
//
// Usage: MonoText('$4,200')
//        MonoText('09:30', color: QColors.of(context).textSecondary)
//        MonoText('23/31', size: 16)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';

class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.size = 13,
    this.weight = FontWeight.w400,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        height: 18 / 13,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? c.textPrimary,
      ),
    );
  }
}
