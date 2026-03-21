import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/gamification_event.dart';
import '../../domain/models/daily_score.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/models/streak_status.dart';
import '../../domain/models/daily_mission.dart';
import '../../domain/models/ai_coach_suggestion.dart';
import '../../data/repositories/gamification_repository_impl.dart';
import '../../data/services/gamification_engine_service.dart';
import '../../data/services/streak_service.dart';
import '../../data/services/daily_mission_service.dart';
import '../../data/services/ai_coach_service.dart';
import '../../data/services/gamification_event_bus.dart';

class GamificationViewModel extends ChangeNotifier {
  final _repo = LocalGamificationRepository();
  final _engine = GamificationEngineService();
  final _streakService = StreakService();
  final _missionService = DailyMissionService();
  final _coachService = AiCoachService();
  static const _uuid = Uuid();

  bool _initialized = false;

  DailyScore? _todayScore;
  UserProgress _progress = UserProgress.initial();
  List<StreakStatus> _streaks = [];
  List<DailyMission> _todayMissions = [];
  List<AiCoachSuggestion> _coachSuggestions = [];
  List<GamificationEvent> _recentEvents = [];

  // Getters
  DailyScore? get todayScore => _todayScore;
  UserProgress get progress => _progress;
  List<StreakStatus> get streaks => _streaks;
  List<DailyMission> get todayMissions => _todayMissions;
  List<AiCoachSuggestion> get coachSuggestions =>
      _coachSuggestions.where((s) => !s.isDismissed).toList();
  int get todayScoreValue => _todayScore?.totalScore ?? 0;
  List<GamificationEvent> get recentEvents => _recentEvents;

  List<StreakStatus> get activeStreaks =>
      _streaks.where((s) => s.isActive).toList()
        ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

  List<DailyMission> get completedMissions =>
      _todayMissions.where((m) => m.isCompleted).toList();
  List<DailyMission> get pendingMissions =>
      _todayMissions.where((m) => !m.isCompleted).toList();

  int get missionsCompletedCount => completedMissions.length;
  int get totalMissionsCount => _todayMissions.length;

  GamificationCategory? get weakestCategory {
    if (_todayScore == null) return null;
    if (_todayScore!.categoryScores.isEmpty) return null;
    return _todayScore!.categoryScores.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _repo.init();
    GamificationEventBus.register(
        (type, {description}) => logEvent(type, description: description));
    await _refresh();
  }

  @override
  void dispose() {
    GamificationEventBus.unregister();
    super.dispose();
  }

  /// Called by any feature module to log an activity.
  Future<void> logEvent(GamificationEventType type, {String? description}) async {
    final event = GamificationEvent(
      id: _uuid.v4(),
      category: GamificationEngineService.categoryFor(type),
      type: type,
      points: GamificationEngineService.pointsFor(type),
      occurredAt: DateTime.now(),
      description: description,
    );
    await _repo.saveEvent(event);

    // Auto-complete missions triggered by this event
    final updated = _missionService.applyEventToMissions(_todayMissions, type);
    final newlyCompleted = updated
        .where((m) => m.isCompleted)
        .where((m) => !_todayMissions.any((old) => old.id == m.id && old.isCompleted))
        .toList();
    for (final m in newlyCompleted) {
      await _repo.updateMission(m);
    }

    // Update streak for the category
    final cat = event.category;
    final existing = _streaks.firstWhere(
      (s) => s.category == cat,
      orElse: () => StreakStatus.initial(cat),
    );
    final updated2 =
        _streakService.processActivity(current: existing, activityDate: DateTime.now());
    await _repo.saveStreak(updated2);

    await _refresh();
  }

  Future<void> completeMissionManually(String missionId) async {
    final idx = _todayMissions.indexWhere((m) => m.id == missionId);
    if (idx < 0 || _todayMissions[idx].isCompleted) return;
    final completed = _todayMissions[idx].complete();
    await _repo.updateMission(completed);

    // Award mission XP
    final updatedProgress = _progress.addXp(completed.xpReward);
    await _repo.saveUserProgress(updatedProgress);

    await _refresh();
  }

  Future<void> dismissCoachSuggestion(String id) async {
    final suggestion = _coachSuggestions.firstWhere((s) => s.id == id);
    await _repo.updateSuggestion(suggestion.dismiss());
    await _refresh();
  }

  Future<void> _refresh() async {
    final today = DateTime.now();

    // Decay stale streaks
    final rawStreaks = await _repo.getAllStreaks();
    _streaks = _streakService.decayStaleStreaks(rawStreaks);
    for (final s in _streaks) {
      await _repo.saveStreak(s);
    }

    // Generate today's missions if not yet generated
    var missions = await _repo.getMissionsForDate(today);
    if (missions.isEmpty) {
      missions = _missionService.generateMissions(today);
      await _repo.saveMissions(missions);
    }
    _todayMissions = missions;

    // Events + score
    _recentEvents = await _repo.getRecentEvents(days: 7);
    final todayEvents = await _repo.getEventsForDate(today);
    final existingScore = await _repo.getDailyScore(today);

    _todayScore = _engine.compute(
      date: today,
      events: todayEvents,
      completedMissions: _todayMissions.where((m) => m.isCompleted).toList(),
      streaks: _streaks,
      existingEventIds: existingScore?.eventIds ?? [],
    );
    await _repo.saveDailyScore(_todayScore!);

    // Update XP/progress
    _progress = await _repo.getUserProgress();
    final newProgress = _progress.addXp(0); // recalc level from stored XP
    // Only update if score changed (avoid runaway XP from refreshes)
    if (existingScore == null ||
        existingScore.xpEarned != _todayScore!.xpEarned) {
      final xpDelta = _todayScore!.xpEarned -
          (existingScore?.xpEarned ?? 0);
      if (xpDelta > 0) {
        _progress = _progress.addXp(xpDelta);
        await _repo.saveUserProgress(_progress);
      }
    } else {
      _progress = newProgress;
    }

    // Coach suggestions
    await _repo.clearOldSuggestions();
    final activeSuggestions = await _repo.getActiveSuggestions();
    if (activeSuggestions.isEmpty) {
      final generated = _coachService.generateSuggestions(
        todayScore: _todayScore,
        streaks: _streaks,
        recentEvents: _recentEvents,
      );
      for (final s in generated) {
        await _repo.saveSuggestion(s);
      }
      _coachSuggestions = generated;
    } else {
      _coachSuggestions = activeSuggestions;
    }

    notifyListeners();
  }
}
