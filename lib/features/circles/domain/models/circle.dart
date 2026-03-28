class Circle {
  final String id;
  String name;
  String emoji;
  final String ownerId;
  final String myRole;
  final List<CircleMember> members;
  final List<String> modules;
  final DateTime createdAt;

  Circle({
    required this.id,
    required this.name,
    this.emoji = '',
    required this.ownerId,
    this.myRole = 'member',
    this.members = const [],
    this.modules = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOwner => myRole == 'owner';

  factory Circle.fromJson(Map<String, dynamic> j) => Circle(
        id: j['id'],
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '',
        ownerId: j['ownerId'] ?? j['owner_id'] ?? '',
        myRole: j['myRole'] ?? 'member',
        members: (j['members'] as List?)
                ?.map((m) => CircleMember.fromJson(m))
                .toList() ??
            [],
        modules: (j['modules'] as List?)?.map((m) => m.toString()).toList() ?? [],
        createdAt: DateTime.tryParse(j['createdAt'] ?? j['created_at'] ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'modules': modules,
      };
}

class CircleMember {
  final String id;
  final String userId;
  final String email;
  final String role;
  final DateTime joinedAt;

  CircleMember({
    required this.id,
    required this.userId,
    this.email = '',
    this.role = 'member',
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory CircleMember.fromJson(Map<String, dynamic> j) => CircleMember(
        id: j['id'] ?? '',
        userId: j['userId'] ?? j['user_id'] ?? '',
        email: j['email'] ?? '',
        role: j['role'] ?? 'member',
        joinedAt: DateTime.tryParse(j['joinedAt'] ?? j['joined_at'] ?? '') ??
            DateTime.now(),
      );
}
