// lib/theme/atoms/app_card.dart
//
// AppCard — border-only container atom.
// No shadow. No elevation. 1px hairline border.
// Default radius: 8px (md). Override via radius param.

import 'package:flutter/material.dart';
import '../tokens.dart';
import '../app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = RadiusTokens.mdAll,
    this.onTap,
    this.color,  // override surface color if needed
    this.dense = false, // dense: 14pt padding instead of 16pt
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius radius;
  final VoidCallback? onTap;
  final Color? color;
  // dense = true → 14pt padding on all sides (vs 16pt default).
  // Use for pipeline cards and compact list contexts.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final bg = color ?? c.surface;

    return AnimatedContainer(
      duration: MotionTokens.duration,
      curve: MotionTokens.curve,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: c.border, width: 1),
        // Elevation: NONE. No boxShadow.
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: c.border.withValues(alpha: 0.15),
            highlightColor: c.border.withValues(alpha: 0.08),
            child: () {
              // Resolve padding: explicit > dense variant > default 16pt
              final effectivePadding = padding ??
                  (dense
                      ? const EdgeInsets.all(14)
                      : const EdgeInsets.all(SpaceTokens.s16));
              return Padding(padding: effectivePadding, child: child);
            }(),
          ),
        ),
      ),
    );
  }
}
