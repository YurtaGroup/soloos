import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import '../viewmodels/projects_view_model.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  Future<void> _showAddDialog(BuildContext context, ProjectsViewModel vm) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Project',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Project name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Description (optional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final added = await vm.addProject(
                      name: nameCtrl.text,
                      description: descCtrl.text,
                    );
                    if (added && ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Create Project'),
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
    final vm = context.watch<ProjectsViewModel>();
    final projects = vm.projects;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Work'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.workColor),
            onPressed: () => _showAddDialog(context, vm),
          ),
        ],
      ),
      body: projects.isEmpty
          ? EmptyState(
              emoji: '📋',
              title: 'No projects yet',
              subtitle: 'Create your first project\nand start tracking tasks.',
              onAction: () => _showAddDialog(context, vm),
              actionLabel: '+ New Project',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (ctx, i) => _ProjectCard(
                project: projects[i],
                onDelete: () => vm.deleteProject(i),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'projects_fab',
        onPressed: () => _showAddDialog(context, vm),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onDelete,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  Future<void> _addTask(ProjectsViewModel vm) async {
    final ctrl = TextEditingController();
    String priority = 'medium';
    DateTime? dueDate;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                'Add Task',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Task name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['high', 'medium', 'low'].map((p) {
                  final selected = priority == p;
                  Color c;
                  switch (p) {
                    case 'high':
                      c = AppColors.accentRed;
                      break;
                    case 'low':
                      c = AppColors.accentGreen;
                      break;
                    default:
                      c = AppColors.accent;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setModalState(() => priority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? c.withValues(alpha: 0.2) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? c : AppColors.textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          p.toUpperCase(),
                          style: TextStyle(
                            color: selected ? c : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Due date picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModalState(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16, color: dueDate != null ? AppColors.workColor : AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate!) : 'Due date (optional)',
                        style: TextStyle(
                          color: dueDate != null ? AppColors.textPrimary : AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (dueDate != null)
                        GestureDetector(
                          onTap: () => setModalState(() => dueDate = null),
                          child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    vm.addTask(widget.project,
                        title: ctrl.text, priority: priority, dueDate: dueDate);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editTask(BuildContext context, ProjectsViewModel vm, Task task) {
    final ctrl = TextEditingController(text: task.title);
    String priority = task.priority;
    DateTime? dueDate = task.dueDate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              const Text('Edit Task',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Task name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['high', 'medium', 'low'].map((p) {
                  final selected = priority == p;
                  Color c;
                  switch (p) {
                    case 'high': c = AppColors.accentRed; break;
                    case 'low': c = AppColors.accentGreen; break;
                    default: c = AppColors.accent;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setModalState(() => priority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? c.withValues(alpha: 0.2) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? c : AppColors.textMuted.withValues(alpha: 0.3)),
                        ),
                        child: Text(p.toUpperCase(),
                            style: TextStyle(color: selected ? c : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModalState(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16, color: dueDate != null ? AppColors.workColor : AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate!) : 'Due date (optional)',
                        style: TextStyle(color: dueDate != null ? AppColors.textPrimary : AppColors.textMuted, fontSize: 13),
                      ),
                      const Spacer(),
                      if (dueDate != null)
                        GestureDetector(
                          onTap: () => setModalState(() => dueDate = null),
                          child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    vm.editTask(task,
                        title: ctrl.text,
                        priority: priority,
                        dueDate: dueDate,
                        clearDueDate: dueDate == null && task.dueDate != null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
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
    final vm = context.watch<ProjectsViewModel>();
    final p = widget.project;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.workColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.workColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${p.completedTasks}/${p.tasks.length}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (p.tasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.progress,
                        backgroundColor: AppColors.workColor.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation(AppColors.workColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFF252535)),
                ...p.tasks.map((task) => _TaskTile(
                      task: task,
                      onToggle: () {
                        HapticFeedback.lightImpact();
                        vm.toggleTask(task);
                        setState(() {});
                      },
                      onDelete: () {
                        vm.deleteTask(p, task);
                        setState(() {});
                      },
                      onEdit: () => _editTask(context, vm, task),
                    )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextButton.icon(
                    onPressed: () => _addTask(vm),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add task'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.workColor),
                  ),
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null &&
        !task.isDone &&
        task.dueDate!.isBefore(DateTime.now());

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.accentRed.withValues(alpha: 0.2),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: task.isDone ? AppColors.workColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: task.isDone ? AppColors.workColor : AppColors.textMuted,
                      width: task.isDone ? 0 : 1.5,
                    ),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: task.isDone ? AppColors.textMuted : AppColors.textPrimary,
                        fontSize: 14,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          DateFormat('MMM d').format(task.dueDate!),
                          style: TextStyle(
                            color: isOverdue ? AppColors.accentRed : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PriorityBadge(task.priority),
            ],
          ),
        ),
      ),
    );
  }
}
