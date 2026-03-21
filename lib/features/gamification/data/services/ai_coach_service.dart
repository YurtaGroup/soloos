import 'package:uuid/uuid.dart';
import '../../domain/models/ai_coach_suggestion.dart';
import '../../domain/models/daily_score.dart';
import '../../domain/models/streak_status.dart';
import '../../domain/models/gamification_event.dart';

/// Rule-based (no LLM) coach that generates calm, short motivational suggestions.
class AiCoachService {
  static const _uuid = Uuid();

  /// Generate up to 2 coach suggestions based on current state.
  List<AiCoachSuggestion> generateSuggestions({
    required DailyScore? todayScore,
    required List<StreakStatus> streaks,
    required List<GamificationEvent> recentEvents,
  }) {
    final suggestions = <AiCoachSuggestion>[];

    // 1. Celebrate strong streaks
    final topStreak =
        streaks.where((s) => s.isActive).fold<StreakStatus?>(null, (best, s) {
      if (best == null) return s;
      return s.currentStreak > best.currentStreak ? s : best;
    });

    if (topStreak != null && topStreak.currentStreak >= 7) {
      suggestions.add(_make(
        message:
            '${topStreak.flameEmoji} ${topStreak.currentStreak}-day ${topStreak.category.label} streak. Momentum is your biggest asset — protect it.',
        tone: CoachTone.celebratory,
        category: topStreak.category,
      ));
    }

    // 2. Encourage at-risk streaks
    final atRisk = streaks.where((s) => s.isAtRisk).toList();
    if (atRisk.isNotEmpty && suggestions.length < 2) {
      final s = atRisk.first;
      suggestions.add(_make(
        message:
            'Your ${s.category.label} streak (${s.currentStreak}d) needs attention today. Small actions count.',
        tone: CoachTone.encouraging,
        category: s.category,
      ));
    }

    // 3. Balanced day encouragement
    if (todayScore != null && suggestions.length < 2) {
      final lowCats = todayScore.categoryScores.entries
          .where((e) => e.value < 20)
          .map((e) => e.key)
          .toList();
      if (lowCats.isNotEmpty) {
        final cat = lowCats.first;
        suggestions.add(_make(
          message: _encourageCategory(cat),
          tone: CoachTone.neutral,
          category: cat,
        ));
      }
    }

    // 4. Good score celebration
    if (todayScore != null &&
        todayScore.totalScore >= 70 &&
        suggestions.isEmpty) {
      suggestions.add(_make(
        message:
            'Strong day — score ${todayScore.totalScore}/100. You\'re building something real.',
        tone: CoachTone.celebratory,
      ));
    }

    // 5. Generic morning nudge if nothing else fires
    if (suggestions.isEmpty) {
      suggestions.add(_make(
        message: _morningNudge(),
        tone: CoachTone.encouraging,
      ));
    }

    return suggestions.take(2).toList();
  }

  AiCoachSuggestion _make({
    required String message,
    required CoachTone tone,
    GamificationCategory? category,
  }) =>
      AiCoachSuggestion(
        id: _uuid.v4(),
        message: message,
        tone: tone,
        focusCategory: category,
        createdAt: DateTime.now(),
      );

  String _encourageCategory(GamificationCategory cat) => switch (cat) {
        GamificationCategory.health =>
          'Even one completed habit today builds the foundation for tomorrow.',
        GamificationCategory.family =>
          'One quick message to someone you care about. That\'s it.',
        GamificationCategory.finance =>
          'A quick glance at your finances keeps you in control, not reacting.',
        GamificationCategory.work =>
          'Cross one thing off your list. Progress, not perfection.',
        GamificationCategory.ideas =>
          'Ideas compound. Capture one today before it disappears.',
        GamificationCategory.mind =>
          'A moment of reflection is the highest-ROI habit for founders.',
        GamificationCategory.life =>
          'Balance isn\'t a destination — it\'s today\'s small choices.',
      };

  String _morningNudge() {
    final nudges = [
      'One focused hour today is worth three scattered ones tomorrow.',
      'Clarity comes from action, not more planning.',
      'Build the habit before the mood arrives.',
      'You don\'t rise to the level of your goals — you fall to the level of your systems.',
      'Small consistent wins over dramatic bursts.',
    ];
    final idx = DateTime.now().day % nudges.length;
    return nudges[idx];
  }
}
