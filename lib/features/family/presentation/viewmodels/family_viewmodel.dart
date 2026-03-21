import 'package:flutter/foundation.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';
import '../../data/repositories/family_repository_impl.dart';
import '../../data/services/family_ai_suggestion_service.dart';
import '../../data/services/family_reminder_service.dart';
import '../../domain/models/family_person.dart';
import '../../domain/models/family_reminder.dart';
import '../../domain/models/family_suggestion.dart';
import '../../domain/models/relationship_note.dart';

class FamilyViewModel extends ChangeNotifier {
  FamilyViewModel({FamilyRepositoryImpl? repo})
      : _repo = repo ?? FamilyRepositoryImpl() {
    _init();
  }

  final FamilyRepositoryImpl _repo;
  late final FamilyReminderService _reminderService;
  final _suggestionService = FamilyAiSuggestionService();

  List<FamilyPerson> _people = [];
  List<FamilyReminder> _reminders = [];
  List<FamilySuggestion> _suggestions = [];

  // ── Getters ────────────────────────────────────────────────────────────────

  List<FamilyPerson> get people => List.unmodifiable(_people);

  List<FamilyPerson> get peopleNeedingAttention =>
      _people.where((p) => p.needsAttentionToday).toList()
        ..sort((a, b) => b.attentionScore.compareTo(a.attentionScore));

  List<FamilyPerson> get overdueContacts =>
      _people.where((p) => p.isContactOverdue).toList();

  List<FamilyPerson> get upcomingBirthdays =>
      _people.where((p) => p.daysUntilBirthday != null && p.daysUntilBirthday! <= 14).toList()
        ..sort((a, b) => a.daysUntilBirthday!.compareTo(b.daysUntilBirthday!));

  List<FamilyReminder> get upcomingReminders =>
      _reminderService.getUpcomingReminders();

  List<FamilyReminder> get overdueReminders =>
      _reminderService.getOverdueReminders();

  List<FamilyReminder> get dueTodayReminders =>
      _reminderService.getDueTodayReminders();

  List<FamilySuggestion> get suggestions =>
      _suggestions.where((s) => s.isActive).toList();

  int get totalPeople => _people.length;
  int get overdueContactCount => overdueContacts.length;
  int get dueTodayCount => _reminderService.getDueTodayCount();

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await _repo.init();
    _reminderService = FamilyReminderService(_repo);
    await _refresh();
    await _reminderService.generateBirthdayRemindersIfNeeded(_people);
    _reminders = _repo.getAllReminders();
    notifyListeners();
  }

  Future<void> _refresh() async {
    _people = _repo.getAllPeople();
    _reminders = _repo.getAllReminders();
    _suggestions = _suggestionService.generateDailySuggestions(
      people: _people,
      reminders: _reminders,
    );
    notifyListeners();
  }

  // ── People ─────────────────────────────────────────────────────────────────

  Future<void> addPerson(FamilyPerson person) async {
    await _repo.savePerson(person);
    await _refresh();
  }

  Future<void> updatePerson(FamilyPerson person) async {
    person.updatedAt = DateTime.now();
    await _repo.updatePerson(person);
    await _refresh();
  }

  Future<void> deletePerson(String id) async {
    await _repo.deletePerson(id);
    await _refresh();
  }

  /// One-tap "contacted today" action
  Future<void> markContactedToday(String personId) async {
    final person = _repo.getPersonById(personId);
    if (person == null) return;
    person.lastContactAt = DateTime.now();
    person.updatedAt = DateTime.now();
    await _repo.updatePerson(person);
    GamificationEventBus.emit(GamificationEventType.contactedPerson,
        description: person.displayName);
    await _refresh();
  }

  // ── Reminders ──────────────────────────────────────────────────────────────

  Future<void> addReminder(FamilyReminder reminder) async {
    await _repo.saveReminder(reminder);
    await _refresh();
  }

  Future<void> completeReminder(String reminderId) async {
    await _reminderService.completeReminder(reminderId);
    GamificationEventBus.emit(GamificationEventType.reminderCompleted);
    await _refresh();
  }

  Future<void> deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    await _refresh();
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  List<RelationshipNote> getNotesForPerson(String personId) =>
      _repo.getNotesForPerson(personId);

  Future<void> addNote(RelationshipNote note) async {
    await _repo.saveNote(note);
    GamificationEventBus.emit(GamificationEventType.noteAdded);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _repo.deleteNote(id);
    notifyListeners();
  }

  // ── Suggestions ────────────────────────────────────────────────────────────

  void dismissSuggestion(String id) {
    final s = _suggestions.firstWhere((s) => s.id == id);
    s.dismissedAt = DateTime.now();
    notifyListeners();
  }

  void markSuggestionActedOn(String id) {
    final s = _suggestions.firstWhere((s) => s.id == id);
    s.actedOnAt = DateTime.now();
    notifyListeners();
  }

  // ── Person detail ──────────────────────────────────────────────────────────

  List<FamilyReminder> getRemindersForPerson(String personId) =>
      _repo.getRemindersForPerson(personId);

  List<FamilySuggestion> getSuggestionsForPerson(String personId) =>
      _suggestionService.generateSuggestionsForPerson(
        _repo.getPersonById(personId)!,
        reminders: _repo.getRemindersForPerson(personId),
      );
}
