import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Reusable dismissible wrapper with consistent delete background.
/// Eliminates 4× repeated Dismissible boilerplate across screens.
///
/// Usage:
/// ```dart
/// DismissibleCard(
///   id: item.id,
///   onDelete: () => viewModel.delete(item),
///   child: MyTile(item: item),
/// );
/// ```
class DismissibleCard extends StatelessWidget {
  const DismissibleCard({
    super.key,
    required this.id,
    required this.onDelete,
    required this.child,
    this.deleteColor = AppColors.accentRed,
  });

  final String id;
  final VoidCallback onDelete;
  final Widget child;
  final Color deleteColor;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: deleteColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: deleteColor),
      ),
      child: child,
    );
  }
}
