class StandupLog {
  final String id;
  DateTime date;
  String wins;
  String challenges;
  String priorities;
  String aiResponse;

  StandupLog({
    required this.id,
    DateTime? date,
    this.wins = '',
    this.challenges = '',
    this.priorities = '',
    this.aiResponse = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'wins': wins,
        'challenges': challenges,
        'priorities': priorities,
        'aiResponse': aiResponse,
      };

  factory StandupLog.fromJson(Map<String, dynamic> j) => StandupLog(
        id: j['id'],
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        wins: j['wins'] ?? '',
        challenges: j['challenges'] ?? '',
        priorities: j['priorities'] ?? '',
        aiResponse: j['aiResponse'] ?? '',
      );
}
