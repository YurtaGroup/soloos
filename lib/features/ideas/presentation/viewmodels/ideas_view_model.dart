import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/app_models.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/claude_service.dart';

/// ViewModel for the Ideas feature.
///
/// Owns all business logic that was previously scattered across
/// [_IdeasScreenState] and [_IdeaCardState] in ideas_screen.dart:
///
/// - idea list management (load, add, delete)
/// - status transitions (archive, activate)
/// - AI validation via ClaudeService
/// - AI script generation via ClaudeService
/// - per-idea loading state (validating / scripting)
///
/// The screen and cards become pure observers — they call methods
/// on this ViewModel and render its state.
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

  /// Which idea ID is currently being AI-validated (null = none).
  String? _validatingId;

  /// Which idea ID is currently having a script generated (null = none).
  String? _scriptingId;

  // ── Getters ────────────────────────────────────────────────────

  List<Idea> get activeIdeas =>
      _ideas.where((i) => i.status == IdeaStatus.active).toList();

  List<Idea> get archivedIdeas =>
      _ideas.where((i) => i.status != IdeaStatus.active).toList();

  bool isValidating(String ideaId) => _validatingId == ideaId;
  bool isScripting(String ideaId) => _scriptingId == ideaId;

  bool get atActiveLimit => activeIdeas.length >= 3;

  // ── Load ───────────────────────────────────────────────────────

  void _loadIdeas() {
    _ideas = _storage.getIdeas();
    notifyListeners();
  }

  void reload() => _loadIdeas();

  // ── Add ────────────────────────────────────────────────────────

  /// Returns false if at the 3-idea limit (caller shows snackbar).
  Future<bool> addIdea({required String title, required String description}) async {
    if (atActiveLimit) return false;
    if (title.trim().isEmpty) return false;

    final all = _storage.getIdeas()
      ..add(Idea(
        id: const Uuid().v4(),
        title: title.trim(),
        description: description.trim(),
      ));
    await _storage.saveIdeas(all);
    GamificationEventBus.emit(GamificationEventType.ideaCreated,
        description: title.trim());
    _loadIdeas();
    return true;
  }

  // ── Delete ─────────────────────────────────────────────────────

  Future<void> deleteIdea(String ideaId) async {
    final all = _storage.getIdeas()..removeWhere((i) => i.id == ideaId);
    await _storage.saveIdeas(all);
    _loadIdeas();
  }

  // ── Status ─────────────────────────────────────────────────────

  Future<void> updateStatus(String ideaId, IdeaStatus status) async {
    final all = _storage.getIdeas();
    final idx = all.indexWhere((i) => i.id == ideaId);
    if (idx != -1) all[idx].status = status;
    await _storage.saveIdeas(all);
    if (status == IdeaStatus.active) {
      GamificationEventBus.emit(GamificationEventType.ideaActedOn);
    }
    _loadIdeas();
  }

  // ── AI: Validate ───────────────────────────────────────────────

  Future<void> validateIdea(Idea idea) async {
    if (_validatingId != null) return; // already working on one
    _validatingId = idea.id;
    notifyListeners();

    final result = await _claude.validateIdea(idea.title, idea.description);

    final all = _storage.getIdeas();
    final idx = all.indexWhere((i) => i.id == idea.id);
    if (idx != -1) {
      all[idx].notes.insert(0, '🤖 AI Validation:\n$result');
      await _storage.saveIdeas(all);
    }

    _validatingId = null;
    _loadIdeas();
  }

  // ── AI: Generate Script ────────────────────────────────────────

  Future<void> generateScript(Idea idea, String platform) async {
    if (_scriptingId != null) return;
    _scriptingId = idea.id;
    notifyListeners();

    final script = await _claude.writeContentScript(
      topic: idea.title,
      platform: platform,
      angle: idea.description,
    );

    final all = _storage.getIdeas();
    final idx = all.indexWhere((i) => i.id == idea.id);
    if (idx != -1) {
      all[idx].aiScript = script;
      await _storage.saveIdeas(all);
    }

    _scriptingId = null;
    _loadIdeas();
  }
}
