/// A single action logged from any module that contributes to gamification.
class GamificationEvent {
  final String id;
  final GamificationCategory category;
  final GamificationEventType type;
  final double points;
  final DateTime occurredAt;
  final String? description;

  const GamificationEvent({
    required this.id,
    required this.category,
    required this.type,
    required this.points,
    required this.occurredAt,
    this.description,
  });

  factory GamificationEvent.fromJson(Map<String, dynamic> json) =>
      GamificationEvent(
        id: json['id'] as String,
        category: GamificationCategory.values.byName(json['category'] as String),
        type: GamificationEventType.values.byName(json['type'] as String),
        points: (json['points'] as num).toDouble(),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'type': type.name,
        'points': points,
        'occurredAt': occurredAt.toIso8601String(),
        if (description != null) 'description': description,
      };
}

enum GamificationCategory {
  mind,
  work,
  finance,
  life,
  family,
  health,
  ideas;

  String get label => switch (this) {
        mind => 'Mind',
        work => 'Work',
        finance => 'Finance',
        life => 'Life',
        family => 'Family',
        health => 'Health',
        ideas => 'Ideas',
      };

  String get emoji => switch (this) {
        mind => '🧠',
        work => '💼',
        finance => '💰',
        life => '✨',
        family => '❤️',
        health => '🌿',
        ideas => '💡',
      };
}

enum GamificationEventType {
  // Work
  taskCompleted,
  projectMilestone,
  standupCompleted,
  // Health
  habitCompleted,
  allHabitsCompleted,
  // Finance
  debtPaymentLogged,
  obligationTracked,
  // Family
  contactedPerson,
  reminderCompleted,
  noteAdded,
  // Ideas
  ideaCreated,
  ideaActedOn,
  // Life / Mind
  journalEntry,
  goalSet,
  // Streaks
  streakExtended,
  streakRestored,
}
