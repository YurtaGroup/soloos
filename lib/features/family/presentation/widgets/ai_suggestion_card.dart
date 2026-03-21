import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/family_suggestion.dart';

class AiSuggestionCard extends StatelessWidget {
  final FamilySuggestion suggestion;
  final VoidCallback onActedOn;
  final VoidCallback onDismiss;

  const AiSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onActedOn,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(suggestion.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
                const SizedBox(height: 3),
                Text(suggestion.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onActedOn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('✓ Done',
                            style: TextStyle(
                                color: AppColors.accentGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDismiss,
                      child: const Text('Dismiss',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
