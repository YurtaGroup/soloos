// lib/features/work/presentation/screens/tasks_screen.dart
//
// Quiet OS — Week 3: Things 3 + Linear style task surface.
//
// Layout: single scrollable column with three smart lists.
//   TODAY    — tasks due today, sorted in_progress → todo → done
//   INBOX    — tasks with no due date (null dueDate, not done)
//   UPCOMING — tasks with a future due date, grouped by date
//
// Data: reads from ProjectsViewModel.projects (no new ViewModel).
// "Inbox" tasks are stored in the first project (default bucket).
// When no project exists, a create-project prompt is shown.
//
// Inbox decision: tasks created without a project are assigned to
// the first project in the list, treated as a synthetic "Personal"
// default bucket. This avoids a separate data model while keeping
// the screen working day-one. The project name is never surfaced in
// the Inbox list UI — the list IS the inbox. When the user has
// multiple projects the Inbox still works correctly because it
// filters on dueDate==null regardless of which project owns the task.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/mono_text.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/app_input.dart';

import '../../../work/presentation/viewmodels/projects_view_model.dart';
import '../../../work/domain/models/task.dart';
import '../../../work/domain/models/project.dart';

// ---------------------------------------------------------------------------
// DERIVED TYPE — task with its owning project reference
// ---------------------------------------------------------------------------

class _TaskRef {
  const _TaskRef({required this.task, required this.project});
  final Task task;
  final Project project;
}

// ---------------------------------------------------------------------------
// TASKS SCREEN
// ---------------------------------------------------------------------------

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // Which smart list is the "active" one for the + header button.
  // 0 = Today, 1 = Inbox, 2 = Upcoming
  int _activeList = 0;

  // Typed GlobalKeys so the header + button can call openCreate() on
  // whichever smart list is currently active.
  final _todayKey    = GlobalKey<_TodayListState>();
  final _inboxKey    = GlobalKey<_InboxListState>();
  final _upcomingKey = GlobalKey<_UpcomingListState>();

  void _openCreateOnActiveList() {
    switch (_activeList) {
      case 0:
        _todayKey.currentState?.openCreate();
      case 1:
        _inboxKey.currentState?.openCreate();
      case 2:
        _upcomingKey.currentState?.openCreate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final vm = context.watch<ProjectsViewModel>();

    // Guard: no projects yet → show create-project prompt
    if (!vm.loading && vm.projects.isEmpty) {
      return _NoProjectsPrompt(vm: vm);
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── HEADER ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SpaceTokens.s16,
              topInset + SpaceTokens.s8,
              SpaceTokens.s8,
              SpaceTokens.s16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Tasks',
                    style: TextStyles.displayMd(context),
                  ),
                ),
                // Keyboard shortcuts sheet
                IconButton(
                  icon: const Icon(Icons.keyboard_outlined, size: 20),
                  color: c.textSecondary,
                  tooltip: 'Keyboard shortcuts',
                  onPressed: () => _showShortcutsSheet(context),
                ),
                // Add task to active list
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  color: c.textSecondary,
                  tooltip: 'Add task',
                  onPressed: _openCreateOnActiveList,
                ),
              ],
            ),
          ),
        ),

        // ── SMART LISTS ───────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            SpaceTokens.s16, 0,
            SpaceTokens.s16, SpaceTokens.s48,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _TodayList(
                key: _todayKey,
                onActivated: () => setState(() => _activeList = 0),
              ),
              const SizedBox(height: SpaceTokens.s32),
              _InboxList(
                key: _inboxKey,
                onActivated: () => setState(() => _activeList = 1),
              ),
              const SizedBox(height: SpaceTokens.s32),
              _UpcomingList(
                key: _upcomingKey,
                onActivated: () => setState(() => _activeList = 2),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  void _showShortcutsSheet(BuildContext context) {
    final c = QColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SpaceTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Keyboard shortcuts',
                  style: TextStyles.displayMd(context)),
              const SizedBox(height: SpaceTokens.s24),
              _ShortcutRow(keys: '⌘ N', label: 'New task in active list'),
              _ShortcutRow(keys: '↩', label: 'Commit and add another'),
              _ShortcutRow(keys: 'Esc', label: 'Cancel inline create'),
              _ShortcutRow(keys: '⌘ ↩', label: 'Toggle complete (focused row)'),
              const SizedBox(height: SpaceTokens.s8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.keys, required this.label});
  final String keys;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpaceTokens.s8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: RadiusTokens.smAll,
            ),
            child: MonoText(keys, size: 12, color: c.textSecondary),
          ),
          const SizedBox(width: SpaceTokens.s12),
          Text(label, style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NO PROJECTS PROMPT
// ---------------------------------------------------------------------------

class _NoProjectsPrompt extends StatelessWidget {
  const _NoProjectsPrompt({required this.vm});
  final ProjectsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SpaceTokens.s24,
        topInset + SpaceTokens.s48,
        SpaceTokens.s24,
        SpaceTokens.s48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionLabel('TASKS', bottomPadding: SpaceTokens.s8),
          Text(
            'You need a project first.',
            style: TextStyles.displayMd(context),
          ),
          const SizedBox(height: SpaceTokens.s8),
          Text(
            'Tasks live inside projects. Create a personal one to get started.',
            style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SpaceTokens.s24),
          AppButton(
            label: 'Create Personal project',
            onPressed: () async {
              await vm.addProject(name: 'Personal');
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HELPERS — date math and formatting
// ---------------------------------------------------------------------------

bool _isTomorrow(DateTime dt) {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return dt.year == tomorrow.year &&
      dt.month == tomorrow.month &&
      dt.day == tomorrow.day;
}

bool _isFuture(DateTime dt) {
  final today = DateTime.now();
  final d = DateTime(dt.year, dt.month, dt.day);
  final t = DateTime(today.year, today.month, today.day);
  return d.isAfter(t);
}

String _formatDateDivider(DateTime dt) {
  if (_isTomorrow(dt)) return 'Tomorrow';
  return DateFormat('EEE, MMM d').format(dt);
}

String _formatTime(DateTime dt) {
  // Only show time if it's not midnight exactly
  if (dt.hour == 0 && dt.minute == 0) return '';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// TASK STATUS CIRCLE — 22pt leading indicator
// ---------------------------------------------------------------------------

class _StatusCircle extends StatefulWidget {
  const _StatusCircle({
    required this.task,
    required this.project,
    required this.onToggle,
    required this.onSetInProgress,
  });

  final Task task;
  final Project project;
  final VoidCallback onToggle;
  final VoidCallback onSetInProgress;

  @override
  State<_StatusCircle> createState() => _StatusCircleState();
}

class _StatusCircleState extends State<_StatusCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: MotionTokens.duration,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: MotionTokens.curve);
    if (widget.task.isDone) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_StatusCircle old) {
    super.didUpdateWidget(old);
    if (widget.task.isDone && !old.task.isDone) {
      _ctrl.forward();
    } else if (!widget.task.isDone && old.task.isDone) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final isDone = widget.task.isDone;
    final isInProgress = widget.task.status == 'in_progress';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onToggle();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onSetInProgress();
      },
      child: SizedBox(
        width: 22,
        height: 22,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return CustomPaint(
              painter: _CirclePainter(
                progress: _anim.value,
                isDone: isDone,
                isInProgress: isInProgress,
                strokeColor: c.border,
                limeColor: ColorTokens.lime500,
                checkColor: c.appBg,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  const _CirclePainter({
    required this.progress,
    required this.isDone,
    required this.isInProgress,
    required this.strokeColor,
    required this.limeColor,
    required this.checkColor,
  });

  final double progress;
  final bool isDone;
  final bool isInProgress;
  final Color strokeColor;
  final Color limeColor;
  final Color checkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    // Outer stroke circle
    final strokePaint = Paint()
      ..color = Color.lerp(strokeColor, limeColor, progress)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, strokePaint);

    if (isDone) {
      // Filled circle — lime fill grows in with progress
      final fillPaint = Paint()
        ..color = limeColor.withValues(alpha: progress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * progress, fillPaint);

      // Checkmark — appears at 60% progress
      if (progress > 0.6) {
        final t = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
        final checkPaint = Paint()
          ..color = checkColor.withValues(alpha: t)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        // Simple check path: v-shape
        final cx = center.dx;
        final cy = center.dy;
        final r = radius * 0.55;
        final p1 = Offset(cx - r * 0.6, cy);
        final p2 = Offset(cx - r * 0.1, cy + r * 0.6);
        final p3 = Offset(cx + r * 0.7, cy - r * 0.5);

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy);
        canvas.drawPath(path, checkPaint);
      }
    } else if (isInProgress) {
      // Inner lime dot — 8px filled circle
      final dotPaint = Paint()
        ..color = limeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.progress != progress ||
      old.isDone != isDone ||
      old.isInProgress != isInProgress;
}

// ---------------------------------------------------------------------------
// TASK ROW — the single-line row atom for this screen
// ---------------------------------------------------------------------------

class _TaskRow extends StatefulWidget {
  const _TaskRow({required this.taskRef});

  final _TaskRef taskRef;

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow>
    with SingleTickerProviderStateMixin {
  // Things 3 trick: defer visual collapse 1.2s after completion
  // so the user has a moment to undo before the row disappears.
  Timer? _removeTimer;
  double _targetHeight = 1.0; // 1.0 = full, 0.0 = collapsed

  @override
  void dispose() {
    _removeTimer?.cancel();
    super.dispose();
  }

  void _scheduleRemoval() {
    _removeTimer?.cancel();
    _removeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _targetHeight = 0.0);
    });
  }

  @override
  void didUpdateWidget(_TaskRow old) {
    super.didUpdateWidget(old);
    final wasNotDone = !old.taskRef.task.isDone;
    final isNowDone = widget.taskRef.task.isDone;
    if (wasNotDone && isNowDone) {
      _scheduleRemoval();
    }
    if (!isNowDone) {
      _removeTimer?.cancel();
      setState(() => _targetHeight = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProjectsViewModel>();
    final c = QColors.of(context);
    final task = widget.taskRef.task;
    final project = widget.taskRef.project;
    final isDone = task.isDone;
    final isHigh = task.priority == 'high';
    final timeLabel = task.dueDate != null ? _formatTime(task.dueDate!) : '';
    final trailingText = timeLabel.isNotEmpty
        ? timeLabel
        : isDone
            ? 'done'
            : '';

    Widget row = Dismissible(
      key: ValueKey('task_${task.id}'),
      // Swipe right → complete
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: SpaceTokens.s16),
        color: c.danger,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 18),
            const SizedBox(width: SpaceTokens.s8),
            Text('Delete',
                style: TextStyles.bodyMd(context)
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: SpaceTokens.s16),
        color: ColorTokens.lime500,
        child: Row(
          children: [
            const Icon(Icons.check_rounded, color: ColorTokens.ink900, size: 18),
            const SizedBox(width: SpaceTokens.s8),
            Text('Done',
                style: TextStyles.bodyMd(context).copyWith(
                  color: ColorTokens.ink900,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Complete
          if (!task.isDone) vm.toggleTask(task);
          return false; // keep in list; the animation handles fade-out
        } else {
          // Delete — no confirm dialog; this is a swipe gesture, intentional
          await vm.deleteTask(project, task);
          return true;
        }
      },
      onDismissed: (_) {},
      child: InkWell(
        onTap: () => _showEditSheet(context, vm, task, project),
        splashColor: c.border.withValues(alpha: 0.12),
        highlightColor: c.border.withValues(alpha: 0.06),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // High-priority lime bar (3px, trailing edge of leading area)
              if (isHigh)
                Container(
                  width: 3,
                  color: ColorTokens.lime500,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpaceTokens.s16,
                    vertical: SpaceTokens.s12,
                  ),
                  child: Row(
                    children: [
                      // Status circle
                      _StatusCircle(
                        task: task,
                        project: project,
                        onToggle: () {
                          HapticFeedback.lightImpact();
                          vm.toggleTask(task);
                        },
                        onSetInProgress: () {
                          final nextStatus = task.status == 'in_progress'
                              ? 'todo'
                              : 'in_progress';
                          vm.editTask(task, status: nextStatus);
                        },
                      ),
                      const SizedBox(width: SpaceTokens.s12),

                      // Title with animated strikethrough
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: MotionTokens.duration,
                          curve: MotionTokens.curve,
                          style: TextStyles.bodyMd(context).copyWith(
                            color: isDone ? c.textDisabled : c.textPrimary,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: c.textDisabled,
                          ),
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Trailing time / "done" label
                      if (trailingText.isNotEmpty) ...[
                        const SizedBox(width: SpaceTokens.s12),
                        MonoText(
                          trailingText,
                          size: 13,
                          color: isDone ? c.textDisabled : c.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Animate collapse after completion delay
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: MotionTokens.curve,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: _targetHeight == 0.0 ? 0 : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row,
            Divider(
              height: 1,
              thickness: 1,
              color: c.border,
              indent: SpaceTokens.s16 + 22 + SpaceTokens.s12,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EDIT TASK SHEET — bottom sheet with inline editing
// ---------------------------------------------------------------------------

void _showEditSheet(
  BuildContext context,
  ProjectsViewModel vm,
  Task task,
  Project project,
) {
  final titleCtrl = TextEditingController(text: task.title);
  String priority = task.priority;
  String status = task.status;
  DateTime? dueDate = task.dueDate;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: QColors.of(context).surface,
    shape: const RoundedRectangleBorder(),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final c = QColors.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + SpaceTokens.s16,
            left: SpaceTokens.s16,
            right: SpaceTokens.s16,
            top: SpaceTokens.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('EDIT TASK', bottomPadding: SpaceTokens.s16),
              AppInput(
                controller: titleCtrl,
                autofocus: true,
                hintText: 'Task title',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: SpaceTokens.s16),

              // Status row
              Text('Status',
                  style: TextStyles.bodySm(ctx).copyWith(color: c.textSecondary)),
              const SizedBox(height: SpaceTokens.s8),
              Row(
                children: ['todo', 'in_progress', 'done'].map((s) {
                  final label = s == 'todo'
                      ? 'Todo'
                      : s == 'in_progress'
                          ? 'In Progress'
                          : 'Done';
                  final isSelected = status == s;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheet(() => status = s),
                      child: AnimatedContainer(
                        duration: MotionTokens.duration,
                        margin: const EdgeInsets.only(right: SpaceTokens.s8),
                        padding: const EdgeInsets.symmetric(
                          vertical: SpaceTokens.s8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? c.selectedRow
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? c.accent
                                : c.border,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyles.bodySm(ctx).copyWith(
                            color: isSelected ? c.textPrimary : c.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: SpaceTokens.s16),

              // Priority row
              Text('Priority',
                  style: TextStyles.bodySm(ctx).copyWith(color: c.textSecondary)),
              const SizedBox(height: SpaceTokens.s8),
              Row(
                children: ['high', 'medium', 'low'].map((p) {
                  final isSelected = priority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheet(() => priority = p),
                      child: AnimatedContainer(
                        duration: MotionTokens.duration,
                        margin: const EdgeInsets.only(right: SpaceTokens.s8),
                        padding: const EdgeInsets.symmetric(
                          vertical: SpaceTokens.s8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? c.selectedRow
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? c.accent : c.border,
                          ),
                        ),
                        child: Text(
                          p[0].toUpperCase() + p.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyles.bodySm(ctx).copyWith(
                            color: isSelected ? c.textPrimary : c.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: SpaceTokens.s16),

              // Due date picker row
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate:
                        dueDate ?? DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setSheet(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpaceTokens.s12,
                    vertical: SpaceTokens.s12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: c.textSecondary),
                      const SizedBox(width: SpaceTokens.s8),
                      Expanded(
                        child: Text(
                          dueDate != null
                              ? DateFormat('EEE, MMM d, yyyy').format(dueDate!)
                              : 'Due date (optional)',
                          style: TextStyles.bodyMd(ctx).copyWith(
                            color: dueDate != null
                                ? c.textPrimary
                                : c.textDisabled,
                          ),
                        ),
                      ),
                      if (dueDate != null)
                        GestureDetector(
                          onTap: () => setSheet(() => dueDate = null),
                          child:
                              Icon(Icons.close, size: 16, color: c.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SpaceTokens.s24),

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Save',
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        vm.editTask(
                          task,
                          title: titleCtrl.text,
                          priority: priority,
                          status: status,
                          dueDate: dueDate,
                          clearDueDate: dueDate == null && task.dueDate != null,
                        );
                        Navigator.pop(ctx);
                      },
                      isFullWidth: true,
                    ),
                  ),
                  const SizedBox(width: SpaceTokens.s12),
                  AppButton(
                    label: 'Delete',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      vm.deleteTask(project, task);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: SpaceTokens.s8),
            ],
          ),
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// INLINE CREATE ROW — ghost row → text field → commit
// ---------------------------------------------------------------------------

class _InlineCreate extends StatefulWidget {
  const _InlineCreate({
    required this.hintText,
    required this.onCommit,
    required this.onCancel,
  });

  final String hintText;
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  @override
  State<_InlineCreate> createState() => _InlineCreateState();
}

class _InlineCreateState extends State<_InlineCreate> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onCancel();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commit() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      widget.onCommit(text);
      _ctrl.clear();
      // Chain: immediately re-focus for the next task (Things 3 behavior)
      _focusNode.requestFocus();
    } else {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s4),
        child: Row(
          children: [
            // Placeholder circle matching the status circle size
            SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.border,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: SpaceTokens.s12),
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                autofocus: true,
                style: TextStyles.bodyMd(context).copyWith(color: c.textPrimary),
                cursorColor: ColorTokens.lime500,
                cursorWidth: 1.5,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _commit(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyles.bodyMd(context).copyWith(color: c.textDisabled),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GHOST ROW — "+ Add task" placeholder
// ---------------------------------------------------------------------------

class _GhostCreate extends StatelessWidget {
  const _GhostCreate({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s12),
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: c.textDisabled),
            const SizedBox(width: SpaceTokens.s12),
            Text(
              label,
              style: TextStyles.bodyMd(context).copyWith(color: c.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION HEADER ROW (icon + label + count)
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    this.countSuffix,
  });

  final IconData icon;
  final String label;
  final int count;
  final String? countSuffix;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textSecondary),
        const SizedBox(width: SpaceTokens.s8),
        SectionLabel(label, bottomPadding: 0),
        const Spacer(),
        if (countSuffix != null)
          MonoText(countSuffix!, size: 12, color: c.textSecondary)
        else if (count > 0)
          MonoText('$count', size: 12, color: c.textSecondary),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// TODAY LIST
// ---------------------------------------------------------------------------

class _TodayList extends StatefulWidget {
  const _TodayList({super.key, required this.onActivated});
  final VoidCallback onActivated;

  @override
  State<_TodayList> createState() => _TodayListState();
}

class _TodayListState extends State<_TodayList> {
  bool _showCreate = false;

  /// Called by parent via GlobalKey to open the inline create row.
  void openCreate() {
    widget.onActivated();
    setState(() => _showCreate = true);
  }

  List<_TaskRef> _todayTasks(ProjectsViewModel vm) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final refs = <_TaskRef>[];
    for (final project in vm.projects) {
      for (final task in project.tasks) {
        if (task.dueDate != null) {
          final d = DateTime(
              task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          if (d == today) refs.add(_TaskRef(task: task, project: project));
        }
      }
    }
    // Sort: in_progress → todo → done
    refs.sort((a, b) {
      int rank(_TaskRef r) {
        if (r.task.status == 'in_progress') return 0;
        if (!r.task.isDone) return 1;
        return 2;
      }
      return rank(a).compareTo(rank(b));
    });
    return refs;
  }

  void _createTask(BuildContext context, String title) {
    final vm = context.read<ProjectsViewModel>();
    if (vm.projects.isEmpty) return;
    final project = vm.projects.first;
    final now = DateTime.now();
    // Due date: today at midnight
    final dueDate = DateTime(now.year, now.month, now.day);
    vm.addTask(project, title: title, priority: 'medium', dueDate: dueDate);
    // Keep create row open for chaining
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<ProjectsViewModel>();
    final tasks = _todayTasks(vm);
    final doneCount = tasks.where((r) => r.task.isDone).length;
    final totalCount = tasks.length;

    return GestureDetector(
      onTap: widget.onActivated,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.today_outlined,
            label: 'TODAY',
            count: totalCount,
            countSuffix: totalCount > 0
                ? '$doneCount of $totalCount'
                : null,
          ),
          const SizedBox(height: SpaceTokens.s12),
          Divider(height: 1, thickness: 1, color: c.border),

          if (tasks.isEmpty && !_showCreate)
            _GhostCreate(
              label: 'Plan your day',
              onTap: () {
                widget.onActivated();
                setState(() => _showCreate = true);
              },
            )
          else ...[
            ...tasks.map((ref) => _TaskRow(taskRef: ref)),
          ],

          // Inline create
          AnimatedSize(
            duration: MotionTokens.duration,
            curve: MotionTokens.curve,
            child: _showCreate
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InlineCreate(
                        hintText: 'Task title',
                        onCommit: (title) => _createTask(context, title),
                        onCancel: () => setState(() => _showCreate = false),
                      ),
                      Divider(height: 1, thickness: 1, color: c.border),
                    ],
                  )
                : tasks.isNotEmpty
                    ? _GhostCreate(
                        label: 'Add task to Today',
                        onTap: () {
                          widget.onActivated();
                          setState(() => _showCreate = true);
                        },
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// INBOX LIST
// ---------------------------------------------------------------------------

class _InboxList extends StatefulWidget {
  const _InboxList({super.key, required this.onActivated});
  final VoidCallback onActivated;

  @override
  State<_InboxList> createState() => _InboxListState();
}

class _InboxListState extends State<_InboxList> {
  bool _showCreate = false;

  /// Called by parent via GlobalKey to open the inline create row.
  void openCreate() {
    widget.onActivated();
    setState(() => _showCreate = true);
  }

  List<_TaskRef> _inboxTasks(ProjectsViewModel vm) {
    final refs = <_TaskRef>[];
    for (final project in vm.projects) {
      for (final task in project.tasks) {
        if (task.dueDate == null && !task.isDone) {
          refs.add(_TaskRef(task: task, project: project));
        }
      }
    }
    // Sort: in_progress first, then by createdAt desc (newest first)
    refs.sort((a, b) {
      if (a.task.status == 'in_progress' && b.task.status != 'in_progress') {
        return -1;
      }
      if (b.task.status == 'in_progress' && a.task.status != 'in_progress') {
        return 1;
      }
      return b.task.createdAt.compareTo(a.task.createdAt);
    });
    return refs;
  }

  void _createTask(BuildContext context, String title) {
    final vm = context.read<ProjectsViewModel>();
    if (vm.projects.isEmpty) return;
    final project = vm.projects.first;
    vm.addTask(project, title: title, priority: 'medium', dueDate: null);
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<ProjectsViewModel>();
    final tasks = _inboxTasks(vm);

    return GestureDetector(
      onTap: widget.onActivated,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.inbox_outlined,
            label: 'INBOX',
            count: tasks.length,
          ),
          const SizedBox(height: SpaceTokens.s12),
          Divider(height: 1, thickness: 1, color: c.border),

          if (tasks.isEmpty && !_showCreate)
            _GhostCreate(
              label: 'Capture a thought',
              onTap: () {
                widget.onActivated();
                setState(() => _showCreate = true);
              },
            )
          else
            ...tasks.map((ref) => _TaskRow(taskRef: ref)),

          AnimatedSize(
            duration: MotionTokens.duration,
            curve: MotionTokens.curve,
            child: _showCreate
                ? Column(
                    children: [
                      _InlineCreate(
                        hintText: 'Task title',
                        onCommit: (title) => _createTask(context, title),
                        onCancel: () => setState(() => _showCreate = false),
                      ),
                      Divider(height: 1, thickness: 1, color: c.border),
                    ],
                  )
                : tasks.isNotEmpty
                    ? _GhostCreate(
                        label: 'Add task',
                        onTap: () {
                          widget.onActivated();
                          setState(() => _showCreate = true);
                        },
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UPCOMING LIST
// ---------------------------------------------------------------------------

class _UpcomingList extends StatefulWidget {
  const _UpcomingList({super.key, required this.onActivated});
  final VoidCallback onActivated;

  @override
  State<_UpcomingList> createState() => _UpcomingListState();
}

class _UpcomingListState extends State<_UpcomingList> {
  bool _showCreate = false;

  /// Called by parent via GlobalKey to open the inline create row.
  void openCreate() {
    widget.onActivated();
    setState(() => _showCreate = true);
  }

  /// Groups future tasks by date (day bucket).
  Map<DateTime, List<_TaskRef>> _upcomingByDate(ProjectsViewModel vm) {
    final map = <DateTime, List<_TaskRef>>{};
    for (final project in vm.projects) {
      for (final task in project.tasks) {
        if (task.dueDate != null && _isFuture(task.dueDate!) && !task.isDone) {
          final bucket = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          map.putIfAbsent(bucket, () => []).add(
            _TaskRef(task: task, project: project),
          );
        }
      }
    }
    // Sort tasks within each bucket by time
    for (final list in map.values) {
      list.sort((a, b) {
        final ta = a.task.dueDate ?? DateTime(9999);
        final tb = b.task.dueDate ?? DateTime(9999);
        return ta.compareTo(tb);
      });
    }
    return map;
  }

  void _createTask(BuildContext context, String title) async {
    final vm = context.read<ProjectsViewModel>();
    if (vm.projects.isEmpty) return;
    final project = vm.projects.first;
    // Default to tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    await vm.addTask(project, title: title, priority: 'medium', dueDate: dueDate);
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<ProjectsViewModel>();
    final byDate = _upcomingByDate(vm);
    final sortedDates = byDate.keys.toList()..sort();
    final totalCount = byDate.values.fold<int>(0, (sum, list) => sum + list.length);

    return GestureDetector(
      onTap: widget.onActivated,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.event_outlined,
            label: 'UPCOMING',
            count: totalCount,
          ),
          const SizedBox(height: SpaceTokens.s12),
          Divider(height: 1, thickness: 1, color: c.border),

          if (byDate.isEmpty && !_showCreate) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s12),
              child: Text(
                'Nothing scheduled.',
                style:
                    TextStyles.bodyMd(context).copyWith(color: c.textDisabled),
              ),
            ),
            _GhostCreate(
              label: 'Add task',
              onTap: () {
                widget.onActivated();
                setState(() => _showCreate = true);
              },
            ),
          ] else ...[
            for (final date in sortedDates) ...[
              // Date divider
              Padding(
                padding: const EdgeInsets.only(
                  top: SpaceTokens.s12,
                  bottom: SpaceTokens.s4,
                ),
                child: Text(
                  _formatDateDivider(date),
                  style: TextStyles.bodySm(context).copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ...byDate[date]!.map((ref) => _TaskRow(taskRef: ref)),
            ],
          ],

          AnimatedSize(
            duration: MotionTokens.duration,
            curve: MotionTokens.curve,
            child: _showCreate
                ? Column(
                    children: [
                      _InlineCreate(
                        hintText: 'Task title — defaults to tomorrow',
                        onCommit: (title) => _createTask(context, title),
                        onCancel: () => setState(() => _showCreate = false),
                      ),
                      Divider(height: 1, thickness: 1, color: c.border),
                    ],
                  )
                : byDate.isNotEmpty
                    ? _GhostCreate(
                        label: 'Add task',
                        onTap: () {
                          widget.onActivated();
                          setState(() => _showCreate = true);
                        },
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
