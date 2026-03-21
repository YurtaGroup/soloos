import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/gamification_event.dart';
import '../../domain/models/daily_score.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/models/streak_status.dart';
import '../../domain/models/daily_mission.dart';
import '../../domain/models/ai_coach_suggestion.dart';
import 'gamification_repository.dart';

class LocalGamificationRepository implements GamificationRepository {
  static const _eventsKey = 'gami_events';
  static const _dailyScoresKey = 'gami_daily_scores';
  static const _progressKey = 'gami_user_progress';
  static const _streaksKey = 'gami_streaks';
  static const _missionsKey = 'gami_missions';
  static const _coachKey = 'gami_coach_suggestions';

  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Events ────────────────────────────────────────────────────────────────

  @override
  Future<List<GamificationEvent>> getEventsForDate(DateTime date) async {
    final all = _loadEvents();
    final d = _dateOnly(date);
    return all.where((e) => _dateOnly(e.occurredAt) == d).toList();
  }

  @override
  Future<List<GamificationEvent>> getRecentEvents({int days = 7}) async {
    final all = _loadEvents();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((e) => e.occurredAt.isAfter(cutoff)).toList();
  }

  @override
  Future<void> saveEvent(GamificationEvent event) async {
    final all = _loadEvents();
    all.add(event);
    // Keep only last 90 days
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final trimmed = all.where((e) => e.occurredAt.isAfter(cutoff)).toList();
    await _prefs.setString(
        _eventsKey, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  List<GamificationEvent> _loadEvents() {
    final raw = _prefs.getString(_eventsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => GamificationEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Daily scores ──────────────────────────────────────────────────────────

  @override
  Future<DailyScore?> getDailyScore(DateTime date) async {
    final all = _loadDailyScores();
    final d = _dateOnly(date);
    try {
      return all.firstWhere((s) => _dateOnly(s.date) == d);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDailyScore(DailyScore score) async {
    final all = _loadDailyScores();
    final d = _dateOnly(score.date);
    final idx = all.indexWhere((s) => _dateOnly(s.date) == d);
    if (idx >= 0) {
      all[idx] = score;
    } else {
      all.add(score);
    }
    // Keep 30 days
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final trimmed = all.where((s) => s.date.isAfter(cutoff)).toList();
    await _prefs.setString(
        _dailyScoresKey, jsonEncode(trimmed.map((s) => s.toJson()).toList()));
  }

  List<DailyScore> _loadDailyScores() {
    final raw = _prefs.getString(_dailyScoresKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => DailyScore.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── User progress ─────────────────────────────────────────────────────────

  @override
  Future<UserProgress> getUserProgress() async {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return UserProgress.initial();
    return UserProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveUserProgress(UserProgress progress) async {
    await _prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  // ── Streaks ───────────────────────────────────────────────────────────────

  @override
  Future<List<StreakStatus>> getAllStreaks() async => _loadStreaks();

  @override
  Future<StreakStatus?> getStreak(GamificationCategory category) async {
    try {
      return _loadStreaks().firstWhere((s) => s.category == category);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveStreak(StreakStatus streak) async {
    final all = _loadStreaks();
    final idx = all.indexWhere((s) => s.category == streak.category);
    if (idx >= 0) {
      all[idx] = streak;
    } else {
      all.add(streak);
    }
    await _prefs.setString(
        _streaksKey, jsonEncode(all.map((s) => s.toJson()).toList()));
  }

  List<StreakStatus> _loadStreaks() {
    final raw = _prefs.getString(_streaksKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => StreakStatus.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Missions ──────────────────────────────────────────────────────────────

  @override
  Future<List<DailyMission>> getMissionsForDate(DateTime date) async {
    final all = _loadMissions();
    final d = _dateOnly(date);
    return all.where((m) => _dateOnly(m.date) == d).toList();
  }

  @override
  Future<void> saveMissions(List<DailyMission> missions) async {
    final existing = _loadMissions();
    // Remove missions for same dates
    final dates = missions.map((m) => _dateOnly(m.date)).toSet();
    final others = existing.where((m) => !dates.contains(_dateOnly(m.date))).toList();
    final merged = [...others, ...missions];
    // Keep 14 days
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final trimmed = merged.where((m) => m.date.isAfter(cutoff)).toList();
    await _prefs.setString(
        _missionsKey, jsonEncode(trimmed.map((m) => m.toJson()).toList()));
  }

  @override
  Future<void> updateMission(DailyMission mission) async {
    final all = _loadMissions();
    final idx = all.indexWhere((m) => m.id == mission.id);
    if (idx >= 0) all[idx] = mission;
    await _prefs.setString(
        _missionsKey, jsonEncode(all.map((m) => m.toJson()).toList()));
  }

  List<DailyMission> _loadMissions() {
    final raw = _prefs.getString(_missionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => DailyMission.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Coach suggestions ─────────────────────────────────────────────────────

  @override
  Future<List<AiCoachSuggestion>> getActiveSuggestions() async =>
      _loadCoach().where((s) => !s.isDismissed).toList();

  @override
  Future<void> saveSuggestion(AiCoachSuggestion suggestion) async {
    final all = _loadCoach();
    all.add(suggestion);
    await _saveCoach(all);
  }

  @override
  Future<void> updateSuggestion(AiCoachSuggestion suggestion) async {
    final all = _loadCoach();
    final idx = all.indexWhere((s) => s.id == suggestion.id);
    if (idx >= 0) all[idx] = suggestion;
    await _saveCoach(all);
  }

  @override
  Future<void> clearOldSuggestions() async {
    final all = _loadCoach();
    final cutoff = DateTime.now().subtract(const Duration(days: 3));
    final fresh = all.where((s) => s.createdAt.isAfter(cutoff)).toList();
    await _saveCoach(fresh);
  }

  List<AiCoachSuggestion> _loadCoach() {
    final raw = _prefs.getString(_coachKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AiCoachSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveCoach(List<AiCoachSuggestion> list) async {
    await _prefs.setString(
        _coachKey, jsonEncode(list.map((s) => s.toJson()).toList()));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
