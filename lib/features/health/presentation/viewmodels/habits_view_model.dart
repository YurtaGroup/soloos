import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/habit.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/api_service.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';

class HabitsViewModel extends ChangeNotifier {
  HabitsViewModel({StorageService? storage})
      : _storage = storage ?? StorageService() {
    _loadHabits();
  }

  final StorageService _storage;
  List<Habit> _habits = [];
  bool _loading = false;

  List<Habit> get habits => _habits;
  bool get loading => _loading;
  int get completedToday => _habits.where((h) => h.isCompletedToday()).length;
  int get maxStreak => _habits.isEmpty
      ? 0
      : _habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);

  bool get _useDb => ApiService.isAuthenticated;

  Future<void> _loadHabits() async {
    _loading = true;
    notifyListeners();

    try {
      if (_useDb) {
        final rows = await ApiService.getAll('habits', orderBy: 'created_at', ascending: true);
        final completionRows = await ApiService.getAll('habit_completions', orderBy: 'completed_date');

        // Group completions by habit_id
        final completionsByHabit = <String, List<DateTime>>{};
        for (final r in completionRows) {
          final hid = r['habit_id'] as String;
          completionsByHabit.putIfAbsent(hid, () => []).add(DateTime.parse(r['completed_date']));
        }

        _habits = rows
            .map((r) => Habit.fromRow(r, completedDates: completionsByHabit[r['id']] ?? []))
            .toList();
      } else {
        _habits = _storage.getHabits();
      }
    } catch (_) {
      _habits = _storage.getHabits();
    }

    _loading = false;
    notifyListeners();
  }

  void reload() => _loadHabits();

  Future<void> toggleHabit(Habit habit) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final alreadyDone = habit.isCompletedToday();

    if (alreadyDone) {
      habit.completedDates.removeWhere(
        (d) => d.year == today.year && d.month == today.month && d.day == today.day,
      );
      if (_useDb) {
        await ApiService.deleteHabitCompletion(habit.id, todayStr);
      }
    } else {
      habit.completedDates.add(today);
      if (_useDb) {
        await ApiService.insertHabitCompletion(habit.id, todayStr);
      }
      GamificationEventBus.emit(
        GamificationEventType.habitCompleted,
        description: habit.name,
      );
      if (_habits.every((h) => h.isCompletedToday())) {
        GamificationEventBus.emit(GamificationEventType.allHabitsCompleted);
      }
    }

    await _storage.saveHabits(_habits);
    notifyListeners();
  }

  Future<bool> addHabit({required String name, required String emoji}) async {
    if (name.trim().isEmpty) return false;
    final habit = Habit(
      id: const Uuid().v4(),
      name: name.trim(),
      emoji: emoji,
    );

    if (_useDb) {
      await ApiService.insert('habits', habit.toRow());
    }

    final habits = _storage.getHabits()..add(habit);
    await _storage.saveHabits(habits);
    await _loadHabits();
    return true;
  }

  Future<void> deleteHabit(Habit habit) async {
    if (_useDb) {
      await ApiService.delete('habits', habit.id);
    }
    _habits.remove(habit);
    await _storage.saveHabits(_habits);
    notifyListeners();
  }
}
