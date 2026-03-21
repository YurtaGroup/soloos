import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../models/app_models.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _storage = StorageService();
  late List<Habit> _habits;

  @override
  void initState() {
    super.initState();
    _habits = _storage.getHabits();
  }

  void _reload() => setState(() => _habits = _storage.getHabits());

  Future<void> _toggleHabit(Habit habit) async {
    final today = DateTime.now();
    final alreadyDone = habit.isCompletedToday();
    if (alreadyDone) {
      habit.completedDates.removeWhere(
        (d) => d.year == today.year && d.month == today.month && d.day == today.day,
      );
    } else {
      habit.completedDates.add(today);
    }
    await _storage.saveHabits(_habits);
    _reload();
  }

  Future<void> _addHabit() async {
    final nameCtrl = TextEditingController();
    String emoji = '✅';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Habit',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final emojis = ['✅', '💪', '📚', '🏃', '🧘', '💧', '🥗', '😴', '✍️', '🎯', '💊', '🚫'];
                      final selected = await showDialog<String>(
                        context: ctx,
                        builder: (d) => AlertDialog(
                          backgroundColor: AppColors.card,
                          title: const Text('Choose Emoji', style: TextStyle(color: AppColors.textPrimary)),
                          content: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: emojis.map((e) => GestureDetector(
                              onTap: () => Navigator.pop(d, e),
                              child: Text(e, style: const TextStyle(fontSize: 28)),
                            )).toList(),
                          ),
                        ),
                      );
                      if (selected != null) setModal(() => emoji = selected);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(hintText: 'Habit name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final habits = _storage.getHabits()
                      ..add(Habit(
                        id: const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        emoji: emoji,
                      ));
                    await _storage.saveHabits(habits);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _reload();
                  },
                  child: const Text('Add Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedToday = _habits.where((h) => h.isCompletedToday()).length;
    final maxStreak = _habits.isEmpty ? 0 : _habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health & Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.healthColor),
            onPressed: _addHabit,
          ),
        ],
      ),
      body: _habits.isEmpty
          ? EmptyState(
              emoji: '💪',
              title: 'No habits yet',
              subtitle: 'Build powerful daily routines.\nConsistency is your superpower.',
              onAction: _addHabit,
              actionLabel: '+ Add Habit',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats header
                Row(
                  children: [
                    Expanded(
                      child: StatChip(
                        value: '$completedToday/${_habits.length}',
                        label: 'Today',
                        color: AppColors.healthColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatChip(
                        value: '${maxStreak}d',
                        label: 'Best Streak',
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatChip(
                        value: completedToday == _habits.length && _habits.isNotEmpty ? '🔥' : '📊',
                        label: completedToday == _habits.length ? 'Perfect!' : 'Keep going',
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Habit cards
                ..._habits.map((habit) => _HabitCard(
                      habit: habit,
                      onToggle: () => _toggleHabit(habit),
                      onDelete: () async {
                        _habits.remove(habit);
                        await _storage.saveHabits(_habits);
                        _reload();
                      },
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        backgroundColor: AppColors.healthColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday();
    final streak = habit.currentStreak;

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: done ? AppColors.healthColor.withOpacity(0.1) : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done ? AppColors.healthColor.withOpacity(0.4) : AppColors.textMuted.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        color: done ? AppColors.healthColor : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (streak > 0) ...[
                          const Icon(Icons.local_fire_department_rounded,
                              size: 12, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            '$streak day streak',
                            style: const TextStyle(color: AppColors.accent, fontSize: 11),
                          ),
                        ] else
                          const Text(
                            'Start today!',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Mini calendar (last 7 days)
              _MiniCalendar(habit: habit),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.healthColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? AppColors.healthColor : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  final Habit habit;
  const _MiniCalendar({required this.habit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Row(
      children: days.map((day) {
        final filled = habit.completedDates.any(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day,
        );
        final isToday = day.day == now.day && day.month == now.month && day.year == now.year;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: filled
                ? AppColors.healthColor
                : isToday
                    ? AppColors.healthColor.withOpacity(0.3)
                    : AppColors.textMuted.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
