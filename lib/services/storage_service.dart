import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../features/family/domain/models/crm_extras.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  static const _secure = FlutterSecureStorage();
  String _cachedApiKey = '';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Load API key from secure storage into memory cache
    _cachedApiKey = await _secure.read(key: 'claude_api_key') ?? '';
    // Migrate from plain prefs if needed
    final plainKey = _prefs!.getString('api_key') ?? '';
    if (plainKey.isNotEmpty && _cachedApiKey.isEmpty) {
      _cachedApiKey = plainKey;
      await _secure.write(key: 'claude_api_key', value: plainKey);
      await _prefs!.remove('api_key');
    }
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw Exception('StorageService not initialized');
    return _prefs!;
  }

  // ─── User Settings ────────────────────────────────────────────
  String get userName => prefs.getString('user_name') ?? '';
  Future<void> setUserName(String v) => prefs.setString('user_name', v);

  String get apiKey => _cachedApiKey;
  Future<void> setApiKey(String v) async {
    _cachedApiKey = v;
    await _secure.write(key: 'claude_api_key', value: v);
  }

  bool get onboardingDone => prefs.getBool('onboarding_done') ?? false;
  Future<void> setOnboardingDone() => prefs.setBool('onboarding_done', true);

  bool get aiConsentGiven => prefs.getBool('ai_consent_given') ?? false;
  Future<void> setAiConsentGiven(bool v) => prefs.setBool('ai_consent_given', v);

  String get lastAiDigest => prefs.getString('last_ai_digest') ?? '';
  Future<void> setLastAiDigest(String v) => prefs.setString('last_ai_digest', v);

  String get lastDigestDate => prefs.getString('last_digest_date') ?? '';
  Future<void> setLastDigestDate(String v) => prefs.setString('last_digest_date', v);

  // ─── Projects ─────────────────────────────────────────────────
  List<Project> getProjects() {
    final raw = prefs.getString('projects');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Project.fromJson(e)).toList();
  }

  Future<void> saveProjects(List<Project> projects) =>
      prefs.setString('projects', jsonEncode(projects.map((p) => p.toJson()).toList()));

  // ─── Habits ───────────────────────────────────────────────────
  List<Habit> getHabits() {
    final raw = prefs.getString('habits');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Habit.fromJson(e)).toList();
  }

  Future<void> saveHabits(List<Habit> habits) =>
      prefs.setString('habits', jsonEncode(habits.map((h) => h.toJson()).toList()));

  // ─── Finance ──────────────────────────────────────────────────
  List<Transaction> getTransactions() {
    final raw = prefs.getString('transactions');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Transaction.fromJson(e)).toList();
  }

  Future<void> saveTransactions(List<Transaction> transactions) =>
      prefs.setString('transactions', jsonEncode(transactions.map((t) => t.toJson()).toList()));

  // ─── Ideas ────────────────────────────────────────────────────
  List<Idea> getIdeas() {
    final raw = prefs.getString('ideas');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Idea.fromJson(e)).toList();
  }

  Future<void> saveIdeas(List<Idea> ideas) =>
      prefs.setString('ideas', jsonEncode(ideas.map((i) => i.toJson()).toList()));

  // ─── Contacts ─────────────────────────────────────────────────
  List<Contact> getContacts() {
    final raw = prefs.getString('contacts');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Contact.fromJson(e)).toList();
  }

  Future<void> saveContacts(List<Contact> contacts) =>
      prefs.setString('contacts', jsonEncode(contacts.map((c) => c.toJson()).toList()));

  // ─── CRM Extras (local-only, Week 4 Phase A) ──────────────────
  static const _crmExtrasKey = 'crm_extras_v1';

  /// Returns all locally-stored CRM extras, keyed by contactId.
  Map<String, CrmExtras> getCrmExtras() {
    final raw = prefs.getString(_crmExtrasKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
      (k, v) => MapEntry(k, CrmExtras.fromJson(v as Map<String, dynamic>)),
    );
  }

  /// Persists the full CRM extras map.
  Future<void> saveCrmExtras(Map<String, CrmExtras> extras) =>
      prefs.setString(
        _crmExtrasKey,
        jsonEncode(extras.map((k, v) => MapEntry(k, v.toJson()))),
      );

  /// Read-modify-write: inserts or replaces a single CrmExtras entry.
  Future<void> upsertCrmExtra(CrmExtras extra) async {
    final all = getCrmExtras();
    all[extra.contactId] = extra;
    await saveCrmExtras(all);
  }

  /// Removes the CRM extras for a deleted contact.
  Future<void> removeCrmExtra(String contactId) async {
    final all = getCrmExtras();
    all.remove(contactId);
    await saveCrmExtras(all);
  }

  // ─── Standup Logs ─────────────────────────────────────────────
  List<StandupLog> getStandupLogs() {
    final raw = prefs.getString('standup_logs');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => StandupLog.fromJson(e)).toList();
  }

  Future<void> saveStandupLogs(List<StandupLog> logs) =>
      prefs.setString('standup_logs', jsonEncode(logs.map((l) => l.toJson()).toList()));
}
