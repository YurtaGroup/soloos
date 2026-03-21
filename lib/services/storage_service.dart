import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw Exception('StorageService not initialized');
    return _prefs!;
  }

  // ─── User Settings ────────────────────────────────────────────
  String get userName => prefs.getString('user_name') ?? '';
  Future<void> setUserName(String v) => prefs.setString('user_name', v);

  String get apiKey => prefs.getString('api_key') ?? '';
  Future<void> setApiKey(String v) => prefs.setString('api_key', v);

  bool get onboardingDone => prefs.getBool('onboarding_done') ?? false;
  Future<void> setOnboardingDone() => prefs.setBool('onboarding_done', true);

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

  // ─── Standup Logs ─────────────────────────────────────────────
  List<StandupLog> getStandupLogs() {
    final raw = prefs.getString('standup_logs');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => StandupLog.fromJson(e)).toList();
  }

  Future<void> saveStandupLogs(List<StandupLog> logs) =>
      prefs.setString('standup_logs', jsonEncode(logs.map((l) => l.toJson()).toList()));
}
