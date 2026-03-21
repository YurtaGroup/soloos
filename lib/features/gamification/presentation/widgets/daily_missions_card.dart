import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/daily_mission.dart';
import '../../domain/models/gamification_event.dart';

class DailyMissionsCard extends StatelessWidget {
  final List<DailyMission> missions;
  final void Function(String missionId) onComplete;

  const DailyMissionsCard({
    super.key,
    required this.missions,
    required this.onComplete,
  });

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
    final completed = missions.where((m) => m.isCompleted).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed/${missions.length} done',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              if (completed == missions.length && missions.isNotEmpty)
                const Text('🏆 All missions complete!',
                    style: TextStyle(color: AppColors.accentGreen, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ...missions.map((m) => _MissionTile(
                mission: m,
                color: _colors[m.category] ?? AppColors.primary,
                onComplete: () => onComplete(m.id),
              )),
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final DailyMission mission;
  final Color color;
  final VoidCallback onComplete;
  const _MissionTile(
      {required this.mission, required this.color, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: mission.isCompleted
            ? AppColors.accentGreen.withOpacity(0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: mission.isCompleted
              ? AppColors.accentGreen.withOpacity(0.3)
              : color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: mission.isCompleted ? null : onComplete,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: mission.isCompleted
                    ? AppColors.accentGreen
                    : color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: mission.isCompleted ? AppColors.accentGreen : color,
                ),
              ),
              child: mission.isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    color: mission.isCompleted
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: mission.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                Text(
                  mission.description,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mission.difficultyEmoji,
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                '+${mission.xpReward} XP',
                style: TextStyle(
                  color: mission.isCompleted
                      ? AppColors.textMuted
                      : AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
