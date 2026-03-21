import '../../domain/models/family_person.dart';
import '../../domain/models/family_reminder.dart';
import '../../domain/models/family_suggestion.dart';

/// Rule-based suggestion engine — no external LLM needed.
/// Generates actionable, calm suggestions for a solopreneur.
class FamilyAiSuggestionService {
  static const _maxSuggestions = 4;

  List<FamilySuggestion> generateDailySuggestions({
    required List<FamilyPerson> people,
    required List<FamilyReminder> reminders,
  }) {
    final suggestions = <FamilySuggestion>[];

    for (final person in people) {
      if (!person.isActive) continue;
      final personSuggestions = generateSuggestionsForPerson(
        person,
        reminders: reminders.where((r) => r.personId == person.id).toList(),
      );
      suggestions.addAll(personSuggestions);
    }

    // Sort by urgency (higher confidence/priority first)
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    return suggestions.take(_maxSuggestions).toList();
  }

  List<FamilySuggestion> generateSuggestionsForPerson(
    FamilyPerson person, {
    List<FamilyReminder> reminders = const [],
  }) {
    final suggestions = <FamilySuggestion>[];

    // 1. Birthday coming up
    if (person.isBirthdayToday) {
      suggestions.add(FamilySuggestion(
        personId: person.id,
        personName: person.displayName,
        suggestionType: SuggestionType.birthday,
        title: '🎂 Today is ${person.displayName}\'s birthday!',
        description: 'Don\'t forget to call or message them today.',
        confidence: 1.0,
      ));
    } else if (person.isBirthdaySoon) {
      final days = person.daysUntilBirthday!;
      suggestions.add(FamilySuggestion(
        personId: person.id,
        personName: person.displayName,
        suggestionType: SuggestionType.birthday,
        title: '${person.displayName}\'s birthday in $days days',
        description: 'Plan something special or at least send a message.',
        confidence: 0.95,
      ));
    }

    // 2. Overdue contact
    if (person.isContactOverdue) {
      final days = person.daysSinceContact!;
      suggestions.add(FamilySuggestion(
        personId: person.id,
        personName: person.displayName,
        suggestionType: SuggestionType.contact,
        title: 'Check in with ${person.displayName}',
        description: 'You haven\'t been in touch for $days days '
            '(goal: every ${person.contactFrequencyGoalDays} days).',
        confidence: 0.9,
      ));
    }

    // 3. Never contacted — high priority person
    if (person.hasNeverBeenContacted &&
        (person.priorityLevel == PriorityLevel.high ||
            person.priorityLevel == PriorityLevel.critical)) {
      suggestions.add(FamilySuggestion(
        personId: person.id,
        personName: person.displayName,
        suggestionType: SuggestionType.contact,
        title: 'Reach out to ${person.displayName}',
        description: 'You\'ve never logged contact with them. '
            'A quick message goes a long way.',
        confidence: 0.75,
      ));
    }

    // 4. High-priority person with no contact in 30+ days
    final days = person.daysSinceContact;
    if (days != null &&
        days >= 30 &&
        (person.priorityLevel == PriorityLevel.high ||
            person.priorityLevel == PriorityLevel.critical)) {
      suggestions.add(FamilySuggestion(
        personId: person.id,
        personName: person.displayName,
        suggestionType: SuggestionType.qualityTime,
        title: 'Quality time with ${person.displayName}?',
        description: '$days days since your last contact. '
            'Schedule something meaningful this week.',
        confidence: 0.7,
      ));
    }

    // 5. Overdue reminder
    final overdueReminders = reminders.where((r) => r.isOverdue).toList();
    if (overdueReminders.isNotEmpty) {
      final r = overdueReminders.first;
      suggestions.add(FamilySuggestion(
        personId: person.id,
        personName: person.displayName,
        suggestionType: SuggestionType.reminder,
        title: 'Overdue: ${r.title}',
        description: 'This was due ${_daysAgo(r.dueAt)} ago.',
        confidence: 0.85,
      ));
    }

    return suggestions;
  }

  String _daysAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return '1 day';
    return '$diff days';
  }
}
