import 'gamification_event.dart';

/// Daily wellness/productivity score 0–100, broken down by category.
class DailyScore {
  final DateTime date;
  final int totalScore; // 0–100
  final Map<GamificationCategory, int> categoryScores; // 0–100 each
  final int xpEarned;
  final List<String> eventIds; // references to GamificationEvent IDs

  const DailyScore({
    required this.date,
    required this.totalScore,
    required this.categoryScores,
    required this.xpEarned,
    required this.eventIds,
  });

  factory DailyScore.empty(DateTime date) => DailyScore(
        date: date,
        totalScore: 0,
        categoryScores: {},
        xpEarned: 0,
        eventIds: [],
      );

  factory DailyScore.fromJson(Map<String, dynamic> json) {
    final rawCat = json['categoryScores'] as Map<String, dynamic>? ?? {};
    return DailyScore(
      date: DateTime.parse(json['date'] as String),
      totalScore: json['totalScore'] as int,
      categoryScores: rawCat.map(
        (k, v) => MapEntry(GamificationCategory.values.byName(k), v as int),
      ),
      xpEarned: json['xpEarned'] as int,
      eventIds: List<String>.from(json['eventIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalScore': totalScore,
        'categoryScores':
            categoryScores.map((k, v) => MapEntry(k.name, v)),
        'xpEarned': xpEarned,
        'eventIds': eventIds,
      };
}
