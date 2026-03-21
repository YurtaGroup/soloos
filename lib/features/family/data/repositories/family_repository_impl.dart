import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/family_person.dart';
import '../../domain/models/family_reminder.dart';
import '../../domain/models/relationship_note.dart';
import 'family_repository.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  static const _peopleKey = 'family_people';
  static const _remindersKey = 'family_reminders';
  static const _notesKey = 'family_notes';

  SharedPreferences? _prefs;

  SharedPreferences get prefs {
    if (_prefs == null) throw Exception('FamilyRepository not initialized');
    return _prefs!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── People ─────────────────────────────────────────────────────────────────

  @override
  List<FamilyPerson> getAllPeople() {
    final raw = prefs.getString(_peopleKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => FamilyPerson.fromJson(e as Map<String, dynamic>))
        .where((p) => p.isActive)
        .toList();
  }

  @override
  FamilyPerson? getPersonById(String id) =>
      getAllPeople().where((p) => p.id == id).firstOrNull;

  @override
  Future<void> savePerson(FamilyPerson person) async {
    final people = _allPeopleRaw()..add(person);
    await _persistPeople(people);
  }

  @override
  Future<void> updatePerson(FamilyPerson person) async {
    final people = _allPeopleRaw()
        .map((p) => p.id == person.id ? person : p)
        .toList();
    await _persistPeople(people);
  }

  @override
  Future<void> deletePerson(String id) async {
    // Soft delete
    final people = _allPeopleRaw().map((p) {
      if (p.id != id) return p;
      return FamilyPerson.fromJson({...p.toJson(), 'isActive': false});
    }).toList();
    await _persistPeople(people);
  }

  // ── Reminders ──────────────────────────────────────────────────────────────

  @override
  List<FamilyReminder> getAllReminders() {
    final raw = prefs.getString(_remindersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => FamilyReminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<FamilyReminder> getRemindersForPerson(String personId) =>
      getAllReminders().where((r) => r.personId == personId).toList();

  @override
  Future<void> saveReminder(FamilyReminder reminder) async {
    final reminders = getAllReminders()..add(reminder);
    await _persistReminders(reminders);
  }

  @override
  Future<void> completeReminder(String reminderId) async {
    final reminders = getAllReminders().map((r) {
      if (r.id != reminderId) return r;
      r.isCompleted = true;
      r.completedAt = DateTime.now();
      r.updatedAt = DateTime.now();
      return r;
    }).toList();

    // Spawn next recurring instance if needed
    final completed = reminders.firstWhere((r) => r.id == reminderId);
    final next = completed.nextRecurringDate();
    if (next != null) {
      reminders.add(FamilyReminder(
        personId: completed.personId,
        title: completed.title,
        description: completed.description,
        reminderType: completed.reminderType,
        dueAt: next,
        recurrenceType: completed.recurrenceType,
      ));
    }

    await _persistReminders(reminders);
  }

  @override
  Future<void> deleteReminder(String id) async {
    final reminders = getAllReminders()..removeWhere((r) => r.id == id);
    await _persistReminders(reminders);
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  @override
  List<RelationshipNote> getNotesForPerson(String personId) {
    final raw = prefs.getString(_notesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => RelationshipNote.fromJson(e as Map<String, dynamic>))
        .where((n) => n.personId == personId)
        .toList();
  }

  @override
  Future<void> saveNote(RelationshipNote note) async {
    final raw = prefs.getString(_notesKey);
    final notes = raw == null
        ? <RelationshipNote>[]
        : (jsonDecode(raw) as List)
            .map((e) => RelationshipNote.fromJson(e as Map<String, dynamic>))
            .toList()
      ..add(note);
    await prefs.setString(
        _notesKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  @override
  Future<void> deleteNote(String id) async {
    final raw = prefs.getString(_notesKey);
    if (raw == null) return;
    final notes = (jsonDecode(raw) as List)
        .map((e) => RelationshipNote.fromJson(e as Map<String, dynamic>))
        .where((n) => n.id != id)
        .toList();
    await prefs.setString(
        _notesKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<FamilyPerson> _allPeopleRaw() {
    final raw = prefs.getString(_peopleKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => FamilyPerson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persistPeople(List<FamilyPerson> list) =>
      prefs.setString(_peopleKey, jsonEncode(list.map((p) => p.toJson()).toList()));

  Future<void> _persistReminders(List<FamilyReminder> list) =>
      prefs.setString(_remindersKey, jsonEncode(list.map((r) => r.toJson()).toList()));
}
