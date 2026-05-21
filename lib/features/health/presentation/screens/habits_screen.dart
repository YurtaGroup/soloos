import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/app_card.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/mono_text.dart';
import '../../../../widgets/common_widgets.dart';
import '../../domain/models/habit.dart';
import '../viewmodels/habits_view_model.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  Future<void> _showAddDialog(BuildContext context, HabitsViewModel vm) async {
    final nameCtrl = TextEditingController();
    String emoji = '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: RadiusTokens.lg),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + SpaceTokens.s24,
            left: SpaceTokens.s16,
            right: SpaceTokens.s16,
            top: SpaceTokens.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Habit', style: TextStyles.displayMd(ctx)),
              const SizedBox(height: SpaceTokens.s16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      // Emoji picker — kept as user-generated data
                      final emojiChars = ['✅', '💪', '📚', '🏃', '🧘', '💧', '🥗', '😴', '✍️', '🎯', '💊', '🚫'];
                      final selected = await showDialog<String>(
                        context: ctx,
                        builder: (d) => AlertDialog(
                          title: const Text('Choose Emoji'),
                          content: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: emojiChars.map((e) => GestureDetector(
                              onTap: () => Navigator.pop(d, e),
                              child: Text(e, style: const TextStyle(fontSize: 28)),
                            )).toList(),
                          ),
                        ),
                      );
                      if (selected != null) setModal(() => emoji = selected);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(SpaceTokens.s12),
                      decoration: BoxDecoration(
                        color: QColors.of(ctx).surfaceMuted,
                        borderRadius: RadiusTokens.smAll,
                        border: Border.all(color: QColors.of(ctx).border),
                      ),
                      child: emoji.isEmpty
                          ? Icon(Icons.emoji_emotions_outlined,
                              size: 24, color: QColors.of(ctx).textSecondary)
                          : Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: SpaceTokens.s12),
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      style: TextStyles.bodyMd(ctx),
                      decoration: const InputDecoration(hintText: 'Habit name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpaceTokens.s16),
              AppButton(
                label: 'Add Habit',
                isFullWidth: true,
                onPressed: () async {
                  final added = await vm.addHabit(
                    name: nameCtrl.text,
                    emoji: emoji,
                  );
                  if (added && ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<HabitsViewModel>();
    final habits = vm.habits;
    final completedToday = vm.completedToday;
    final maxStreak = vm.maxStreak;

    return Scaffold(
      appBar: AppBar(
        title: Text('Health and Habits', style: TextStyles.displayMd(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: c.textSecondary),
            onPressed: () => _showAddDialog(context, vm),
          ),
        ],
      ),
      body: habits.isEmpty
          ? EmptyState(
              emoji: '',
              title: 'No habits yet',
              subtitle: 'Build powerful daily routines.',
              onAction: () => _showAddDialog(context, vm),
              actionLabel: 'Add Habit',
            )
          : ListView(
              padding: const EdgeInsets.all(SpaceTokens.s16),
              children: [
                // Stats header
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        dense: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionLabel('Today', bottomPadding: SpaceTokens.s4),
                            MonoText(
                              '$completedToday/${habits.length}',
                              size: 20,
                              weight: FontWeight.w700,
                              color: completedToday == habits.length && habits.isNotEmpty
                                  ? c.success
                                  : c.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: SpaceTokens.s8),
                    Expanded(
                      child: AppCard(
                        dense: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionLabel('Best Streak', bottomPadding: SpaceTokens.s4),
                            MonoText(
                              '${maxStreak}d',
                              size: 20,
                              weight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpaceTokens.s16),
                ...habits.map((habit) => _HabitCard(
                      habit: habit,
                      onToggle: () => vm.toggleHabit(habit),
                      onDelete: () => vm.deleteHabit(habit),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habits_fab',
        onPressed: () => _showAddDialog(context, vm),
        backgroundColor: c.primaryButton,
        foregroundColor: c.primaryButtonLabel,
        elevation: 0,
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
    final c = QColors.of(context);
    final done = habit.isCompletedToday();
    final streak = habit.currentStreak;

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: SpaceTokens.s16),
        margin: const EdgeInsets.only(bottom: SpaceTokens.s8),
        decoration: BoxDecoration(
          color: c.danger.withValues(alpha: 0.12),
          borderRadius: RadiusTokens.smAll,
        ),
        child: Icon(Icons.delete_outline, color: c.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onToggle();
        },
        child: AnimatedContainer(
          duration: MotionTokens.duration,
          curve: MotionTokens.curve,
          margin: const EdgeInsets.only(bottom: SpaceTokens.s8),
          padding: const EdgeInsets.all(SpaceTokens.s16),
          decoration: BoxDecoration(
            color: done ? c.success.withValues(alpha: 0.08) : c.surface,
            borderRadius: RadiusTokens.smAll,
            border: Border.all(
              color: done ? c.success.withValues(alpha: 0.4) : c.border,
            ),
          ),
          child: Row(
            children: [
              // Emoji is user-generated data — keep it
              Text(habit.emoji.isEmpty ? '' : habit.emoji,
                  style: const TextStyle(fontSize: 24)),
              if (habit.emoji.isNotEmpty) const SizedBox(width: SpaceTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyles.bodyMd(context).copyWith(
                        color: done ? c.success : c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (streak > 0)
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 12, color: c.warn),
                          const SizedBox(width: 3),
                          Text(
                            '$streak day streak',
                            style: TextStyles.bodySm(context)
                                .copyWith(color: c.warn),
                          ),
                        ],
                      )
                    else
                      Text('Start today.',
                          style: TextStyles.bodySm(context)
                              .copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              _MiniCalendar(habit: habit),
              const SizedBox(width: SpaceTokens.s8),
              AnimatedContainer(
                duration: MotionTokens.duration,
                curve: MotionTokens.curve,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: done ? c.success : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? c.success : c.border,
                    width: done ? 0 : 1.5,
                  ),
                ),
                child: done
                    ? Icon(Icons.check_rounded,
                        color: c.surface, size: 14)
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
    final c = QColors.of(context);
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Row(
      children: days.map((day) {
        final filled = habit.completedDates.any(
          (d) =>
              d.year == day.year &&
              d.month == day.month &&
              d.day == day.day,
        );
        final isToday = day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: filled
                ? c.success
                : isToday
                    ? c.success.withValues(alpha: 0.3)
                    : c.border,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
