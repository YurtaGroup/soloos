import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/family_person.dart';
import '../../domain/models/family_reminder.dart';
import '../viewmodels/family_viewmodel.dart';
import '../widgets/family_person_card.dart';
import '../widgets/ai_suggestion_card.dart';
import 'family_person_detail_screen.dart';
import 'add_edit_family_person_screen.dart';

class FamilyDashboardScreen extends StatelessWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FamilyViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddPerson(context),
        child: const Icon(Icons.person_add_outlined),
      ),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, vm),
          if (vm.peopleNeedingAttention.isNotEmpty)
            _sectionSliver(
              title: '🔴 Needs Attention',
              trailing: '${vm.peopleNeedingAttention.length}',
              child: _AttentionList(vm: vm),
            ),
          if (vm.suggestions.isNotEmpty)
            _sectionSliver(
              title: '💡 Today\'s Suggestions',
              child: _SuggestionsList(vm: vm),
            ),
          if (vm.upcomingReminders.isNotEmpty || vm.overdueReminders.isNotEmpty)
            _sectionSliver(
              title: '⏰ Reminders',
              child: _RemindersList(vm: vm),
            ),
          _sectionSliver(
            title: '👥 Everyone',
            trailing: '${vm.totalPeople}',
            child: _AllPeopleList(vm: vm),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionSliver({
    required String title,
    String? trailing,
    required Widget child,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    )),
                if (trailing != null)
                  Text(trailing,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(BuildContext context, FamilyViewModel vm) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1530), Color(0xFF0F0A20)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFEC4899).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('❤️ Family',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              '${vm.totalPeople} people',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _HeaderChip(
                  label: 'Need attention',
                  value: '${vm.overdueContactCount}',
                  color: vm.overdueContactCount > 0
                      ? AppColors.accentRed
                      : AppColors.accentGreen,
                ),
                const SizedBox(width: 8),
                _HeaderChip(
                  label: 'Due today',
                  value: '${vm.dueTodayCount}',
                  color: vm.dueTodayCount > 0
                      ? AppColors.accent
                      : AppColors.accentGreen,
                ),
                const SizedBox(width: 8),
                _HeaderChip(
                  label: 'Birthdays soon',
                  value: '${vm.upcomingBirthdays.length}',
                  color: AppColors.primaryLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAddPerson(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditFamilyPersonScreen()),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HeaderChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 18)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AttentionList extends StatelessWidget {
  final FamilyViewModel vm;
  const _AttentionList({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: vm.peopleNeedingAttention
          .take(5)
          .map((p) => FamilyPersonCard(
                person: p,
                onTap: () => _openDetail(context, p),
                onContactedToday: () =>
                    context.read<FamilyViewModel>().markContactedToday(p.id),
                showAttentionBadge: true,
              ))
          .toList(),
    );
  }

  void _openDetail(BuildContext context, FamilyPerson p) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => FamilyPersonDetailScreen(personId: p.id)),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final FamilyViewModel vm;
  const _SuggestionsList({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: vm.suggestions
          .map((s) => AiSuggestionCard(
                suggestion: s,
                onActedOn: () {
                  context.read<FamilyViewModel>().markSuggestionActedOn(s.id);
                  context.read<FamilyViewModel>().markContactedToday(s.personId);
                },
                onDismiss: () =>
                    context.read<FamilyViewModel>().dismissSuggestion(s.id),
              ))
          .toList(),
    );
  }
}

class _RemindersList extends StatelessWidget {
  final FamilyViewModel vm;
  const _RemindersList({required this.vm});

  @override
  Widget build(BuildContext context) {
    final overdue = vm.overdueReminders;
    final upcoming = vm.upcomingReminders.where((r) => !r.isOverdue).take(5).toList();

    return Column(
      children: [
        ...overdue.map((r) => _ReminderTile(
              reminder: r,
              isOverdue: true,
              onComplete: () =>
                  context.read<FamilyViewModel>().completeReminder(r.id),
            )),
        ...upcoming.map((r) => _ReminderTile(
              reminder: r,
              isOverdue: false,
              onComplete: () =>
                  context.read<FamilyViewModel>().completeReminder(r.id),
            )),
      ],
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final FamilyReminder reminder;
  final bool isOverdue;
  final VoidCallback onComplete;
  const _ReminderTile(
      {required this.reminder,
      required this.isOverdue,
      required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? AppColors.accentRed : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: AppColors.accentRed.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Text(reminder.reminderType.emoji,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                Text(
                  isOverdue ? 'Overdue' : _dueLabel(reminder.dueAt),
                  style: TextStyle(color: color, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accentGreen.withOpacity(0.4)),
              ),
              child: const Icon(Icons.check,
                  size: 16, color: AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  String _dueLabel(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }
}

class _AllPeopleList extends StatelessWidget {
  final FamilyViewModel vm;
  const _AllPeopleList({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.people.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Text('❤️', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            const Text('Add people who matter',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Track relationships, birthdays, and\nstay present with the people you love.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: vm.people
          .map((p) => FamilyPersonCard(
                person: p,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          FamilyPersonDetailScreen(personId: p.id)),
                ),
                onContactedToday: () =>
                    context.read<FamilyViewModel>().markContactedToday(p.id),
              ))
          .toList(),
    );
  }
}
