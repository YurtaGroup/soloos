import '../../domain/models/gamification_event.dart';
import '../../domain/models/daily_score.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/models/streak_status.dart';
import '../../domain/models/daily_mission.dart';
import '../../domain/models/ai_coach_suggestion.dart';

abstract class GamificationRepository {
  Future<void> init();

  // Events
  Future<List<GamificationEvent>> getEventsForDate(DateTime date);
  Future<List<GamificationEvent>> getRecentEvents({int days = 7});
  Future<void> saveEvent(GamificationEvent event);

  // Daily score
  Future<DailyScore?> getDailyScore(DateTime date);
  Future<void> saveDailyScore(DailyScore score);

  // User progress
  Future<UserProgress> getUserProgress();
  Future<void> saveUserProgress(UserProgress progress);

  // Streaks
  Future<List<StreakStatus>> getAllStreaks();
  Future<StreakStatus?> getStreak(GamificationCategory category);
  Future<void> saveStreak(StreakStatus streak);

  // Missions
  Future<List<DailyMission>> getMissionsForDate(DateTime date);
  Future<void> saveMissions(List<DailyMission> missions);
  Future<void> updateMission(DailyMission mission);

  // Coach suggestions
  Future<List<AiCoachSuggestion>> getActiveSuggestions();
  Future<void> saveSuggestion(AiCoachSuggestion suggestion);
  Future<void> updateSuggestion(AiCoachSuggestion suggestion);
  Future<void> clearOldSuggestions();
}
