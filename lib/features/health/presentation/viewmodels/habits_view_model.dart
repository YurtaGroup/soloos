import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/habit.dart';
import '../../../../services/storage_service.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';

class HabitsViewModel extends ChangeNotifier {
  HabitsViewModel({StorageService? storage})
      : _storage = storage ?? StorageService() {
    _loadHabits();
  }

  final StorageService _storage;
  List<Habit> _habits = [];

  List<Habit> get habits => _habits;
  int get completedToday => _habits.where((h) => h.isCompletedToday()).length;
  int get maxStreak => _habits.isEmpty
      ? 0
      : _habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);

  void _loadHabits() {
    _habits = _storage.getHabits();
    notifyListeners();
  }

  void reload() => _loadHabits();

  Future<void> toggleHabit(Habit habit) async {
    final today = DateTime.now();
    final alreadyDone = habit.isCompletedToday();
    if (alreadyDone) {
      habit.completedDates.removeWhere(
        (d) => d.year == today.year && d.month == today.month && d.day == today.day,
      );
    } else {
      habit.completedDates.add(today);
      GamificationEventBus.emit(
        GamificationEventType.habitCompleted,
        description: habit.name,
      );
      if (_habits.every((h) => h.isCompletedToday())) {
        GamificationEventBus.emit(GamificationEventType.allHabitsCompleted);
      }
    }
    await _storage.saveHabits(_habits);
    _loadHabits();
  }

  Future<bool> addHabit({required String name, required String emoji}) async {
    if (name.trim().isEmpty) return false;
    final habits = _storage.getHabits()
      ..add(Habit(
        id: const Uuid().v4(),
        name: name.trim(),
        emoji: emoji,
      ));
    await _storage.saveHabits(habits);
    _loadHabits();
    return true;
  }

  Future<void> deleteHabit(Habit habit) async {
    _habits.remove(habit);
    await _storage.saveHabits(_habits);
    _loadHabits();
  }
}
