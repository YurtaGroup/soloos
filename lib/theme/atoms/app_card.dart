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
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius radius;
  final VoidCallback? onTap;
  final Color? color;

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
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        ),
      ),
    );
  }
}
