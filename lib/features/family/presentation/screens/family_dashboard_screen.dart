import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/app_card.dart';
import '../../../../theme/atoms/mono_text.dart';
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
    final c = QColors.of(context);
    final vm = context.watch<FamilyViewModel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'family_fab',
        onPressed: () => _openAddPerson(context),
        backgroundColor: c.primaryButton,
        foregroundColor: c.primaryButtonLabel,
        elevation: 0,
        child: const Icon(Icons.person_add_outlined),
      ),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, vm, c),
          if (vm.peopleNeedingAttention.isNotEmpty)
            _sectionSliver(
              context: context,
              title: 'Needs Attention',
              trailing: '${vm.peopleNeedingAttention.length}',
              child: _AttentionList(vm: vm),
            ),
          if (vm.suggestions.isNotEmpty)
            _sectionSliver(
              context: context,
              title: "Today's Suggestions",
              child: _SuggestionsList(vm: vm),
            ),
          if (vm.upcomingReminders.isNotEmpty || vm.overdueReminders.isNotEmpty)
            _sectionSliver(
              context: context,
              title: 'Reminders',
              child: _RemindersList(vm: vm),
            ),
          _sectionSliver(
            context: context,
            title: 'Everyone',
            trailing: '${vm.totalPeople}',
            child: _AllPeopleList(vm: vm),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionSliver({
    required BuildContext context,
    required String title,
    String? trailing,
    required Widget child,
  }) {
    final c = QColors.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SpaceTokens.s16, SpaceTokens.s24, SpaceTokens.s16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionLabel(title, bottomPadding: 0),
                if (trailing != null)
                  MonoText(trailing, size: 11, color: c.textSecondary),
              ],
            ),
            const SizedBox(height: SpaceTokens.s8),
            child,
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(
      BuildContext context, FamilyViewModel vm, QColorSet c) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            SpaceTokens.s16, SpaceTokens.s16, SpaceTokens.s16, 0),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Family', bottomPadding: SpaceTokens.s8),
              Text(
                '${vm.totalPeople} people',
                style: TextStyles.displayMd(context),
              ),
              const SizedBox(height: SpaceTokens.s16),
              Row(
                children: [
                  _HeaderChip(
                    label: 'Need attention',
                    value: '${vm.overdueContactCount}',
                    color: vm.overdueContactCount > 0 ? c.danger : c.success,
                  ),
                  const SizedBox(width: SpaceTokens.s8),
                  _HeaderChip(
                    label: 'Due today',
                    value: '${vm.dueTodayCount}',
                    color: vm.dueTodayCount > 0 ? c.warn : c.success,
                  ),
                  const SizedBox(width: SpaceTokens.s8),
                  _HeaderChip(
                    label: 'Birthdays soon',
                    value: '${vm.upcomingBirthdays.length}',
                    color: c.textSecondary,
                  ),
                ],
              ),
            ],
          ),
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
    final c = QColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(SpaceTokens.s8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: RadiusTokens.smAll,
        ),
        child: Column(
          children: [
            MonoText(value,
                size: 18, weight: FontWeight.w700, color: color),
            Text(label,
                style: TextStyles.bodySm(context)
                    .copyWith(color: c.textSecondary, fontSize: 9),
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
    final upcoming =
        vm.upcomingReminders.where((r) => !r.isOverdue).take(5).toList();

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
    final c = QColors.of(context);
    final color = isOverdue ? c.danger : c.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: SpaceTokens.s4),
      decoration: BoxDecoration(
        border: Border.all(
            color: isOverdue ? c.danger.withValues(alpha: 0.3) : c.border),
        borderRadius: RadiusTokens.smAll,
      ),
      child: Row(
        children: [
          // Reminder emoji is user data — preserve
          Padding(
            padding: const EdgeInsets.all(SpaceTokens.s12),
            child: Text(reminder.reminderType.emoji,
                style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: TextStyles.bodyMd(context)),
                Text(
                  isOverdue ? 'Overdue' : _dueLabel(reminder.dueAt),
                  style: TextStyles.bodySm(context).copyWith(color: color),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onComplete,
            child: Padding(
              padding: const EdgeInsets.all(SpaceTokens.s12),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: c.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: c.success.withValues(alpha: 0.4)),
                ),
                child:
                    Icon(Icons.check, size: 14, color: c.success),
              ),
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
    final c = QColors.of(context);
    if (vm.people.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            Text('Add people who matter',
                style: TextStyles.bodyMd(context)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: SpaceTokens.s4),
            Text(
              'Track relationships, birthdays, and stay present with the people you love.',
              style: TextStyles.bodySm(context).copyWith(color: c.textSecondary),
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
