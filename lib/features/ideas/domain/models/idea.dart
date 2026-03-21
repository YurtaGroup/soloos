enum IdeaStatus { active, archived, completed }

class Idea {
  final String id;
  String title;
  String description;
  IdeaStatus status;
  List<String> notes;
  DateTime createdAt;
  String? aiScript;

  Idea({
    required this.id,
    required this.title,
    this.description = '',
    this.status = IdeaStatus.active,
    List<String>? notes,
    DateTime? createdAt,
    this.aiScript,
  })  : notes = notes ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'aiScript': aiScript,
      };

  factory Idea.fromJson(Map<String, dynamic> j) => Idea(
        id: j['id'],
        title: j['title'],
        description: j['description'] ?? '',
        status: IdeaStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => IdeaStatus.active,
        ),
        notes: List<String>.from(j['notes'] ?? []),
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        aiScript: j['aiScript'],
      );
}
