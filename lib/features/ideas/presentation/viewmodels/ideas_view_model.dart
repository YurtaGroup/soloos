import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/idea.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/api_service.dart';
import '../../../../services/claude_service.dart';
import '../../../../services/analytics_service.dart';

class IdeasViewModel extends ChangeNotifier {
  IdeasViewModel({
    StorageService? storage,
    ClaudeService? claude,
  })  : _storage = storage ?? StorageService(),
        _claude = claude ?? ClaudeService() {
    _loadIdeas();
  }

  final StorageService _storage;
  final ClaudeService _claude;

  List<Idea> _ideas = [];
  bool _loading = false;
  String? _validatingId;
  String? _scriptingId;

  List<Idea> get ideas => _ideas;
  bool get loading => _loading;

  List<Idea> get activeIdeas =>
      _ideas.where((i) => i.status == IdeaStatus.active).toList();

  List<Idea> get archivedIdeas =>
      _ideas.where((i) => i.status != IdeaStatus.active).toList();

  bool isValidating(String ideaId) => _validatingId == ideaId;
  bool isScripting(String ideaId) => _scriptingId == ideaId;

  bool get atActiveLimit => activeIdeas.length >= 3;

  bool get _useDb => ApiService.isAuthenticated;

  Future<void> _loadIdeas() async {
    _loading = true;
    notifyListeners();

    try {
      if (_useDb) {
        final rows = await ApiService.getAll('ideas', orderBy: 'created_at');
        _ideas = rows.map((r) => Idea.fromRow(r)).toList();
      } else {
        _ideas = _storage.getIdeas();
      }
    } catch (_) {
      _ideas = _storage.getIdeas();
    }

    _loading = false;
    notifyListeners();
  }

  void reload() => _loadIdeas();

  Future<bool> addIdea({required String title, required String description}) async {
    if (atActiveLimit) return false;
    if (title.trim().isEmpty) return false;

    final idea = Idea(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description.trim(),
    );

    if (_useDb) {
      await ApiService.insert('ideas', idea.toRow());
    }

    final all = _storage.getIdeas()..add(idea);
    await _storage.saveIdeas(all);
    GamificationEventBus.emit(GamificationEventType.ideaCreated,
        description: title.trim());
    AnalyticsService().ideaCreated();
    await _loadIdeas();
    return true;
  }

  Future<void> deleteIdea(String ideaId) async {
    final all = _storage.getIdeas()..removeWhere((i) => i.id == ideaId);
    await _storage.saveIdeas(all);
    await _loadIdeas();
    if (_useDb) {
      try { await ApiService.delete('ideas', ideaId); } catch (_) {}
    }
  }

  Future<void> updateStatus(String ideaId, IdeaStatus status) async {
    if (_useDb) {
      await ApiService.update('ideas', ideaId, {'status': status.name});
    }

    final all = _storage.getIdeas();
    final idx = all.indexWhere((i) => i.id == ideaId);
    if (idx != -1) all[idx].status = status;
    await _storage.saveIdeas(all);

    if (status == IdeaStatus.active) {
      GamificationEventBus.emit(GamificationEventType.ideaActedOn);
    }
    await _loadIdeas();
  }

  /// Returns a limit string like 'limit:3:3' if blocked, or null if OK.
  Future<String?> checkAiLimit() => _claude.checkAiLimit();

  Future<void> validateIdea(Idea idea) async {
    if (_validatingId != null) return;

    // Check free-tier AI limit before calling
    final limitCheck = await _claude.checkAiLimit();
    if (limitCheck != null) {
      _validatingId = null;
      notifyListeners();
      return;
    }

    _validatingId = idea.id;
    notifyListeners();

    final result = await _claude.validateIdea(idea.title, idea.description);

    idea.notes.insert(0, '🤖 AI Validation:\n$result');

    if (_useDb) {
      await ApiService.update('ideas', idea.id, {'notes': idea.notes});
    }

    final all = _storage.getIdeas();
    final idx = all.indexWhere((i) => i.id == idea.id);
    if (idx != -1) {
      all[idx].notes = idea.notes;
      await _storage.saveIdeas(all);
    }

    _validatingId = null;
    await _loadIdeas();
  }

  Future<void> generateScript(Idea idea, String platform) async {
    if (_scriptingId != null) return;

    // Check free-tier AI limit before calling
    final limitCheck = await _claude.checkAiLimit();
    if (limitCheck != null) {
      _scriptingId = null;
      notifyListeners();
      return;
    }

    _scriptingId = idea.id;
    notifyListeners();

    final script = await _claude.writeContentScript(
      topic: idea.title,
      platform: platform,
      angle: idea.description,
    );

    idea.aiScript = script;

    if (_useDb) {
      await ApiService.update('ideas', idea.id, {'ai_script': script});
    }

    final all = _storage.getIdeas();
    final idx = all.indexWhere((i) => i.id == idea.id);
    if (idx != -1) {
      all[idx].aiScript = script;
      await _storage.saveIdeas(all);
    }

    _scriptingId = null;
    await _loadIdeas();
  }
}
