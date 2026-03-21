import '../../domain/models/streak_status.dart';

/// Manages streak logic: extend, break, grace period.
class StreakService {
  /// Given the current streak and the latest activity date for a category,
  /// returns the updated streak.
  ///
  /// Rules:
  /// - Activity today → extend streak (or start at 1)
  /// - Activity yesterday and today → extend
  /// - 2+ days gap → break streak (reset to 0 or 1 if today has activity)
  /// - Grace period: streak is NOT broken on the first missed day,
  ///   but it's marked [isBroken=false, atRisk=true]; broken on 2nd miss.
  StreakStatus processActivity({
    required StreakStatus current,
    required DateTime activityDate,
  }) {
    final actDay = _dateOnly(activityDate);
    final lastDay =
        current.lastActivityDate != null ? _dateOnly(current.lastActivityDate!) : null;

    if (lastDay == null) {
      // First activity ever for this category
      return StreakStatus(
        category: current.category,
        currentStreak: 1,
        longestStreak: 1,
        lastActivityDate: activityDate,
        isBroken: false,
      );
    }

    final daysSinceLast = actDay.difference(lastDay).inDays;

    if (daysSinceLast == 0) {
      // Already acted today — no change needed (idempotent)
      return current;
    } else if (daysSinceLast == 1) {
      // Consecutive day — extend
      return current.extend(activityDate);
    } else {
      // Gap — start fresh from 1 (no grace period: streak already broken)
      return StreakStatus(
        category: current.category,
        currentStreak: 1,
        longestStreak: current.longestStreak,
        lastActivityDate: activityDate,
        isBroken: false,
      );
    }
  }

  /// Check all streaks and mark any that missed yesterday as broken.
  List<StreakStatus> decayStaleStreaks(List<StreakStatus> streaks) {
    final yesterday = _dateOnly(
        DateTime.now().subtract(const Duration(days: 1)));
    return streaks.map((s) {
      if (s.currentStreak == 0 || s.lastActivityDate == null) return s;
      final lastDay = _dateOnly(s.lastActivityDate!);
      // If last activity was before yesterday, streak is broken
      if (lastDay.isBefore(yesterday)) {
        return s.reset();
      }
      return s;
    }).toList();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
