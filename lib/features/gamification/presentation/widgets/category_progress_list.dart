import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/gamification_event.dart';

class CategoryProgressList extends StatelessWidget {
  final Map<GamificationCategory, int> categoryScores;
  const CategoryProgressList({super.key, required this.categoryScores});

  static const Map<GamificationCategory, Color> _colors = {
    GamificationCategory.work: AppColors.workColor,
    GamificationCategory.health: AppColors.healthColor,
    GamificationCategory.finance: AppColors.financeColor,
    GamificationCategory.family: Color(0xFFEC4899),
    GamificationCategory.ideas: AppColors.ideasColor,
    GamificationCategory.mind: AppColors.primaryLight,
    GamificationCategory.life: AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
    final sorted = GamificationCategory.values.toList()
      ..sort((a, b) =>
          (categoryScores[b] ?? 0).compareTo(categoryScores[a] ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sorted.map((cat) {
          final score = categoryScores[cat] ?? 0;
          final color = _colors[cat] ?? AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: Text(
                    cat.label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$score',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: score >= 60 ? color : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
