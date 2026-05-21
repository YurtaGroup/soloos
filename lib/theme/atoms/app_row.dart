// lib/theme/atoms/app_row.dart
//
// AppRow — tappable list row.
// Used by Tasks list, pipeline rows, any list item.
//
// Layout: [leading] title / subtitle [trailing]
// Hairline divider below (optional, default: true).
// 180ms press highlight, no splash circle.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens.dart';
import '../app_colors.dart';

class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.showDivider = true,
    this.padding,
    this.isSelected = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: SpaceTokens.s16,
          vertical: SpaceTokens.s12,
        );

    return AnimatedContainer(
      duration: MotionTokens.duration,
      curve: MotionTokens.curve,
      color: isSelected ? c.selectedRow : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: c.border.withValues(alpha: 0.12),
        highlightColor: c.border.withValues(alpha: 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: effectivePadding,
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: SpaceTokens.s12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                            color: c.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 18 / 13,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: SpaceTokens.s12),
                    trailing!,
                  ],
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 1,
                color: c.border,
                // Align divider to the title text, not the leading widget.
                // Use a fixed indent when a leading slot is present.
                indent: leading != null ? SpaceTokens.s48 : 0,
                endIndent: 0,
              ),
          ],
        ),
      ),
    );
  }
}
