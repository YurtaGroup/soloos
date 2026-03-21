import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable API key / password input with show/hide toggle.
/// Used in OnboardingScreen and SettingsScreen.
///
/// Usage:
/// ```dart
/// ApiKeyField(
///   controller: _keyController,
///   label: 'Claude API Key',
///   hint: 'sk-ant-...',
/// )
/// ```
class ApiKeyField extends StatefulWidget {
  const ApiKeyField({
    super.key,
    required this.controller,
    this.label = 'API Key',
    this.hint = '',
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  State<ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<ApiKeyField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      style: const TextStyle(color: AppColors.textPrimary),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: IconButton(
          icon: Icon(
            _visible ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}
