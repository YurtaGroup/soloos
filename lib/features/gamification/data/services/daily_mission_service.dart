import 'package:uuid/uuid.dart';
import '../../domain/models/daily_mission.dart';
import '../../domain/models/gamification_event.dart';

/// Generates a balanced set of daily missions.
class DailyMissionService {
  static const _uuid = Uuid();

  /// Returns 5 missions for the given date — spread across categories
  /// to encourage balance rather than grinding one area.
  List<DailyMission> generateMissions(DateTime date) {
    // Use date as seed to get consistent missions for same day
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final pool = _missionPool();
    // Pseudo-shuffle by seed (deterministic)
    pool.sort((a, b) =>
        (a.title.hashCode ^ seed).compareTo(b.title.hashCode ^ seed));

    // Pick at most 1 per category, up to 5 total
    final selected = <DailyMission>[];
    final usedCategories = <GamificationCategory>{};
    for (final m in pool) {
      if (selected.length >= 5) break;
      if (!usedCategories.contains(m.category)) {
        usedCategories.add(m.category);
        selected.add(DailyMission(
          id: _uuid.v4(),
          title: m.title,
          description: m.description,
          category: m.category,
          difficulty: m.difficulty,
          xpReward: m.xpReward,
          isCompleted: false,
          date: date,
          triggerEventType: m.triggerEventType,
        ));
      }
    }
    return selected;
  }

  /// Auto-complete missions triggered by a specific event type.
  List<DailyMission> applyEventToMissions(
    List<DailyMission> missions,
    GamificationEventType eventType,
  ) {
    return missions.map((m) {
      if (!m.isCompleted && m.triggerEventType == eventType) {
        return m.complete();
      }
      return m;
    }).toList();
  }

  List<_MissionTemplate> _missionPool() => [
        // Work
        _MissionTemplate(
          title: 'Complete a task',
          description: 'Mark any project task as done.',
          category: GamificationCategory.work,
          difficulty: MissionDifficulty.easy,
          xpReward: 30,
          triggerEventType: GamificationEventType.taskCompleted,
        ),
        _MissionTemplate(
          title: 'Run your standup',
          description: 'Do your daily AI standup check-in.',
          category: GamificationCategory.work,
          difficulty: MissionDifficulty.medium,
          xpReward: 50,
          triggerEventType: GamificationEventType.standupCompleted,
        ),
        _MissionTemplate(
          title: 'Hit a project milestone',
          description: 'Reach a milestone in any active project.',
          category: GamificationCategory.work,
          difficulty: MissionDifficulty.hard,
          xpReward: 80,
          triggerEventType: GamificationEventType.projectMilestone,
        ),
        // Health
        _MissionTemplate(
          title: 'Complete a habit',
          description: 'Check off at least one habit today.',
          category: GamificationCategory.health,
          difficulty: MissionDifficulty.easy,
          xpReward: 30,
          triggerEventType: GamificationEventType.habitCompleted,
        ),
        _MissionTemplate(
          title: 'Perfect habit day',
          description: 'Complete all your habits for today.',
          category: GamificationCategory.health,
          difficulty: MissionDifficulty.hard,
          xpReward: 100,
          triggerEventType: GamificationEventType.allHabitsCompleted,
        ),
        // Finance
        _MissionTemplate(
          title: 'Log a debt payment',
          description: 'Record a payment toward any debt.',
          category: GamificationCategory.finance,
          difficulty: MissionDifficulty.medium,
          xpReward: 50,
          triggerEventType: GamificationEventType.debtPaymentLogged,
        ),
        _MissionTemplate(
          title: 'Track an obligation',
          description: 'Add or review a monthly obligation.',
          category: GamificationCategory.finance,
          difficulty: MissionDifficulty.easy,
          xpReward: 25,
          triggerEventType: GamificationEventType.obligationTracked,
        ),
        // Family
        _MissionTemplate(
          title: 'Reach out to someone',
          description: 'Log a "contacted" interaction with a family member or friend.',
          category: GamificationCategory.family,
          difficulty: MissionDifficulty.easy,
          xpReward: 35,
          triggerEventType: GamificationEventType.contactedPerson,
        ),
        _MissionTemplate(
          title: 'Add a relationship note',
          description: 'Write something to remember about someone.',
          category: GamificationCategory.family,
          difficulty: MissionDifficulty.easy,
          xpReward: 20,
          triggerEventType: GamificationEventType.noteAdded,
        ),
        // Ideas
        _MissionTemplate(
          title: 'Capture an idea',
          description: 'Log a new idea in your ideas list.',
          category: GamificationCategory.ideas,
          difficulty: MissionDifficulty.easy,
          xpReward: 30,
          triggerEventType: GamificationEventType.ideaCreated,
        ),
        _MissionTemplate(
          title: 'Act on an idea',
          description: 'Mark an idea as "in progress" or convert it to a project.',
          category: GamificationCategory.ideas,
          difficulty: MissionDifficulty.hard,
          xpReward: 80,
          triggerEventType: GamificationEventType.ideaActedOn,
        ),
        // Mind
        _MissionTemplate(
          title: 'Set a goal',
          description: 'Define or review one personal or business goal.',
          category: GamificationCategory.mind,
          difficulty: MissionDifficulty.medium,
          xpReward: 40,
          triggerEventType: GamificationEventType.goalSet,
        ),
      ];
}

class _MissionTemplate {
  final String title;
  final String description;
  final GamificationCategory category;
  final MissionDifficulty difficulty;
  final int xpReward;
  final GamificationEventType? triggerEventType;

  const _MissionTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    this.triggerEventType,
  });
}
