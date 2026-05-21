// lib/theme/atoms/app_button.dart
//
// AppButton — Quiet OS primary interaction atom.
//
// Variants: primary | secondary | ghost
// Sizes:    sm | md | lg
//
// Light mode:  primary = ink900 fill, white label.
// Dark mode:   primary = lime500 fill, ink900 label.
// secondary:   hairline border, no fill, textPrimary label.
// ghost:       no border, no fill, textSecondary label.
//
// No elevation, no drop shadow, no spring animation.
// 180ms cubic-bezier(0.2, 0, 0, 1) on state changes.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens.dart';
import '../app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    // Size-based padding and font
    final (hPad, vPad, fontSize) = switch (size) {
      AppButtonSize.sm => (SpaceTokens.s12, SpaceTokens.s8,  13.0),
      AppButtonSize.md => (SpaceTokens.s16, SpaceTokens.s12, 14.0),
      AppButtonSize.lg => (SpaceTokens.s24, SpaceTokens.s16, 15.0),
    };

    // Variant colors
    final (bgColor, fgColor, borderColor) = switch (variant) {
      AppButtonVariant.primary => (
        onPressed == null ? c.textDisabled : c.primaryButton,
        onPressed == null ? c.textSecondary : c.primaryButtonLabel,
        Colors.transparent,
      ),
      AppButtonVariant.secondary => (
        Colors.transparent,
        onPressed == null ? c.textDisabled : c.textPrimary,
        onPressed == null ? c.textDisabled : c.border,
      ),
      AppButtonVariant.ghost => (
        Colors.transparent,
        onPressed == null ? c.textDisabled : c.textSecondary,
        Colors.transparent,
      ),
    };

    final textStyle = GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: fgColor,
    );

    Widget child = isLoading
        ? SizedBox(
            width: fontSize,
            height: fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                IconTheme(
                  data: IconThemeData(color: fgColor, size: fontSize + 2),
                  child: leadingIcon!,
                ),
                const SizedBox(width: SpaceTokens.s8),
              ],
              Text(label, style: textStyle),
              if (trailingIcon != null) ...[
                const SizedBox(width: SpaceTokens.s8),
                IconTheme(
                  data: IconThemeData(color: fgColor, size: fontSize + 2),
                  child: trailingIcon!,
                ),
              ],
            ],
          );

    if (isFullWidth) {
      child = Center(child: child);
    }

    return AnimatedContainer(
      duration: MotionTokens.duration,
      curve: MotionTokens.curve,
      width: isFullWidth ? double.infinity : null,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: MotionTokens.duration,
          curve: MotionTokens.curve,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: variant == AppButtonVariant.primary
                ? RadiusTokens.smAll
                : RadiusTokens.smAll,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
