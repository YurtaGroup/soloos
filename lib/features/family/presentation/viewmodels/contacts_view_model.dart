import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/contact.dart';
import '../../domain/models/crm_extras.dart';
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
  Map<String, CrmExtras> _crmExtras = {};

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

    // Load local CRM extras (always local in Phase A)
    _crmExtras = _storage.getCrmExtras();

    _loading = false;
    notifyListeners();

    // Schedule birthday notifications for upcoming contacts
    NotificationService().scheduleBirthdayReminders(_contacts);
  }

  void reload() => _loadContacts();

  // ── CRM Extras ────────────────────────────────────────────────

  /// Returns existing extras for [c], or a default "none-stage" record.
  CrmExtras extrasFor(Contact c) =>
      _crmExtras[c.id] ??
      CrmExtras(contactId: c.id, dealStage: 'none');

  /// Upserts a CrmExtras record; persists and notifies.
  Future<void> upsertExtras(CrmExtras e) async {
    _crmExtras[e.contactId] = e;
    await _storage.upsertCrmExtra(e);
    notifyListeners();
  }

  /// Convenience: update only the deal stage for a contact.
  Future<void> updateStage(Contact c, String stage) async {
    final existing = extrasFor(c);
    await upsertExtras(existing.copyWith(dealStage: stage));
  }

  /// Convenience: update next step text and optional date.
  Future<void> updateNextStep(
    Contact c,
    String step,
    DateTime? date,
  ) async {
    final existing = extrasFor(c);
    await upsertExtras(
      existing.copyWith(nextStep: step, nextStepDate: date),
    );
  }

  /// Returns contacts whose CRM stage matches [stage].
  Iterable<Contact> contactsByStage(String stage) => _contacts.where(
        (c) => (_crmExtras[c.id]?.dealStage ?? 'none') == stage,
      );

  /// Sum of dealAmount for all contacts in active stages (not won/lost/none).
  double get pipelineValue => _contacts.fold(0.0, (sum, c) {
        final extras = _crmExtras[c.id];
        if (extras == null || !extras.isActive) return sum;
        return sum + (extras.dealAmount ?? 0.0);
      });

  /// Count of contacts in active pipeline stages.
  int get activeContactCount => _contacts
      .where((c) => (_crmExtras[c.id]?.isActive ?? false))
      .length;

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

  /// Contacts that haven't been reached in 30+ days (or never).
  List<Contact> get overdueContacts =>
      _contacts.where((c) => c.isContactOverdue).toList();

  /// Mark a contact as contacted today.
  Future<void> logContact(Contact contact) async {
    contact.lastContacted = DateTime.now();

    if (_useDb) {
      await ApiService.update('contacts', contact.id, {
        'last_contacted': contact.lastContacted!.toIso8601String(),
      });
    }

    final all = _storage.getContacts();
    final idx = all.indexWhere((c) => c.id == contact.id);
    if (idx != -1) all[idx].lastContacted = contact.lastContacted;
    await _storage.saveContacts(all);
    notifyListeners();
  }

  Future<void> deleteContact(Contact contact) async {
    _contacts.remove(contact);
    _crmExtras.remove(contact.id);
    await _storage.saveContacts(_contacts);
    await _storage.removeCrmExtra(contact.id);
    notifyListeners();
    if (_useDb) {
      try {
        await ApiService.delete('contacts', contact.id);
      } catch (e) {
        debugPrint('API delete contact failed: $e');
      }
    }
  }
}
