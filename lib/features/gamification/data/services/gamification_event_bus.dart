import '../../../gamification/domain/models/gamification_event.dart';

/// Lightweight singleton event bus.
/// Any module can call [GamificationEventBus.emit] to log an activity.
/// GamificationViewModel registers itself on init to receive events.
class GamificationEventBus {
  GamificationEventBus._();

  static void Function(GamificationEventType type, {String? description})?
      _handler;

  /// Called by GamificationViewModel during init.
  static void register(
      void Function(GamificationEventType type, {String? description})
          handler) {
    _handler = handler;
  }

  /// Called by any feature module (ViewModel, screen, etc.).
  static void emit(GamificationEventType type, {String? description}) {
    _handler?.call(type, description: description);
  }

  /// Remove the handler (e.g., on dispose).
  static void unregister() => _handler = null;
}
