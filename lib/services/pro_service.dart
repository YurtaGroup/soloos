import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Single source of truth for Pro status and engagement streak.
///
/// Pro state is persisted locally (production would verify receipt /
/// JWT from your backend). Streak tracks consecutive days the user
/// opens the app — the #1 retention mechanic.
class ProService extends ChangeNotifier {
  static final ProService _instance = ProService._internal();
  factory ProService() => _instance;
  ProService._internal();

  SharedPreferences? _prefs;

  bool _isPro = false;
  int _streakDays = 0;
  int _totalDaysActive = 0;
  DateTime? _trialEndsAt;

  // ── Getters ────────────────────────────────────────────────────

  bool get isPro => _isPro;
  int get streakDays => _streakDays;
  int get totalDaysActive => _totalDaysActive;
  DateTime? get trialEndsAt => _trialEndsAt;

  bool get isTrialActive =>
      _trialEndsAt != null && _trialEndsAt!.isAfter(DateTime.now());

  bool get hasAccess => _isPro || isTrialActive;

  /// Days remaining in trial, or 0 if no active trial.
  int get trialDaysLeft {
    if (_trialEndsAt == null) return 0;
    final diff = _trialEndsAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  String get streakEmoji {
    if (_streakDays >= 30) return '🏆';
    if (_streakDays >= 14) return '🔥';
    if (_streakDays >= 7) return '⚡';
    if (_streakDays >= 3) return '✨';
    return '🌱';
  }

  // ── Init ───────────────────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isPro = _prefs!.getBool('is_pro') ?? false;
    _streakDays = _prefs!.getInt('streak_days') ?? 0;
    _totalDaysActive = _prefs!.getInt('total_days_active') ?? 0;

    final trialStr = _prefs!.getString('trial_ends_at');
    if (trialStr != null) {
      _trialEndsAt = DateTime.tryParse(trialStr);
    }

    await _updateStreak();
    notifyListeners();
  }

  // ── Streak tracking ────────────────────────────────────────────

  Future<void> _updateStreak() async {
    if (_prefs == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastActive = _prefs!.getString('last_active_date') ?? '';

    if (lastActive == today) return; // Already counted today

    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    if (lastActive == yesterday) {
      // Consecutive day — extend streak
      _streakDays += 1;
    } else if (lastActive.isEmpty) {
      // First ever session
      _streakDays = 1;
    } else {
      // Streak broken
      _streakDays = 1;
    }

    _totalDaysActive += 1;
    await _prefs!.setString('last_active_date', today);
    await _prefs!.setInt('streak_days', _streakDays);
    await _prefs!.setInt('total_days_active', _totalDaysActive);
    notifyListeners();
  }

  // ── Pro / Trial management ─────────────────────────────────────

  /// Starts a 7-day free trial. Returns false if trial already used.
  Future<bool> startTrial() async {
    if (_prefs == null) return false;
    final alreadyUsed = _prefs!.getBool('trial_used') ?? false;
    if (alreadyUsed || _isPro) return false;

    _trialEndsAt = DateTime.now().add(const Duration(days: 7));
    await _prefs!.setString('trial_ends_at', _trialEndsAt!.toIso8601String());
    await _prefs!.setBool('trial_used', true);
    notifyListeners();
    return true;
  }

  /// Call this after successful payment (Stripe webhook → your backend → app).
  Future<void> activatePro() async {
    _isPro = true;
    _trialEndsAt = null;
    await _prefs?.setBool('is_pro', true);
    notifyListeners();
  }

  /// Dev/demo helper — toggle Pro for testing.
  Future<void> toggleProForDemo() async {
    _isPro = !_isPro;
    await _prefs?.setBool('is_pro', _isPro);
    notifyListeners();
  }

  // ── Plan limits (Free tier) ────────────────────────────────────

  static const int freeAiCallsPerDay = 3;
  static const int freeActiveIdeas = 3;
  static const int freeStandupHistory = 7; // days
  static const int freeContactsLimit = 20;

  Future<int> aiCallsUsedToday() async {
    if (_prefs == null) return 0;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'ai_calls_$today';
    return _prefs!.getInt(key) ?? 0;
  }

  Future<void> recordAiCall() async {
    if (_prefs == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'ai_calls_$today';
    final current = _prefs!.getInt(key) ?? 0;
    await _prefs!.setInt(key, current + 1);
  }

  Future<bool> canMakeAiCall() async {
    if (hasAccess) return true;
    final used = await aiCallsUsedToday();
    return used < freeAiCallsPerDay;
  }
}
