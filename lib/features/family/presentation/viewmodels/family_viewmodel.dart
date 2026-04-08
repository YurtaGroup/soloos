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
import '../../../../services/api_service.dart';

class FamilyViewModel extends ChangeNotifier {
  FamilyViewModel({FamilyRepositoryImpl? repo})
      : _repo = repo ?? FamilyRepositoryImpl() {
    _init();
  }

  final FamilyRepositoryImpl _repo;
  FamilyReminderService? _reminderService;
  final _suggestionService = FamilyAiSuggestionService();

  bool get _useDb => ApiService.isAuthenticated;

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
      _reminderService?.getUpcomingReminders() ?? [];

  List<FamilyReminder> get overdueReminders =>
      _reminderService?.getOverdueReminders() ?? [];

  List<FamilyReminder> get dueTodayReminders =>
      _reminderService?.getDueTodayReminders() ?? [];

  List<FamilySuggestion> get suggestions =>
      _suggestions.where((s) => s.isActive).toList();

  int get totalPeople => _people.length;
  int get overdueContactCount => overdueContacts.length;
  int get dueTodayCount => _reminderService?.getDueTodayCount() ?? 0;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await _repo.init();
    _reminderService = FamilyReminderService(_repo);
    await _refresh();
    await _reminderService!.generateBirthdayRemindersIfNeeded(_people);
    _reminders = _useDb
        ? await _loadRemindersFromDb()
        : _repo.getAllReminders();
    notifyListeners();
  }

  void reload() => _init();

  Future<void> _refresh() async {
    try {
      if (_useDb) {
        final rows = await ApiService.getAll('family_people', orderBy: 'created_at');
        _people = rows.map((r) => FamilyPerson.fromRow(r)).where((p) => p.isActive).toList();
        _reminders = await _loadRemindersFromDb();
      } else {
        _people = _repo.getAllPeople();
        _reminders = _repo.getAllReminders();
      }
    } catch (_) {
      _people = _repo.getAllPeople();
      _reminders = _repo.getAllReminders();
    }
    await _loadNotesForPeople();
    _suggestions = _suggestionService.generateDailySuggestions(
      people: _people,
      reminders: _reminders,
    );
    notifyListeners();
  }

  Future<List<FamilyReminder>> _loadRemindersFromDb() async {
    final rows = await ApiService.getAll('family_reminders', orderBy: 'due_at', ascending: true);
    return rows.map((r) => FamilyReminder.fromRow(r)).toList();
  }

  // ── People ─────────────────────────────────────────────────────────────────

  Future<void> addPerson(FamilyPerson person) async {
    if (_useDb) {
      await ApiService.insert('family_people', person.toRow());
    }
    await _repo.savePerson(person);
    await _refresh();
  }

  Future<void> updatePerson(FamilyPerson person) async {
    person.updatedAt = DateTime.now();
    if (_useDb) {
      await ApiService.update('family_people', person.id, {
        'full_name': person.fullName,
        'notes_summary': person.notesSummary,
        'last_contact_at': person.lastContactAt?.toIso8601String(),
        'priority_level': person.priorityLevel.name,
        'is_active': person.isActive,
      });
    }
    await _repo.updatePerson(person);
    await _refresh();
  }

  Future<void> deletePerson(String id) async {
    if (_useDb) {
      await ApiService.update('family_people', id, {'is_active': false});
    }
    await _repo.deletePerson(id);
    await _refresh();
  }

  /// One-tap "contacted today" action
  Future<void> markContactedToday(String personId) async {
    final person = _useDb
        ? _people.where((p) => p.id == personId).firstOrNull
        : _repo.getPersonById(personId);
    if (person == null) return;
    person.lastContactAt = DateTime.now();
    person.updatedAt = DateTime.now();
    if (_useDb) {
      await ApiService.update('family_people', personId, {
        'last_contact_at': person.lastContactAt!.toIso8601String(),
      });
    }
    await _repo.updatePerson(person);
    GamificationEventBus.emit(GamificationEventType.contactedPerson,
        description: person.displayName);
    await _refresh();
  }

  // ── Reminders ──────────────────────────────────────────────────────────────

  Future<void> addReminder(FamilyReminder reminder) async {
    if (_useDb) {
      await ApiService.insert('family_reminders', reminder.toRow());
    }
    await _repo.saveReminder(reminder);
    await _refresh();
  }

  Future<void> completeReminder(String reminderId) async {
    if (_useDb) {
      await ApiService.update('family_reminders', reminderId, {
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      });
    }
    await _reminderService?.completeReminder(reminderId);
    GamificationEventBus.emit(GamificationEventType.reminderCompleted);
    await _refresh();
  }

  Future<void> deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    await _refresh();
    if (_useDb) {
      try { await ApiService.delete('family_reminders', id); } catch (e) { debugPrint('API delete reminder failed: $e'); }
    }
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  Map<String, List<RelationshipNote>> _notesCache = {};

  List<RelationshipNote> getNotesForPerson(String personId) =>
      _notesCache[personId] ?? _repo.getNotesForPerson(personId);

  Future<void> _loadNotesForPeople() async {
    if (!_useDb) return;
    try {
      final rows = await ApiService.getAll('relationship_notes', orderBy: 'created_at');
      _notesCache = {};
      for (final r in rows) {
        final note = RelationshipNote.fromRow(r);
        _notesCache.putIfAbsent(note.personId, () => []).add(note);
      }
    } catch (e) {
      debugPrint('Failed to load relationship notes: $e');
    }
  }

  Future<void> addNote(RelationshipNote note) async {
    if (_useDb) {
      await ApiService.insert('relationship_notes', note.toRow());
    }
    await _repo.saveNote(note);
    _notesCache.putIfAbsent(note.personId, () => []).add(note);
    GamificationEventBus.emit(GamificationEventType.noteAdded);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _repo.deleteNote(id);
    for (final list in _notesCache.values) {
      list.removeWhere((n) => n.id == id);
    }
    notifyListeners();
    if (_useDb) {
      try { await ApiService.delete('relationship_notes', id); } catch (e) { debugPrint('API delete note failed: $e'); }
    }
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
