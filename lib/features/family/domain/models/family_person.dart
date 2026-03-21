import 'package:uuid/uuid.dart';

enum RelationshipType { spouse, child, mother, father, sibling, friend, mentor, other }

enum PriorityLevel { low, medium, high, critical }

extension RelationshipTypeLabel on RelationshipType {
  String get label {
    switch (this) {
      case RelationshipType.spouse: return 'Spouse';
      case RelationshipType.child: return 'Child';
      case RelationshipType.mother: return 'Mother';
      case RelationshipType.father: return 'Father';
      case RelationshipType.sibling: return 'Sibling';
      case RelationshipType.friend: return 'Friend';
      case RelationshipType.mentor: return 'Mentor';
      case RelationshipType.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case RelationshipType.spouse: return '❤️';
      case RelationshipType.child: return '👶';
      case RelationshipType.mother: return '👩';
      case RelationshipType.father: return '👨';
      case RelationshipType.sibling: return '🫂';
      case RelationshipType.friend: return '🤝';
      case RelationshipType.mentor: return '🌟';
      case RelationshipType.other: return '👤';
    }
  }
}

class FamilyPerson {
  final String id;
  final String fullName;
  final RelationshipType relationshipType;
  final String? nickname;
  final DateTime? birthday;
  final String? phone;
  final String? email;
  String notesSummary;
  DateTime? lastContactAt;
  int? contactFrequencyGoalDays; // null = no goal
  PriorityLevel priorityLevel;
  List<String> tags;
  List<String> favoritethings;
  final bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  FamilyPerson({
    String? id,
    required this.fullName,
    required this.relationshipType,
    this.nickname,
    this.birthday,
    this.phone,
    this.email,
    this.notesSummary = '',
    this.lastContactAt,
    this.contactFrequencyGoalDays,
    this.priorityLevel = PriorityLevel.medium,
    List<String>? tags,
    List<String>? favoritethings,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        favoritethings = favoritethings ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get displayName => nickname ?? fullName;

  int? get daysSinceContact {
    if (lastContactAt == null) return null;
    return DateTime.now().difference(lastContactAt!).inDays;
  }

  bool get isContactOverdue {
    if (contactFrequencyGoalDays == null || lastContactAt == null) return false;
    return daysSinceContact! > contactFrequencyGoalDays!;
  }

  bool get hasNeverBeenContacted => lastContactAt == null;

  int? get daysUntilBirthday {
    if (birthday == null) return null;
    final now = DateTime.now();
    var next = DateTime(now.year, birthday!.month, birthday!.day);
    if (next.isBefore(now)) {
      next = DateTime(now.year + 1, birthday!.month, birthday!.day);
    }
    return next.difference(now).inDays;
  }

  bool get isBirthdaySoon => daysUntilBirthday != null && daysUntilBirthday! <= 7;
  bool get isBirthdayToday => daysUntilBirthday == 0;

  /// Attention urgency score (0–100). Higher = needs more attention.
  int get attentionScore {
    int score = 0;
    if (isContactOverdue) score += 40;
    if (hasNeverBeenContacted) score += 30;
    if (isBirthdaySoon) score += 25;
    if (isBirthdayToday) score += 50;
    if (priorityLevel == PriorityLevel.critical) score += 20;
    if (priorityLevel == PriorityLevel.high) score += 10;
    return score.clamp(0, 100);
  }

  bool get needsAttentionToday =>
      attentionScore >= 30 || isBirthdayToday || isContactOverdue;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'relationshipType': relationshipType.name,
        'nickname': nickname,
        'birthday': birthday?.toIso8601String(),
        'phone': phone,
        'email': email,
        'notesSummary': notesSummary,
        'lastContactAt': lastContactAt?.toIso8601String(),
        'contactFrequencyGoalDays': contactFrequencyGoalDays,
        'priorityLevel': priorityLevel.name,
        'tags': tags,
        'favoritethings': favoritethings,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FamilyPerson.fromJson(Map<String, dynamic> j) => FamilyPerson(
        id: j['id'],
        fullName: j['fullName'],
        relationshipType: RelationshipType.values.firstWhere(
          (e) => e.name == j['relationshipType'],
          orElse: () => RelationshipType.other,
        ),
        nickname: j['nickname'],
        birthday: j['birthday'] != null ? DateTime.tryParse(j['birthday']) : null,
        phone: j['phone'],
        email: j['email'],
        notesSummary: j['notesSummary'] ?? '',
        lastContactAt: j['lastContactAt'] != null
            ? DateTime.tryParse(j['lastContactAt'])
            : null,
        contactFrequencyGoalDays: j['contactFrequencyGoalDays'],
        priorityLevel: PriorityLevel.values.firstWhere(
          (e) => e.name == j['priorityLevel'],
          orElse: () => PriorityLevel.medium,
        ),
        tags: (j['tags'] as List?)?.cast<String>() ?? [],
        favoritethings: (j['favoritethings'] as List?)?.cast<String>() ?? [],
        isActive: j['isActive'] ?? true,
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
      );
}
