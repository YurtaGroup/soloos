import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/streak_status.dart';

class StreaksCard extends StatelessWidget {
  final List<StreakStatus> activeStreaks;
  const StreaksCard({super.key, required this.activeStreaks});

  @override
  Widget build(BuildContext context) {
    if (activeStreaks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'No active streaks yet. Start by completing actions in any category.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: activeStreaks
            .take(7)
            .map((s) => _StreakChip(streak: s))
            .toList(),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final StreakStatus streak;
  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    final color = streak.isAtRisk ? AppColors.accentRed : AppColors.accentGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(streak.category.emoji,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '${streak.flameEmoji} ${streak.currentStreak}d',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
