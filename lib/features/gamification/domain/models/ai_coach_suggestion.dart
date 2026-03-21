import 'gamification_event.dart';

enum CoachTone { encouraging, neutral, reflective, celebratory }

/// A calm, short motivational nudge from the AI coach.
class AiCoachSuggestion {
  final String id;
  final String message;
  final CoachTone tone;
  final GamificationCategory? focusCategory;
  final DateTime createdAt;
  final bool isDismissed;

  const AiCoachSuggestion({
    required this.id,
    required this.message,
    required this.tone,
    this.focusCategory,
    required this.createdAt,
    this.isDismissed = false,
  });

  String get toneEmoji => switch (tone) {
        CoachTone.encouraging => '💪',
        CoachTone.neutral => '💭',
        CoachTone.reflective => '🪞',
        CoachTone.celebratory => '🎉',
      };

  AiCoachSuggestion dismiss() => AiCoachSuggestion(
        id: id,
        message: message,
        tone: tone,
        focusCategory: focusCategory,
        createdAt: createdAt,
        isDismissed: true,
      );

  factory AiCoachSuggestion.fromJson(Map<String, dynamic> json) =>
      AiCoachSuggestion(
        id: json['id'] as String,
        message: json['message'] as String,
        tone: CoachTone.values.byName(json['tone'] as String),
        focusCategory: json['focusCategory'] != null
            ? GamificationCategory.values
                .byName(json['focusCategory'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isDismissed: json['isDismissed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'tone': tone.name,
        if (focusCategory != null) 'focusCategory': focusCategory!.name,
        'createdAt': createdAt.toIso8601String(),
        'isDismissed': isDismissed,
      };
}
