class Task {
  final String id;
  String title;
  String notes;
  bool isDone;
  String status; // todo, in_progress, done
  String priority; // high, medium, low
  String? url;
  DateTime? dueDate;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.isDone = false,
    this.status = 'todo',
    this.priority = 'medium',
    this.url,
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'isDone': isDone,
        'status': status,
        'priority': priority,
        'url': url,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'],
        title: j['title'],
        notes: j['notes'] ?? '',
        isDone: j['isDone'] ?? false,
        status: j['status'] ?? 'todo',
        priority: j['priority'] ?? 'medium',
        url: j['url'],
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );

  factory Task.fromRow(Map<String, dynamic> r) => Task(
        id: r['id'],
        title: r['title'],
        notes: r['notes'] ?? '',
        isDone: r['is_done'] ?? false,
        status: r['status'] ?? (r['is_done'] == true ? 'done' : 'todo'),
        priority: r['priority'] ?? 'medium',
        url: r['url'],
        dueDate: r['due_date'] != null ? DateTime.tryParse(r['due_date']) : null,
        createdAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toRow(String projectId) => {
        'id': id,
        'project_id': projectId,
        'title': title,
        'notes': notes,
        'is_done': isDone,
        'status': status,
        'priority': priority,
        'url': url,
        'due_date': dueDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
