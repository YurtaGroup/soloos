import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Shared bottom sheet helper.
/// Eliminates repeated [showModalBottomSheet] boilerplate across all screens.
///
/// Usage:
/// ```dart
/// AppBottomSheet.show(context, builder: (ctx) => AddIdeaForm(...));
/// ```
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget Function(BuildContext ctx) builder,
    bool isScrollControlled = true,
    double topRadius = 20,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: builder(ctx),
      ),
    );
  }
}
