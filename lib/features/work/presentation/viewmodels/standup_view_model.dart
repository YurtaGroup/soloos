import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/standup_log.dart';
import '../../../../services/storage_service.dart';
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

  void _loadLogs() {
    _logs = _storage.getStandupLogs();
    notifyListeners();
  }

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

    final logs = _storage.getStandupLogs()..insert(0, log);
    await _storage.saveStandupLogs(logs);
    GamificationEventBus.emit(GamificationEventType.standupCompleted);

    _loading = false;
    _aiResponse = aiResp;
    _loadLogs();
  }

  void clearResponse() {
    _aiResponse = null;
    notifyListeners();
  }
}
