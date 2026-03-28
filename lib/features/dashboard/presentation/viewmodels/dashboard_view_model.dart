import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/claude_service.dart';
import '../../../../core/utils/stats_calculator.dart';

/// ViewModel for the Dashboard / Home tab.
///
/// Owns:
/// - AI digest loading + caching logic
/// - Today's stats computation (via StatsCalculator)
/// - Loading state
///
/// The screen becomes a thin observer that calls [refresh] and
/// renders [digest], [digestLoading], and [stats].
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    StorageService? storage,
    ClaudeService? claude,
  })  : _storage = storage ?? StorageService(),
        _claude = claude ?? ClaudeService() {
    _loadDigest();
  }

  final StorageService _storage;
  final ClaudeService _claude;

  String _digest = '';
  bool _digestLoading = false;

  // ── Getters ────────────────────────────────────────────────────

  String get digest => _digest;
  bool get digestLoading => _digestLoading;
  bool get hasApiKey => _storage.apiKey.isNotEmpty;
  String get userName => _storage.userName;

  // ── Load / Refresh ─────────────────────────────────────────────

  Future<void> _loadDigest() async {
    final lastDate = _storage.lastDigestDate;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (lastDate == today && _storage.lastAiDigest.isNotEmpty) {
      _digest = _storage.lastAiDigest;
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_storage.apiKey.isEmpty) return;

    // Check free-tier AI limit
    final limitCheck = await _claude.checkAiLimit();
    if (limitCheck != null) {
      _digest = '';
      _digestLoading = false;
      notifyListeners();
      return;
    }

    _digestLoading = true;
    notifyListeners();

    final stats = StatsCalculator.calculate(
      projects: _storage.getProjects(),
      habits: _storage.getHabits(),
      transactions: _storage.getTransactions(),
      ideas: _storage.getIdeas(),
      contacts: _storage.getContacts(),
    );

    final result = await _claude.generateDailyDigest(
      userName: _storage.userName,
      openTasks: stats.openTasks,
      completedTasks: stats.doneTasks,
      habitStreak: stats.habitStreak,
      habitsToday: stats.habitsToday,
      totalHabits: stats.totalHabits,
      balance: stats.balance,
      activeIdeas: stats.activeIdeas.map((i) => i.title).toList(),
      upcomingBirthdays: stats.upcomingBirthdayLabels,
    );

    await _storage.setLastAiDigest(result);
    await _storage.setLastDigestDate(
        DateFormat('yyyy-MM-dd').format(DateTime.now()));

    _digest = result;
    _digestLoading = false;
    notifyListeners();
  }
}
