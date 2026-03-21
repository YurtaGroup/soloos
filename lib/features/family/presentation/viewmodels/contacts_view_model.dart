import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/contact.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/google_calendar_service.dart';

class ContactsViewModel extends ChangeNotifier {
  ContactsViewModel({
    StorageService? storage,
    GoogleCalendarService? calService,
  })  : _storage = storage ?? StorageService(),
        _calService = calService ?? GoogleCalendarService() {
    _loadContacts();
  }

  final StorageService _storage;
  final GoogleCalendarService _calService;

  List<Contact> _contacts = [];
  bool _importing = false;

  List<Contact> get contacts => _contacts;
  bool get importing => _importing;
  bool get isGoogleSignedIn => _calService.isSignedIn;

  List<Contact> get upcoming =>
      _contacts.where((c) => c.daysUntilBirthday <= 30).toList();
  List<Contact> get rest =>
      _contacts.where((c) => c.daysUntilBirthday > 30).toList();

  void _loadContacts() {
    _contacts = _storage.getContacts()
      ..sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
    notifyListeners();
  }

  void reload() => _loadContacts();

  Future<String> importFromGoogle() async {
    if (!_calService.isSignedIn) return 'connect_google';
    _importing = true;
    notifyListeners();

    final imported = await _calService.importBirthdays();
    if (imported.isEmpty) {
      _importing = false;
      notifyListeners();
      return 'No birthdays found in Google Contacts';
    }

    final existing = _storage.getContacts();
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();
    int added = 0;
    for (final c in imported) {
      if (!existingNames.contains(c.name.toLowerCase())) {
        existing.add(c);
        added++;
      }
    }
    await _storage.saveContacts(existing);
    _importing = false;
    _loadContacts();
    return 'Imported $added new contacts from Google';
  }

  Future<bool> addContact({
    required String name,
    required String emoji,
    required DateTime birthday,
    String relationship = 'friend',
    String notes = '',
  }) async {
    if (name.trim().isEmpty) return false;
    final contacts = _storage.getContacts()
      ..add(Contact(
        id: const Uuid().v4(),
        name: name.trim(),
        emoji: emoji,
        birthday: birthday,
        relationship: relationship,
        notes: notes.trim(),
      ));
    await _storage.saveContacts(contacts);
    _loadContacts();
    return true;
  }

  Future<void> deleteContact(Contact contact) async {
    _contacts.remove(contact);
    await _storage.saveContacts(_contacts);
    _loadContacts();
  }
}
