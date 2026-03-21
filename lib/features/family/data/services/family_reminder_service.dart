import '../../domain/models/family_person.dart';
import '../../domain/models/family_reminder.dart';
import '../repositories/family_repository.dart';

class FamilyReminderService {
  final FamilyRepository _repo;

  FamilyReminderService(this._repo);

  List<FamilyReminder> getUpcomingReminders({int withinDays = 7}) {
    final cutoff = DateTime.now().add(Duration(days: withinDays));
    return _repo.getAllReminders()
        .where((r) => !r.isCompleted && r.dueAt.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  List<FamilyReminder> getOverdueReminders() =>
      _repo.getAllReminders().where((r) => r.isOverdue).toList()
        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  List<FamilyReminder> getDueTodayReminders() =>
      _repo.getAllReminders().where((r) => r.isDueToday).toList();

  int getDueTodayCount() => getDueTodayReminders().length;

  int getOverdueCount() => getOverdueReminders().length;

  Future<void> completeReminder(String reminderId) =>
      _repo.completeReminder(reminderId);

  /// Auto-create birthday reminders for people with birthdays in the next 14 days
  /// that don't already have a reminder. Call on app launch.
  Future<void> generateBirthdayRemindersIfNeeded(List<FamilyPerson> people) async {
    final existing = _repo.getAllReminders()
        .where((r) => r.reminderType == ReminderType.birthday)
        .map((r) => r.personId)
        .toSet();

    for (final person in people) {
      if (person.birthday == null) continue;
      if (existing.contains(person.id)) continue;

      final daysUntil = person.daysUntilBirthday;
      if (daysUntil == null || daysUntil > 14) continue;

      final dueDate = DateTime.now().add(Duration(days: daysUntil));
      await _repo.saveReminder(FamilyReminder(
        personId: person.id,
        title: '🎂 ${person.displayName}\'s Birthday',
        description: daysUntil == 0
            ? 'Today is ${person.displayName}\'s birthday!'
            : '${person.displayName}\'s birthday is in $daysUntil days.',
        reminderType: ReminderType.birthday,
        dueAt: DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0),
        recurrenceType: RecurrenceType.yearly,
      ));
    }
  }
}
