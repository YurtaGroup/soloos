import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/api_service.dart';
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
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Project',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
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
                    final added = await vm.addProject(name: nameCtrl.text, description: descCtrl.text);
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

  void _showJoinDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Join a Project',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Enter invite code'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.directRequest('POST', '/api/projects/join', body: {'code': ctrl.text.trim()});
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        context.read<ProjectsViewModel>().reload();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Joined project!')),
                        );
                      }
                    } on ApiException catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                  child: const Text('Join'),
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
          if (ApiService.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.group_add_outlined, color: AppColors.textSecondary, size: 22),
              onPressed: () => _showJoinDialog(context),
              tooltip: 'Join project',
            ),
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

  const _ProjectCard({required this.project, required this.onDelete});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _expanded = false;
  bool _kanbanView = false;

  Future<void> _addTask(ProjectsViewModel vm) async {
    final ctrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String priority = 'medium';
    DateTime? dueDate;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Task',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Task name')),
              const SizedBox(height: 12),
              TextField(controller: urlCtrl, style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(hintText: 'URL (optional)', prefixIcon: Icon(Icons.link, size: 18))),
              const SizedBox(height: 12),
              Row(
                children: ['high', 'medium', 'low'].map((p) {
                  final selected = priority == p;
                  final c = p == 'high' ? AppColors.accentRed : p == 'low' ? AppColors.accentGreen : AppColors.accent;
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
              _DueDatePicker(dueDate: dueDate, onChanged: (d) => setModalState(() => dueDate = d)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    vm.addTask(widget.project, title: ctrl.text, priority: priority, dueDate: dueDate);
                    // Set url after creation if provided
                    if (urlCtrl.text.trim().isNotEmpty) {
                      final task = widget.project.tasks.last;
                      vm.editTask(task, url: urlCtrl.text.trim());
                    }
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
    final urlCtrl = TextEditingController(text: task.url ?? '');
    String priority = task.priority;
    String status = task.status;
    DateTime? dueDate = task.dueDate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Task',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: ctrl, autofocus: true, style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Task name')),
              const SizedBox(height: 12),
              TextField(controller: urlCtrl, style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(hintText: 'URL (optional)', prefixIcon: Icon(Icons.link, size: 18))),
              const SizedBox(height: 12),
              // Status selector
              Row(
                children: ['todo', 'in_progress', 'done'].map((s) {
                  final selected = status == s;
                  final label = s == 'todo' ? 'To Do' : s == 'in_progress' ? 'In Progress' : 'Done';
                  final c = s == 'done' ? AppColors.accentGreen : s == 'in_progress' ? AppColors.accent : AppColors.textSecondary;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => status = s),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? c.withValues(alpha: 0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? c.withValues(alpha: 0.5) : Colors.transparent),
                        ),
                        child: Text(label, textAlign: TextAlign.center,
                            style: TextStyle(color: selected ? c : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Priority
              Row(
                children: ['high', 'medium', 'low'].map((p) {
                  final selected = priority == p;
                  final c = p == 'high' ? AppColors.accentRed : p == 'low' ? AppColors.accentGreen : AppColors.accent;
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
              _DueDatePicker(dueDate: dueDate, onChanged: (d) => setModalState(() => dueDate = d)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    vm.editTask(task,
                        title: ctrl.text, priority: priority, status: status,
                        url: urlCtrl.text.trim(), dueDate: dueDate,
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

  Future<void> _inviteToProject() async {
    try {
      final data = await ApiService.directRequest('POST', '/api/projects/${widget.project.id}/invite');
      final code = data['code'] as String;
      if (mounted) {
        Share.share('Join my project "${widget.project.name}" on Solo OS! Code: $code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate invite')),
        );
      }
    }
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
        border: Border.all(color: AppColors.workColor.withValues(alpha: 0.2)),
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
                      Container(width: 10, height: 10,
                          decoration: const BoxDecoration(color: AppColors.workColor, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Text('${p.completedTasks}/${p.tasks.length}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 4),
                      if (ApiService.isAuthenticated)
                        GestureDetector(
                          onTap: _inviteToProject,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.person_add_outlined, color: AppColors.textMuted, size: 18),
                          ),
                        ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (p.tasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.progress,
                        backgroundColor: AppColors.workColor.withValues(alpha: 0.15),
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
                // View toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _kanbanView = false),
                        child: Text('List', style: TextStyle(
                          color: !_kanbanView ? AppColors.workColor : AppColors.textMuted,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => setState(() => _kanbanView = true),
                        child: Text('Board', style: TextStyle(
                          color: _kanbanView ? AppColors.workColor : AppColors.textMuted,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _addTask(vm),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add task'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.workColor, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                ),
                if (_kanbanView)
                  _KanbanBoard(project: p, vm: vm, onEdit: (t) => _editTask(context, vm, t))
                else
                  ...p.tasks.map((task) => _TaskTile(
                    task: task,
                    onToggle: () { HapticFeedback.lightImpact(); vm.toggleTask(task); setState(() {}); },
                    onDelete: () { vm.deleteTask(p, task); setState(() {}); },
                    onEdit: () => _editTask(context, vm, task),
                  )),
                const SizedBox(height: 8),
              ],
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// ── Kanban Board ────────────────────────────────────────────────────────────

class _KanbanBoard extends StatelessWidget {
  final Project project;
  final ProjectsViewModel vm;
  final void Function(Task) onEdit;

  const _KanbanBoard({required this.project, required this.vm, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final todo = project.tasks.where((t) => t.status == 'todo').toList();
    final inProgress = project.tasks.where((t) => t.status == 'in_progress').toList();
    final done = project.tasks.where((t) => t.status == 'done').toList();

    return SizedBox(
      height: _boardHeight(todo.length, inProgress.length, done.length),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KanbanColumn(title: 'To Do', tasks: todo, color: AppColors.textSecondary, vm: vm, project: project, targetStatus: 'todo', onEdit: onEdit),
            const SizedBox(width: 8),
            _KanbanColumn(title: 'In Progress', tasks: inProgress, color: AppColors.accent, vm: vm, project: project, targetStatus: 'in_progress', onEdit: onEdit),
            const SizedBox(width: 8),
            _KanbanColumn(title: 'Done', tasks: done, color: AppColors.accentGreen, vm: vm, project: project, targetStatus: 'done', onEdit: onEdit),
          ],
        ),
      ),
    );
  }

  double _boardHeight(int todo, int inProgress, int done) {
    final max = [todo, inProgress, done].reduce((a, b) => a > b ? a : b);
    return (max * 72.0 + 44).clamp(120.0, 500.0);
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Color color;
  final ProjectsViewModel vm;
  final Project project;
  final String targetStatus;
  final void Function(Task) onEdit;

  const _KanbanColumn({
    required this.title, required this.tasks, required this.color,
    required this.vm, required this.project, required this.targetStatus, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DragTarget<Task>(
        onWillAcceptWithDetails: (details) => details.data.status != targetStatus,
        onAcceptWithDetails: (details) {
          vm.editTask(details.data, status: targetStatus);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty
                  ? color.withValues(alpha: 0.08)
                  : AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: candidateData.isNotEmpty ? color.withValues(alpha: 0.4) : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('${tasks.length}', style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 11)),
                    ],
                  ),
                ),
                ...tasks.map((t) => Draggable<Task>(
                  data: t,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                      ),
                      child: Text(t.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _KanbanCard(task: t, onEdit: () => onEdit(t)),
                  ),
                  child: _KanbanCard(task: t, onEdit: () => onEdit(t)),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  const _KanbanCard({required this.task, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 2, 4, 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                if (task.dueDate != null)
                  Text(DateFormat('MMM d').format(task.dueDate!),
                      style: TextStyle(
                        color: task.dueDate!.isBefore(DateTime.now()) && task.status != 'done'
                            ? AppColors.accentRed : AppColors.textMuted,
                        fontSize: 10)),
                if (task.url != null && task.url!.isNotEmpty) ...[
                  if (task.dueDate != null) const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(task.url!), mode: LaunchMode.externalApplication),
                    child: const Icon(Icons.link, size: 12, color: AppColors.primary),
                  ),
                ],
                const Spacer(),
                PriorityBadge(task.priority),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _DueDatePicker extends StatelessWidget {
  final DateTime? dueDate;
  final ValueChanged<DateTime?> onChanged;
  const _DueDatePicker({required this.dueDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
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
            Icon(Icons.calendar_today_rounded, size: 16,
                color: dueDate != null ? AppColors.workColor : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate!) : 'Due date (optional)',
              style: TextStyle(color: dueDate != null ? AppColors.textPrimary : AppColors.textMuted, fontSize: 13),
            ),
            const Spacer(),
            if (dueDate != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskTile({required this.task, required this.onToggle, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null && !task.isDone && task.dueDate!.isBefore(DateTime.now());

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
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: task.isDone ? AppColors.workColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: task.isDone ? AppColors.workColor : AppColors.textMuted, width: task.isDone ? 0 : 1.5),
                  ),
                  child: task.isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(task.title,
                              style: TextStyle(
                                color: task.isDone ? AppColors.textMuted : AppColors.textPrimary,
                                fontSize: 14,
                                decoration: task.isDone ? TextDecoration.lineThrough : null)),
                        ),
                        if (task.url != null && task.url!.isNotEmpty)
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse(task.url!), mode: LaunchMode.externalApplication),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.link, size: 14, color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                    if (task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(DateFormat('MMM d').format(task.dueDate!),
                            style: TextStyle(color: isOverdue ? AppColors.accentRed : AppColors.textMuted, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              // Status chip
              if (task.status == 'in_progress')
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('WIP', style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              PriorityBadge(task.priority),
            ],
          ),
        ),
      ),
    );
  }
}
