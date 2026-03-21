class Task {
  final String id;
  String title;
  String notes;
  bool isDone;
  String priority; // high, medium, low
  DateTime? dueDate;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.isDone = false,
    this.priority = 'medium',
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'isDone': isDone,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'],
        title: j['title'],
        notes: j['notes'] ?? '',
        isDone: j['isDone'] ?? false,
        priority: j['priority'] ?? 'medium',
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}
