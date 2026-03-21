import 'gamification_event.dart';

/// Per-category streak tracking.
class StreakStatus {
  final GamificationCategory category;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final bool isBroken; // grace period used but not extended

  const StreakStatus({
    required this.category,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    this.isBroken = false,
  });

  bool get isActive => currentStreak > 0 && !isBroken;

  /// Returns true if the streak will break tomorrow unless the user acts today.
  bool get isAtRisk {
    if (lastActivityDate == null) return false;
    final daysSince = DateTime.now().difference(lastActivityDate!).inDays;
    return daysSince == 1; // acted yesterday, need to act today
  }

  String get flameEmoji {
    if (currentStreak >= 30) return '🔥';
    if (currentStreak >= 14) return '⚡';
    if (currentStreak >= 7) return '✨';
    if (currentStreak >= 3) return '🌟';
    return '💫';
  }

  StreakStatus extend(DateTime date) => StreakStatus(
        category: category,
        currentStreak: currentStreak + 1,
        longestStreak:
            currentStreak + 1 > longestStreak ? currentStreak + 1 : longestStreak,
        lastActivityDate: date,
        isBroken: false,
      );

  StreakStatus reset() => StreakStatus(
        category: category,
        currentStreak: 0,
        longestStreak: longestStreak,
        lastActivityDate: lastActivityDate,
        isBroken: true,
      );

  factory StreakStatus.initial(GamificationCategory category) =>
      StreakStatus(category: category, currentStreak: 0, longestStreak: 0);

  factory StreakStatus.fromJson(Map<String, dynamic> json) => StreakStatus(
        category: GamificationCategory.values.byName(json['category'] as String),
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        lastActivityDate: json['lastActivityDate'] != null
            ? DateTime.parse(json['lastActivityDate'] as String)
            : null,
        isBroken: json['isBroken'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        if (lastActivityDate != null)
          'lastActivityDate': lastActivityDate!.toIso8601String(),
        'isBroken': isBroken,
      };
}
