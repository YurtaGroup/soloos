class Contact {
  final String id;
  String name;
  String emoji;
  DateTime birthday;
  String relationship;
  String notes;
  DateTime? lastContacted;

  Contact({
    required this.id,
    required this.name,
    this.emoji = '👤',
    required this.birthday,
    this.relationship = 'friend',
    this.notes = '',
    this.lastContacted,
  });

  int get daysUntilBirthday {
    final now = DateTime.now();
    final next = DateTime(now.year, birthday.month, birthday.day);
    final diff = next.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff < 0 ? diff + 365 : diff;
  }

  /// Days since last contact, or -1 if never contacted.
  int get daysSinceContact {
    if (lastContacted == null) return -1;
    return DateTime.now().difference(lastContacted!).inDays;
  }

  /// True if not contacted in over 30 days (or never contacted).
  bool get isContactOverdue => daysSinceContact == -1 || daysSinceContact > 30;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'birthday': birthday.toIso8601String(),
        'relationship': relationship,
        'notes': notes,
        'lastContacted': lastContacted?.toIso8601String(),
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'] ?? '👤',
        birthday: DateTime.parse(j['birthday']),
        relationship: j['relationship'] ?? 'friend',
        notes: j['notes'] ?? '',
        lastContacted: j['lastContacted'] != null ? DateTime.tryParse(j['lastContacted']) : null,
      );

  factory Contact.fromRow(Map<String, dynamic> r) => Contact(
        id: r['id'],
        name: r['name'],
        emoji: r['emoji'] ?? '👤',
        birthday: DateTime.parse(r['birthday']),
        relationship: r['relationship'] ?? 'friend',
        notes: r['notes'] ?? '',
        lastContacted: r['last_contacted'] != null ? DateTime.tryParse(r['last_contacted']) : null,
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'birthday': birthday.toIso8601String(),
        'relationship': relationship,
        'notes': notes,
        'last_contacted': lastContacted?.toIso8601String(),
      };
}
