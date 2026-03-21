import 'package:uuid/uuid.dart';

enum NoteType { memory, preference, event, concern, gratitude, giftIdea, other }

extension NoteTypeLabel on NoteType {
  String get label {
    switch (this) {
      case NoteType.memory: return 'Memory';
      case NoteType.preference: return 'Preference';
      case NoteType.event: return 'Event';
      case NoteType.concern: return 'Concern';
      case NoteType.gratitude: return 'Gratitude';
      case NoteType.giftIdea: return 'Gift Idea';
      case NoteType.other: return 'Note';
    }
  }

  String get emoji {
    switch (this) {
      case NoteType.memory: return '💭';
      case NoteType.preference: return '❤️';
      case NoteType.event: return '📅';
      case NoteType.concern: return '💛';
      case NoteType.gratitude: return '🙏';
      case NoteType.giftIdea: return '🎁';
      case NoteType.other: return '📝';
    }
  }
}

class RelationshipNote {
  final String id;
  final String personId;
  final String content;
  final NoteType noteType;
  final DateTime createdAt;
  DateTime updatedAt;

  RelationshipNote({
    String? id,
    required this.personId,
    required this.content,
    this.noteType = NoteType.other,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'content': content,
        'noteType': noteType.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RelationshipNote.fromJson(Map<String, dynamic> j) => RelationshipNote(
        id: j['id'],
        personId: j['personId'],
        content: j['content'],
        noteType: NoteType.values.firstWhere(
          (e) => e.name == j['noteType'],
          orElse: () => NoteType.other,
        ),
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
      );
}
