/// Persistent XP + level state for the user.
class UserProgress {
  final int totalXp;
  final int level;
  final int xpToNextLevel;
  final DateTime lastUpdated;

  const UserProgress({
    required this.totalXp,
    required this.level,
    required this.xpToNextLevel,
    required this.lastUpdated,
  });

  static const int xpPerLevel = 500;

  factory UserProgress.initial() => UserProgress(
        totalXp: 0,
        level: 1,
        xpToNextLevel: xpPerLevel,
        lastUpdated: DateTime.now(),
      );

  /// XP within the current level (0 .. xpPerLevel).
  int get xpInCurrentLevel => totalXp % xpPerLevel;

  /// Progress ratio 0.0 – 1.0.
  double get levelProgress => xpInCurrentLevel / xpPerLevel;

  String get levelTitle => switch (level) {
        1 => 'Starter',
        2 => 'Builder',
        3 => 'Hustler',
        4 => 'Operator',
        5 => 'Catalyst',
        6 => 'Visionary',
        7 => 'Architect',
        8 => 'Legend',
        _ => level >= 9 ? 'Titan' : 'Rookie',
      };

  UserProgress addXp(int xp) {
    final newTotal = totalXp + xp;
    final newLevel = (newTotal ~/ xpPerLevel) + 1;
    return UserProgress(
      totalXp: newTotal,
      level: newLevel,
      xpToNextLevel: newLevel * xpPerLevel,
      lastUpdated: DateTime.now(),
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        totalXp: json['totalXp'] as int,
        level: json['level'] as int,
        xpToNextLevel: json['xpToNextLevel'] as int,
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'level': level,
        'xpToNextLevel': xpToNextLevel,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}
