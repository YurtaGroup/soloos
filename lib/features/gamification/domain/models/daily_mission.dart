import 'gamification_event.dart';

enum MissionDifficulty { easy, medium, hard }

/// A daily mission the user can complete for bonus XP.
class DailyMission {
  final String id;
  final String title;
  final String description;
  final GamificationCategory category;
  final MissionDifficulty difficulty;
  final int xpReward;
  final bool isCompleted;
  final DateTime date;
  final GamificationEventType? triggerEventType; // auto-complete on this event

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.isCompleted,
    required this.date,
    this.triggerEventType,
  });

  int get scoreContribution => switch (difficulty) {
        MissionDifficulty.easy => 5,
        MissionDifficulty.medium => 10,
        MissionDifficulty.hard => 20,
      };

  String get difficultyEmoji => switch (difficulty) {
        MissionDifficulty.easy => '🟢',
        MissionDifficulty.medium => '🟡',
        MissionDifficulty.hard => '🔴',
      };

  DailyMission complete() => DailyMission(
        id: id,
        title: title,
        description: description,
        category: category,
        difficulty: difficulty,
        xpReward: xpReward,
        isCompleted: true,
        date: date,
        triggerEventType: triggerEventType,
      );

  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category:
            GamificationCategory.values.byName(json['category'] as String),
        difficulty:
            MissionDifficulty.values.byName(json['difficulty'] as String),
        xpReward: json['xpReward'] as int,
        isCompleted: json['isCompleted'] as bool,
        date: DateTime.parse(json['date'] as String),
        triggerEventType: json['triggerEventType'] != null
            ? GamificationEventType.values
                .byName(json['triggerEventType'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'difficulty': difficulty.name,
        'xpReward': xpReward,
        'isCompleted': isCompleted,
        'date': date.toIso8601String(),
        if (triggerEventType != null) 'triggerEventType': triggerEventType!.name,
      };
}
