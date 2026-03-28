import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/contact.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/google_calendar_service.dart';
import '../../../../services/pro_service.dart';
import '../../../../services/notification_service.dart';

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
  bool _loading = false;
  bool _importing = false;

  List<Contact> get contacts => _contacts;
  bool get loading => _loading;
  bool get importing => _importing;
  bool get isGoogleSignedIn => _calService.isSignedIn;

  List<Contact> get upcoming =>
      _contacts.where((c) => c.daysUntilBirthday <= 30).toList();
  List<Contact> get rest =>
      _contacts.where((c) => c.daysUntilBirthday > 30).toList();

  bool get _useDb => ApiService.isAuthenticated;

  Future<void> _loadContacts() async {
    _loading = true;
    notifyListeners();

    try {
      if (_useDb) {
        final rows = await ApiService.getAll('contacts', orderBy: 'birthday');
        _contacts = rows.map((r) => Contact.fromRow(r)).toList()
          ..sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
      } else {
        _contacts = _storage.getContacts()
          ..sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
      }
    } catch (_) {
      _contacts = _storage.getContacts()
        ..sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
    }

    _loading = false;
    notifyListeners();

    // Schedule birthday notifications for upcoming contacts
    NotificationService().scheduleBirthdayReminders(_contacts);
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

    final existing = _useDb ? _contacts : _storage.getContacts();
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();
    int added = 0;
    for (final c in imported) {
      if (!existingNames.contains(c.name.toLowerCase())) {
        existing.add(c);
        if (_useDb) {
          await ApiService.insert('contacts', c.toRow());
        }
        added++;
      }
    }
    await _storage.saveContacts(existing);
    _importing = false;
    await _loadContacts();
    return 'Imported $added new contacts from Google';
  }

  /// True if the user is at or over the free-tier contacts limit.
  bool get atContactsLimit {
    final pro = ProService();
    if (pro.hasAccess) return false;
    return _contacts.length >= ProService.freeContactsLimit;
  }

  Future<bool> addContact({
    required String name,
    required String emoji,
    required DateTime birthday,
    String relationship = 'friend',
    String notes = '',
  }) async {
    if (name.trim().isEmpty) return false;
    if (atContactsLimit) return false;
    final contact = Contact(
      id: const Uuid().v4(),
      name: name.trim(),
      emoji: emoji,
      birthday: birthday,
      relationship: relationship,
      notes: notes.trim(),
    );

    if (_useDb) {
      await ApiService.insert('contacts', contact.toRow());
    }

    final contacts = _storage.getContacts()..add(contact);
    await _storage.saveContacts(contacts);
    await _loadContacts();
    return true;
  }

  Future<void> deleteContact(Contact contact) async {
    if (_useDb) {
      await ApiService.delete('contacts', contact.id);
    }
    _contacts.remove(contact);
    await _storage.saveContacts(_contacts);
    notifyListeners();
  }
}
