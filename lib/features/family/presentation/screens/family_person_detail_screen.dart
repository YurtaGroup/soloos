import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/family_person.dart';
import '../../domain/models/family_reminder.dart';
import '../../domain/models/relationship_note.dart';
import '../viewmodels/family_viewmodel.dart';
import '../widgets/ai_suggestion_card.dart';
import 'add_edit_family_person_screen.dart';

class FamilyPersonDetailScreen extends StatelessWidget {
  final String personId;
  const FamilyPersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FamilyViewModel>();
    final person = vm.people.where((p) => p.id == personId).firstOrNull;

    if (person == null) {
      return const Scaffold(body: Center(child: Text('Person not found')));
    }

    final reminders = vm.getRemindersForPerson(personId);
    final notes = vm.getNotesForPerson(personId);
    final suggestions = vm.getSuggestionsForPerson(personId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(person.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      AddEditFamilyPersonScreen(existing: person)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PersonHeader(person: person),
            const SizedBox(height: 16),
            _QuickActions(
              person: person,
              onContactedToday: () =>
                  context.read<FamilyViewModel>().markContactedToday(personId),
              onAddReminder: () => _showAddReminder(context, personId),
              onAddNote: () => _showAddNote(context, personId),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionHeader('💡 Suggestions'),
              const SizedBox(height: 8),
              ...suggestions.map((s) => AiSuggestionCard(
                    suggestion: s,
                    onActedOn: () {
                      vm.markSuggestionActedOn(s.id);
                      vm.markContactedToday(personId);
                    },
                    onDismiss: () => vm.dismissSuggestion(s.id),
                  )),
            ],
            if (reminders.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionHeader('⏰ Reminders'),
              const SizedBox(height: 8),
              ...reminders.map((r) => _ReminderItem(
                    reminder: r,
                    onComplete: () => vm.completeReminder(r.id),
                    onDelete: () => vm.deleteReminder(r.id),
                  )),
            ],
            const SizedBox(height: 20),
            _sectionHeader('📝 Notes'),
            const SizedBox(height: 8),
            if (notes.isEmpty)
              const _EmptyItem(message: 'No notes yet')
            else
              ...notes.map((n) => _NoteItem(
                    note: n,
                    onDelete: () => vm.deleteNote(n.id),
                  )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  void _showAddReminder(BuildContext context, String personId) {
    final titleCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Reminder',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(hintText: 'e.g. Call for birthday'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                context.read<FamilyViewModel>().addReminder(FamilyReminder(
                      personId: personId,
                      title: titleCtrl.text.trim(),
                      reminderType: ReminderType.custom,
                      dueAt: DateTime.now().add(const Duration(days: 1)),
                    ));
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
              child: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNote(BuildContext context, String personId) {
    final ctrl = TextEditingController();
    var type = NoteType.other;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Note',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'What do you want to remember?'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<NoteType>(
                value: type,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Type'),
                items: NoteType.values
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text('${t.emoji} ${t.label}')))
                    .toList(),
                onChanged: (v) => v != null ? setState(() => type = v) : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.trim().isEmpty) return;
                  context.read<FamilyViewModel>().addNote(RelationshipNote(
                        personId: personId,
                        content: ctrl.text.trim(),
                        noteType: type,
                      ));
                  Navigator.pop(ctx2);
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                child: const Text('Save Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonHeader extends StatelessWidget {
  final FamilyPerson person;
  const _PersonHeader({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(person.relationshipType.emoji,
              style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(person.fullName,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          Text(person.relationshipType.label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(
                label: 'Last contact',
                value: person.daysSinceContact != null
                    ? '${person.daysSinceContact}d ago'
                    : 'Never',
                color: person.isContactOverdue
                    ? AppColors.accentRed
                    : AppColors.textPrimary,
              ),
              _Stat(
                label: 'Goal',
                value: person.contactFrequencyGoalDays != null
                    ? 'Every ${person.contactFrequencyGoalDays}d'
                    : 'Not set',
                color: AppColors.textPrimary,
              ),
              if (person.birthday != null)
                _Stat(
                  label: 'Birthday',
                  value: 'In ${person.daysUntilBirthday}d',
                  color: person.isBirthdaySoon
                      ? AppColors.accent
                      : AppColors.textPrimary,
                ),
            ],
          ),
          if (person.notesSummary.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.textMuted, height: 1),
            const SizedBox(height: 10),
            Text(person.notesSummary,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final FamilyPerson person;
  final VoidCallback onContactedToday;
  final VoidCallback onAddReminder;
  final VoidCallback onAddNote;
  const _QuickActions({
    required this.person,
    required this.onContactedToday,
    required this.onAddReminder,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(
            icon: Icons.check_circle_outline,
            label: 'Contacted',
            color: AppColors.accentGreen,
            onTap: onContactedToday),
        const SizedBox(width: 8),
        _ActionBtn(
            icon: Icons.alarm_add_outlined,
            label: 'Reminder',
            color: AppColors.accent,
            onTap: onAddReminder),
        const SizedBox(width: 8),
        _ActionBtn(
            icon: Icons.note_add_outlined,
            label: 'Note',
            color: AppColors.accentBlue,
            onTap: onAddNote),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  final FamilyReminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  const _ReminderItem(
      {required this.reminder,
      required this.onComplete,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: reminder.isOverdue
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
                    style: TextStyle(
                        color: reminder.isCompleted
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 13,
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null)),
                Text(
                  reminder.isCompleted
                      ? 'Done'
                      : reminder.isOverdue
                          ? 'Overdue'
                          : '${reminder.dueAt.month}/${reminder.dueAt.day}',
                  style: TextStyle(
                    color: reminder.isCompleted
                        ? AppColors.textMuted
                        : reminder.isOverdue
                            ? AppColors.accentRed
                            : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!reminder.isCompleted)
            GestureDetector(
              onTap: onComplete,
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.accentGreen, size: 22),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
          ),
        ],
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final RelationshipNote note;
  final VoidCallback onDelete;
  const _NoteItem({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.noteType.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(note.content,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, color: AppColors.textMuted, size: 14),
          ),
        ],
      ),
    );
  }
}

class _EmptyItem extends StatelessWidget {
  final String message;
  const _EmptyItem({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(10)),
      child: Text(message,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    );
  }
}
