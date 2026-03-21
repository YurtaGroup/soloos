import 'package:uuid/uuid.dart';

enum SuggestionType { contact, reminder, qualityTime, appreciation, followUp, birthday }

class FamilySuggestion {
  final String id;
  final String personId;
  final String personName;
  final SuggestionType suggestionType;
  final String title;
  final String description;
  final double confidence;
  final DateTime createdAt;
  DateTime? dismissedAt;
  DateTime? actedOnAt;

  FamilySuggestion({
    String? id,
    required this.personId,
    required this.personName,
    required this.suggestionType,
    required this.title,
    required this.description,
    this.confidence = 0.8,
    DateTime? createdAt,
    this.dismissedAt,
    this.actedOnAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isDismissed => dismissedAt != null;
  bool get isActedOn => actedOnAt != null;
  bool get isActive => !isDismissed && !isActedOn;

  String get emoji {
    switch (suggestionType) {
      case SuggestionType.contact: return '💬';
      case SuggestionType.reminder: return '⏰';
      case SuggestionType.qualityTime: return '🌟';
      case SuggestionType.appreciation: return '💛';
      case SuggestionType.followUp: return '🔄';
      case SuggestionType.birthday: return '🎂';
    }
  }
}
