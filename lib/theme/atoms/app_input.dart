// lib/theme/atoms/app_input.dart
//
// AppInput — Quiet OS text field.
// 4px radius (sm). Hairline border. Lime focus ring (1.5px).
// No filled background tint — surface color only.
// No floating label (uses hintText). Override via hintText param.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens.dart';
import '../app_colors.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.hintText,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.errorText,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? label;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    final base = OutlineInputBorder(
      borderRadius: RadiusTokens.smAll,
      borderSide: BorderSide(color: c.border, width: 1),
    );
    final focused = OutlineInputBorder(
      borderRadius: RadiusTokens.smAll,
      borderSide: BorderSide(color: ColorTokens.lime500, width: 1.5),
    );
    final errored = OutlineInputBorder(
      borderRadius: RadiusTokens.smAll,
      borderSide: BorderSide(color: ColorTokens.danger, width: 1),
    );
    final errorFocused = OutlineInputBorder(
      borderRadius: RadiusTokens.smAll,
      borderSide: BorderSide(color: ColorTokens.danger, width: 1.5),
    );
    final disabled = OutlineInputBorder(
      borderRadius: RadiusTokens.smAll,
      borderSide: BorderSide(color: c.textDisabled, width: 1),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: enabled ? c.textPrimary : c.textDisabled,
      ),
      cursorColor: ColorTokens.lime500,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? IconTheme(
                data: IconThemeData(color: c.textSecondary, size: 18),
                child: prefixIcon!,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconTheme(
                data: IconThemeData(color: c.textSecondary, size: 18),
                child: suffixIcon!,
              )
            : null,
        filled: true,
        fillColor: enabled ? c.surface : c.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.s16,
          vertical: SpaceTokens.s12,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: c.textDisabled,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: c.textSecondary,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ColorTokens.danger,
        ),
        border:            base,
        enabledBorder:     base,
        focusedBorder:     focused,
        errorBorder:       errored,
        focusedErrorBorder: errorFocused,
        disabledBorder:    disabled,
      ),
    );
  }
}
