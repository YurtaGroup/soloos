import '../../domain/models/family_person.dart';
import '../../domain/models/family_reminder.dart';
import '../../domain/models/relationship_note.dart';

abstract class FamilyRepository {
  List<FamilyPerson> getAllPeople();
  FamilyPerson? getPersonById(String id);
  Future<void> savePerson(FamilyPerson person);
  Future<void> updatePerson(FamilyPerson person);
  Future<void> deletePerson(String id);

  List<FamilyReminder> getAllReminders();
  List<FamilyReminder> getRemindersForPerson(String personId);
  Future<void> saveReminder(FamilyReminder reminder);
  Future<void> completeReminder(String reminderId);
  Future<void> deleteReminder(String id);

  List<RelationshipNote> getNotesForPerson(String personId);
  Future<void> saveNote(RelationshipNote note);
  Future<void> deleteNote(String id);
}
