import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/standup_log.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/claude_service.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';

class StandupViewModel extends ChangeNotifier {
  StandupViewModel({
    StorageService? storage,
    ClaudeService? claude,
  })  : _storage = storage ?? StorageService(),
        _claude = claude ?? ClaudeService() {
    _loadLogs();
  }

  final StorageService _storage;
  final ClaudeService _claude;

  List<StandupLog> _logs = [];
  bool _loading = false;
  String? _aiResponse;

  List<StandupLog> get logs => _logs;
  bool get loading => _loading;
  String? get aiResponse => _aiResponse;

  bool get _useDb => ApiService.isAuthenticated;

  Future<void> _loadLogs() async {
    _loading = true;
    notifyListeners();

    try {
      if (_useDb) {
        final rows = await ApiService.getAll('standup_logs', orderBy: 'created_at');
        _logs = rows.map((r) => StandupLog.fromRow(r)).toList();
      } else {
        _logs = _storage.getStandupLogs();
      }
    } catch (_) {
      _logs = _storage.getStandupLogs();
    }

    _loading = false;
    notifyListeners();
  }

  void reload() => _loadLogs();

  Future<void> submit({
    required String wins,
    required String challenges,
    required String priorities,
  }) async {
    _loading = true;
    _aiResponse = null;
    notifyListeners();

    final aiResp = await _claude.analyzeStandup(
      wins: wins.trim(),
      challenges: challenges.trim(),
      priorities: priorities.trim(),
    );

    final log = StandupLog(
      id: const Uuid().v4(),
      wins: wins.trim(),
      challenges: challenges.trim(),
      priorities: priorities.trim(),
      aiResponse: aiResp,
    );

    if (_useDb) {
      await ApiService.insert('standup_logs', log.toRow());
    }

    final logs = _storage.getStandupLogs()..insert(0, log);
    await _storage.saveStandupLogs(logs);
    GamificationEventBus.emit(GamificationEventType.standupCompleted);

    _loading = false;
    _aiResponse = aiResp;
    await _loadLogs();
  }

  void clearResponse() {
    _aiResponse = null;
    notifyListeners();
  }
}
