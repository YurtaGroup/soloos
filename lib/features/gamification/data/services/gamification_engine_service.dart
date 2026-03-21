import '../../domain/models/gamification_event.dart';
import '../../domain/models/daily_score.dart';
import '../../domain/models/daily_mission.dart';
import '../../domain/models/streak_status.dart';

/// Pure computation: events → DailyScore.
/// No side effects; easy to test.
class GamificationEngineService {
  // Category weights for the overall score (must sum to 1.0)
  static const Map<GamificationCategory, double> _weights = {
    GamificationCategory.work: 0.20,
    GamificationCategory.health: 0.20,
    GamificationCategory.finance: 0.15,
    GamificationCategory.family: 0.15,
    GamificationCategory.ideas: 0.10,
    GamificationCategory.mind: 0.10,
    GamificationCategory.life: 0.10,
  };

  // Max points per category per day before score caps at 100
  static const double _pointsCap = 50.0;

  // XP per score point (score 0–100 → 0–100 XP per day)
  static const int _xpPerScorePoint = 1;

  /// Compute a DailyScore from events and completed missions.
  DailyScore compute({
    required DateTime date,
    required List<GamificationEvent> events,
    required List<DailyMission> completedMissions,
    required List<StreakStatus> streaks,
    required List<String> existingEventIds,
  }) {
    // Accumulate raw points per category
    final rawPoints = <GamificationCategory, double>{};
    for (final e in events) {
      rawPoints[e.category] =
          (rawPoints[e.category] ?? 0) + e.points;
    }

    // Mission bonus points
    for (final m in completedMissions) {
      rawPoints[m.category] =
          (rawPoints[m.category] ?? 0) + m.scoreContribution;
    }

    // Streak bonus: +5 points to category for each active streak ≥ 3
    for (final s in streaks) {
      if (s.isActive && s.currentStreak >= 3) {
        final bonus = s.currentStreak >= 14
            ? 10.0
            : s.currentStreak >= 7
                ? 7.0
                : 5.0;
        rawPoints[s.category] = (rawPoints[s.category] ?? 0) + bonus;
      }
    }

    // Normalize per category to 0–100
    final categoryScores = <GamificationCategory, int>{};
    for (final cat in GamificationCategory.values) {
      final raw = rawPoints[cat] ?? 0;
      categoryScores[cat] = (raw / _pointsCap * 100).clamp(0, 100).round();
    }

    // Weighted overall score
    double weightedSum = 0;
    _weights.forEach((cat, weight) {
      weightedSum += (categoryScores[cat] ?? 0) * weight;
    });
    final totalScore = weightedSum.clamp(0, 100).round();

    final xpEarned = totalScore * _xpPerScorePoint;

    final allEventIds = {
      ...existingEventIds,
      ...events.map((e) => e.id),
    }.toList();

    return DailyScore(
      date: date,
      totalScore: totalScore,
      categoryScores: categoryScores,
      xpEarned: xpEarned,
      eventIds: allEventIds,
    );
  }

  /// Points awarded for each event type.
  static double pointsFor(GamificationEventType type) => switch (type) {
        GamificationEventType.taskCompleted => 8,
        GamificationEventType.projectMilestone => 20,
        GamificationEventType.standupCompleted => 12,
        GamificationEventType.habitCompleted => 7,
        GamificationEventType.allHabitsCompleted => 25,
        GamificationEventType.debtPaymentLogged => 15,
        GamificationEventType.obligationTracked => 10,
        GamificationEventType.contactedPerson => 10,
        GamificationEventType.reminderCompleted => 8,
        GamificationEventType.noteAdded => 5,
        GamificationEventType.ideaCreated => 10,
        GamificationEventType.ideaActedOn => 20,
        GamificationEventType.journalEntry => 8,
        GamificationEventType.goalSet => 12,
        GamificationEventType.streakExtended => 5,
        GamificationEventType.streakRestored => 15,
      };

  /// Category for each event type.
  static GamificationCategory categoryFor(GamificationEventType type) =>
      switch (type) {
        GamificationEventType.taskCompleted ||
        GamificationEventType.projectMilestone ||
        GamificationEventType.standupCompleted =>
          GamificationCategory.work,
        GamificationEventType.habitCompleted ||
        GamificationEventType.allHabitsCompleted =>
          GamificationCategory.health,
        GamificationEventType.debtPaymentLogged ||
        GamificationEventType.obligationTracked =>
          GamificationCategory.finance,
        GamificationEventType.contactedPerson ||
        GamificationEventType.reminderCompleted ||
        GamificationEventType.noteAdded =>
          GamificationCategory.family,
        GamificationEventType.ideaCreated ||
        GamificationEventType.ideaActedOn =>
          GamificationCategory.ideas,
        GamificationEventType.journalEntry ||
        GamificationEventType.goalSet =>
          GamificationCategory.mind,
        GamificationEventType.streakExtended ||
        GamificationEventType.streakRestored =>
          GamificationCategory.life,
      };
}
