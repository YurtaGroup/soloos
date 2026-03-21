import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../models/app_models.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _storage = StorageService();
  late List<Project> _projects;

  @override
  void initState() {
    super.initState();
    _projects = _storage.getProjects();
  }

  void _reload() {
    setState(() => _projects = _storage.getProjects());
  }

  Future<void> _addProject() async {
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
                decoration: const InputDecoration(
                  hintText: 'Project name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final p = Project(
                      id: const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                    final projects = _storage.getProjects()..add(p);
                    await _storage.saveProjects(projects);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _reload();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Work'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.workColor),
            onPressed: _addProject,
          ),
        ],
      ),
      body: _projects.isEmpty
          ? EmptyState(
              emoji: '📋',
              title: 'No projects yet',
              subtitle: 'Create your first project\nand start tracking tasks.',
              onAction: _addProject,
              actionLabel: '+ New Project',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _projects.length,
              itemBuilder: (ctx, i) => _ProjectCard(
                project: _projects[i],
                onUpdate: () async {
                  await _storage.saveProjects(_projects);
                  _reload();
                },
                onDelete: () async {
                  _projects.removeAt(i);
                  await _storage.saveProjects(_projects);
                  _reload();
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _expanded = false;

  Future<void> _addTask() async {
    final ctrl = TextEditingController();
    String priority = 'medium';
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
                          color: selected ? c.withOpacity(0.2) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? c : AppColors.textMuted.withOpacity(0.3),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    widget.project.tasks.add(Task(
                      id: const Uuid().v4(),
                      title: ctrl.text.trim(),
                      priority: priority,
                    ));
                    widget.onUpdate();
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

  @override
  Widget build(BuildContext context) {
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
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
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
                        decoration: BoxDecoration(
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
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.textMuted,
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

          // Tasks
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFF252535)),
            ...p.tasks.map((task) => _TaskTile(
                  task: task,
                  onToggle: () {
                    task.isDone = !task.isDone;
                    widget.onUpdate();
                    setState(() {});
                  },
                  onDelete: () {
                    p.tasks.remove(task);
                    widget.onUpdate();
                    setState(() {});
                  },
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextButton.icon(
                onPressed: _addTask,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add task'),
                style: TextButton.styleFrom(foregroundColor: AppColors.workColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.accentRed.withOpacity(0.2),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: task.isDone ? AppColors.workColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: task.isDone ? AppColors.workColor : AppColors.textMuted,
                  ),
                ),
                child: task.isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  color: task.isDone ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: 14,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            PriorityBadge(task.priority),
          ],
        ),
      ),
    );
  }
}
