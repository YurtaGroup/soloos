import 'package:flutter/material.dart';

class Habit {
  final String id;
  String name;
  String emoji;
  String frequency; // daily, weekdays, weekends
  List<DateTime> completedDates;
  Color color;

  Habit({
    required this.id,
    required this.name,
    this.emoji = '✅',
    this.frequency = 'daily',
    List<DateTime>? completedDates,
    this.color = const Color(0xFF10B981),
  }) : completedDates = completedDates ?? [];

  bool isCompletedToday() {
    final today = DateTime.now();
    return completedDates.any(
      (d) => d.year == today.year && d.month == today.month && d.day == today.day,
    );
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = completedDates.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime.now();
    for (var date in sorted) {
      if (date.year == check.year && date.month == check.month && date.day == check.day) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'frequency': frequency,
        'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
        'color': color.value,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'] ?? '✅',
        frequency: j['frequency'] ?? 'daily',
        completedDates: (j['completedDates'] as List? ?? [])
            .map((d) => DateTime.parse(d))
            .toList(),
        color: Color(j['color'] ?? 0xFF10B981),
      );
}
