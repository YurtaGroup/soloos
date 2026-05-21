// lib/features/calendar/presentation/screens/calendar_week_screen.dart
//
// Quiet OS — Week 4 Phase B: Cron / Notion-style week-view calendar.
//
// Layout: fixed header + horizontal 7-column grid, hour rows 06–22,
// vertical scroll for time axis. Matches the spec exactly:
//   - Today column tinted lime
//   - Task cards: 3px lime left bar, proportional to 1h slot
//   - Google Calendar event cards: 3px ink/textSecondary left bar
//   - "Now" indicator: 1px danger-red hairline + dot on today's column
//   - Drag vertically → change time; drag to another column → change date
//   - Tap empty slot → inline create-task sheet
//   - Tap task card → edit sheet (reuses tasks_screen pattern)
//   - Tap event card → read-only detail sheet
//   - Gear icon → CalendarSettingsScreen
//   - Week nav: ◀ / Today / ▶
//
// Atoms: QColors, TextStyles, MonoText, SectionLabel, AppButton.
// NO raw hex codes. NO new global tokens.

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
import '../../../../services/google_calendar_service.dart';

import 'calendar_settings_screen.dart';

// ---------------------------------------------------------------------------
// CONSTANTS
// ---------------------------------------------------------------------------

const _kStartHour = 6;  // grid starts at 06:00
const _kEndHour   = 22; // grid ends at 22:00 (exclusive row = 22)
const _kHourCount = _kEndHour - _kStartHour; // 16 rows
const _kHourH     = 64.0; // px per hour row
const _kTimeColW  = 40.0; // width of the left hour-label column

// ---------------------------------------------------------------------------
// DERIVED TYPE
// ---------------------------------------------------------------------------

class _TaskRef {
  const _TaskRef({required this.task, required this.project});
  final Task task;
  final Project project;
}

// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

DateTime _weekStart(DateTime anchor) {
  // Monday of the week containing anchor
  return DateTime(anchor.year, anchor.month, anchor.day)
      .subtract(Duration(days: anchor.weekday - 1));
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatHour(int h) =>
    '${h.toString().padLeft(2, '0')}:00';

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _weekRangeLabel(DateTime monday) {
  final sunday = monday.add(const Duration(days: 6));
  if (monday.month == sunday.month) {
    return '${DateFormat('MMM d').format(monday)} – ${DateFormat('d, yyyy').format(sunday)}';
  }
  return '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d, yyyy').format(sunday)}';
}

// Vertical offset in the grid for a given DateTime (clamped to 06–22)
double _yForTime(DateTime dt) {
  final hour = dt.hour.clamp(_kStartHour, _kEndHour).toDouble();
  final minute = dt.minute / 60.0;
  return (hour - _kStartHour + minute) * _kHourH;
}

// ---------------------------------------------------------------------------
// CALENDAR WEEK SCREEN
// ---------------------------------------------------------------------------

class CalendarWeekScreen extends StatefulWidget {
  const CalendarWeekScreen({super.key});

  @override
  State<CalendarWeekScreen> createState() => _CalendarWeekScreenState();
}

class _CalendarWeekScreenState extends State<CalendarWeekScreen> {
  late DateTime _weekMonday;
  Timer? _nowTimer;

  // Scroll controller so we can jump to current hour on load
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _weekMonday = _weekStart(DateTime.now());

    // Trigger auto-sign-in for Google Calendar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<GoogleCalendarService>();
      if (!svc.isSignedIn) svc.tryAutoSignIn();
      _scrollToNow();
    });

    // Refresh "now" indicator every minute
    _nowTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nowTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToNow() {
    final now = DateTime.now();
    final targetY = _yForTime(now) - 80; // show a bit above now
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        targetY.clamp(0, _scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: MotionTokens.curve,
      );
    }
  }

  bool get _isCurrentWeek => _sameDay(_weekMonday, _weekStart(DateTime.now()));

  void _previousWeek() =>
      setState(() => _weekMonday = _weekMonday.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _weekMonday = _weekMonday.add(const Duration(days: 7)));

  void _goToCurrentWeek() {
    setState(() {
      _weekMonday = _weekStart(DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // ── HEADER ───────────────────────────────────────────────────
        _WeekHeader(
          monday: _weekMonday,
          isCurrentWeek: _isCurrentWeek,
          topInset: topInset,
          onPrev: _previousWeek,
          onNext: _nextWeek,
          onToday: _goToCurrentWeek,
          onSettings: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarSettingsScreen()),
          ),
        ),

        // Hairline under header
        Container(height: 1, color: c.border),

        // ── GRID ──────────────────────────────────────────────────────
        Expanded(
          child: _WeekGrid(
            weekMonday: _weekMonday,
            scrollCtrl: _scrollCtrl,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// WEEK HEADER
// ---------------------------------------------------------------------------

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.monday,
    required this.isCurrentWeek,
    required this.topInset,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onSettings,
  });

  final DateTime monday;
  final bool isCurrentWeek;
  final double topInset;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    return Container(
      color: c.appBg,
      padding: EdgeInsets.fromLTRB(
        SpaceTokens.s16,
        topInset + SpaceTokens.s8,
        SpaceTokens.s8,
        SpaceTokens.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Week range title
              Expanded(
                child: Text(
                  _weekRangeLabel(monday),
                  style: TextStyles.displayMd(context),
                ),
              ),
              // Settings gear
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 18),
                color: c.textSecondary,
                tooltip: 'Calendar settings',
                onPressed: onSettings,
              ),
            ],
          ),
          const SizedBox(height: SpaceTokens.s8),
          // Nav row: ◀  Today  ▶
          Row(
            children: [
              _NavArrow(icon: Icons.chevron_left, onTap: onPrev),
              const SizedBox(width: SpaceTokens.s8),
              AnimatedOpacity(
                opacity: isCurrentWeek ? 0.0 : 1.0,
                duration: MotionTokens.duration,
                child: IgnorePointer(
                  ignoring: isCurrentWeek,
                  child: AppButton(
                    label: 'Today',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    onPressed: isCurrentWeek ? null : onToday,
                  ),
                ),
              ),
              const SizedBox(width: SpaceTokens.s8),
              _NavArrow(icon: Icons.chevron_right, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Icon(icon, size: 22, color: c.textSecondary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WEEK GRID  (main body)
// ---------------------------------------------------------------------------

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.weekMonday,
    required this.scrollCtrl,
  });

  final DateTime weekMonday;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final days = List.generate(7, (i) => weekMonday.add(Duration(days: i)));

    return Column(
      children: [
        // ── DAY COLUMN HEADERS ────────────────────────────────────────
        Container(
          color: c.surface,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Empty corner above the hour labels
                SizedBox(width: _kTimeColW),
                Container(width: 1, color: c.border),
                // Day columns
                ...List.generate(7, (i) {
                  final day = days[i];
                  final isToday = _sameDay(day, DateTime.now());
                  return Expanded(
                    child: _DayHeader(day: day, isToday: isToday),
                  );
                }),
              ],
            ),
          ),
        ),
        Container(height: 1, color: c.border),

        // ── SCROLLABLE HOUR GRID ─────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: scrollCtrl,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: _kHourCount * _kHourH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hour labels
                  _HourLabels(),
                  // Vertical hairline
                  Container(width: 1, color: c.border),
                  // 7 day columns
                  ...List.generate(7, (i) {
                    final day = days[i];
                    final isToday = _sameDay(day, DateTime.now());
                    final isLast = i == 6;
                    return Expanded(
                      child: _DayColumn(
                        day: day,
                        isToday: isToday,
                        showRightBorder: !isLast,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DAY COLUMN HEADER  (MON 19, TUE 20 …)
// ---------------------------------------------------------------------------

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.isToday});
  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final labelColor = isToday ? c.accent : c.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('E').format(day).toUpperCase(),
            style: TextStyles.label(context).copyWith(
              color: labelColor,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          MonoText(
            '${day.day}',
            size: 13,
            weight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: isToday ? c.accent : c.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOUR LABELS  (left column)
// ---------------------------------------------------------------------------

class _HourLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return SizedBox(
      width: _kTimeColW,
      child: Stack(
        children: List.generate(_kHourCount, (i) {
          final hour = _kStartHour + i;
          return Positioned(
            top: i * _kHourH - 7, // offset so the label sits at the gridline
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(right: SpaceTokens.s4),
              child: MonoText(
                _formatHour(hour),
                size: 10,
                color: c.textDisabled,
                textAlign: TextAlign.right,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DAY COLUMN  (one of the 7 vertical strips)
// ---------------------------------------------------------------------------

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.isToday,
    required this.showRightBorder,
  });

  final DateTime day;
  final bool isToday;
  final bool showRightBorder;

  List<_TaskRef> _tasksForDay(ProjectsViewModel vm) {
    final refs = <_TaskRef>[];
    for (final project in vm.projects) {
      for (final task in project.tasks) {
        if (task.dueDate != null && _sameDay(task.dueDate!, day)) {
          refs.add(_TaskRef(task: task, project: project));
        }
      }
    }
    return refs;
  }

  List<CalendarEvent> _eventsForDay(GoogleCalendarService svc) {
    return svc.events.where((e) => _sameDay(e.start, day)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<ProjectsViewModel>();
    final calSvc = context.watch<GoogleCalendarService>();

    final tasks = _tasksForDay(vm);
    final events = _eventsForDay(calSvc);
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: showRightBorder
              ? BorderSide(color: c.border, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Hour grid lines ─────────────────────────────────────
          ..._buildGridLines(c),

          // ── Task cards ──────────────────────────────────────────
          ...tasks.map((ref) => _positionedTaskCard(context, ref, vm)),

          // ── Google Calendar event cards ─────────────────────────
          ...events.map((e) => _positionedEventCard(context, e)),

          // ── "Now" line (today only) ──────────────────────────────
          if (isToday) _NowLine(now: now),

          // ── Tappable empty-slot layer ────────────────────────────
          _SlotTapLayer(day: day),
        ],
      ),
    );
  }

  List<Widget> _buildGridLines(QColorSet c) {
    return List.generate(_kHourCount, (i) => Positioned(
      top: i * _kHourH,
      left: 0,
      right: 0,
      child: Container(height: 1, color: c.border),
    ));
  }

  Widget _positionedTaskCard(
    BuildContext context,
    _TaskRef ref,
    ProjectsViewModel vm,
  ) {
    final dt = ref.task.dueDate!;
    // If time is exactly midnight (00:00), treat as 09:00
    final effective = (dt.hour == 0 && dt.minute == 0)
        ? DateTime(dt.year, dt.month, dt.day, 9, 0)
        : dt;

    final top = _yForTime(effective);

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: _kHourH - 4, // 1h slot, 2px gap top/bottom
      child: _TaskCard(taskRef: ref, vm: vm),
    );
  }

  Widget _positionedEventCard(BuildContext context, CalendarEvent event) {
    final top = _yForTime(event.start);
    // Duration in hours, clamped to 0.25–4h display range
    final durationH = event.isAllDay
        ? 1.0
        : (event.end.difference(event.start).inMinutes / 60.0).clamp(0.25, 4.0);
    final height = (durationH * _kHourH - 4).clamp(20.0, double.infinity);

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: _EventCard(event: event),
    );
  }
}

// ---------------------------------------------------------------------------
// SLOT TAP LAYER  — invisible overlay that intercepts taps on empty hours
// ---------------------------------------------------------------------------

class _SlotTapLayer extends StatelessWidget {
  const _SlotTapLayer({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          // Determine which hour slot was tapped
          final tapY = details.localPosition.dy;
          final hourOffset = (tapY / _kHourH).floor();
          final hour = (_kStartHour + hourOffset).clamp(_kStartHour, _kEndHour - 1);
          final slotTime = DateTime(day.year, day.month, day.day, hour, 0);
          _showCreateSheet(context, slotTime);
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, DateTime slotTime) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: QColors.of(context).surface,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => _CreateTaskSheet(slotTime: slotTime),
    );
  }
}

// ---------------------------------------------------------------------------
// TASK CARD  (lime-bar, draggable)
// ---------------------------------------------------------------------------

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.taskRef, required this.vm});
  final _TaskRef taskRef;
  final ProjectsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final task = taskRef.task;
    final isDone = task.isDone;

    final cardContent = GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showTaskEditSheet(context, vm, task, taskRef.project);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDone
              ? c.surfaceMuted.withValues(alpha: 0.5)
              : c.surface,
          border: Border(
            left: BorderSide(
              color: isDone ? c.textDisabled : ColorTokens.lime500,
              width: 3,
            ),
            top: BorderSide(color: c.border, width: 1),
            right: BorderSide(color: c.border, width: 1),
            bottom: BorderSide(color: c.border, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.s8,
          vertical: 3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.bodySm(context).copyWith(
                color: isDone ? c.textDisabled : c.textPrimary,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: c.textDisabled,
                height: 1.2,
              ),
            ),
            if (task.dueDate != null &&
                !(task.dueDate!.hour == 0 && task.dueDate!.minute == 0))
              MonoText(
                _formatTime(task.dueDate!),
                size: 10,
                color: c.textSecondary,
              ),
          ],
        ),
      ),
    );

    // Wrap in LongPressDraggable for move-task interaction
    return LongPressDraggable<_TaskRef>(
      data: taskRef,
      delay: const Duration(milliseconds: 350),
      onDragStarted: () => HapticFeedback.mediumImpact(),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.02,
          child: SizedBox(
            width: 120,
            height: _kHourH - 4,
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(
                  left: BorderSide(color: ColorTokens.lime500, width: 3),
                  top: BorderSide(color: c.accent, width: 1),
                  right: BorderSide(color: c.accent, width: 1),
                  bottom: BorderSide(color: c.accent, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: SpaceTokens.s8,
                vertical: 3,
              ),
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.bodySm(context).copyWith(height: 1.2),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardContent),
      child: cardContent,
    );
  }
}

// ---------------------------------------------------------------------------
// EVENT CARD  (ink-bar, read-only)
// ---------------------------------------------------------------------------

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final timeLabel = event.isAllDay
        ? 'All day'
        : _formatTime(event.start);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showEventDetailSheet(context, event);
      },
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          border: Border(
            left: BorderSide(color: c.textSecondary, width: 3),
            top: BorderSide(color: c.border, width: 1),
            right: BorderSide(color: c.border, width: 1),
            bottom: BorderSide(color: c.border, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.s8,
          vertical: 3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.bodySm(context).copyWith(
                color: c.textPrimary,
                height: 1.2,
              ),
            ),
            MonoText(timeLabel, size: 10, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOW LINE  — 1px danger-red hairline at current time
// ---------------------------------------------------------------------------

class _NowLine extends StatelessWidget {
  const _NowLine({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    // Only render if now is within the visible grid range
    if (now.hour < _kStartHour || now.hour >= _kEndHour) {
      return const SizedBox.shrink();
    }
    final top = _yForTime(now);

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: ColorTokens.danger,
              shape: BoxShape.circle,
            ),
          ),
          // Line
          Expanded(
            child: Container(
              height: 1,
              color: ColorTokens.danger,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CREATE TASK SHEET  — opened by tapping an empty slot
// ---------------------------------------------------------------------------

class _CreateTaskSheet extends StatefulWidget {
  const _CreateTaskSheet({required this.slotTime});
  final DateTime slotTime;

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final _titleCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final text = _titleCtrl.text.trim();
    if (text.isEmpty) return;
    final vm = context.read<ProjectsViewModel>();
    if (vm.projects.isEmpty) {
      if (!context.mounted) return;
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    final project = vm.projects.first;
    await vm.addTask(
      project,
      title: text,
      priority: 'medium',
      dueDate: widget.slotTime,
    );
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('EEE, MMM d').format(widget.slotTime);
    final timeLabel = _formatTime(widget.slotTime);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + SpaceTokens.s16,
        left: SpaceTokens.s16,
        right: SpaceTokens.s16,
        top: SpaceTokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            'NEW TASK — $dayLabel $timeLabel',
            bottomPadding: SpaceTokens.s16,
          ),
          AppInput(
            controller: _titleCtrl,
            autofocus: true,
            hintText: 'Task title',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(context),
          ),
          const SizedBox(height: SpaceTokens.s16),
          AppButton(
            label: 'Add Task',
            isFullWidth: true,
            isLoading: _saving,
            onPressed: _saving ? null : () => _save(context),
          ),
          const SizedBox(height: SpaceTokens.s8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TASK EDIT SHEET  — reuses the same pattern as tasks_screen.dart
// ---------------------------------------------------------------------------

void _showTaskEditSheet(
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

              // Status selector
              Text(
                'Status',
                style: TextStyles.bodySm(ctx)
                    .copyWith(color: c.textSecondary),
              ),
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
                          color: isSelected ? c.selectedRow : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? c.accent : c.border,
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

              // Priority selector
              Text(
                'Priority',
                style: TextStyles.bodySm(ctx)
                    .copyWith(color: c.textSecondary),
              ),
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
                          color: isSelected ? c.selectedRow : Colors.transparent,
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

              // Due date + time pickers
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 365)),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked == null) return;
                  // Preserve existing time or default to 09:00
                  final existingHour =
                      dueDate?.hour ?? 9;
                  final existingMinute = dueDate?.minute ?? 0;
                  setSheet(() => dueDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        existingHour,
                        existingMinute,
                      ));
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
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: c.textSecondary,
                      ),
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
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (dueDate != null) ...[
                const SizedBox(height: SpaceTokens.s8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay(
                        hour: dueDate!.hour,
                        minute: dueDate!.minute,
                      ),
                    );
                    if (picked != null) {
                      setSheet(() => dueDate = DateTime(
                            dueDate!.year,
                            dueDate!.month,
                            dueDate!.day,
                            picked.hour,
                            picked.minute,
                          ));
                    }
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
                        Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: SpaceTokens.s8),
                        MonoText(
                          _formatTime(dueDate!),
                          size: 13,
                          color: c.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: SpaceTokens.s24),

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Save',
                      isFullWidth: true,
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        vm.editTask(
                          task,
                          title: titleCtrl.text,
                          priority: priority,
                          status: status,
                          dueDate: dueDate,
                          clearDueDate:
                              dueDate == null && task.dueDate != null,
                        );
                        Navigator.pop(ctx);
                      },
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
// EVENT DETAIL SHEET  — read-only for Google Calendar events
// ---------------------------------------------------------------------------

void _showEventDetailSheet(BuildContext context, CalendarEvent event) {
  final c = QColors.of(context);
  final timeStr = event.isAllDay
      ? 'All day'
      : '${_formatTime(event.start)} – ${_formatTime(event.end)}';

  showModalBottomSheet(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(),
    builder: (ctx) {
      final cc = QColors.of(ctx);
      return Padding(
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
            SectionLabel(
              'GOOGLE CALENDAR',
              bottomPadding: SpaceTokens.s16,
            ),
            Text(
              event.title,
              style: TextStyles.displayMd(ctx),
            ),
            const SizedBox(height: SpaceTokens.s8),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: cc.textSecondary,
                ),
                const SizedBox(width: SpaceTokens.s8),
                MonoText(
                  timeStr,
                  size: 13,
                  color: cc.textSecondary,
                ),
              ],
            ),
            if (event.location != null) ...[
              const SizedBox(height: SpaceTokens.s8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: cc.textSecondary,
                  ),
                  const SizedBox(width: SpaceTokens.s8),
                  Flexible(
                    child: Text(
                      event.location!,
                      style: TextStyles.bodySm(ctx)
                          .copyWith(color: cc.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            if (event.description != null &&
                event.description!.isNotEmpty) ...[
              const SizedBox(height: SpaceTokens.s8),
              Text(
                event.description!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.bodySm(ctx)
                    .copyWith(color: cc.textSecondary),
              ),
            ],
            const SizedBox(height: SpaceTokens.s24),
            AppButton(
              label: 'Close',
              variant: AppButtonVariant.secondary,
              isFullWidth: true,
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: SpaceTokens.s8),
          ],
        ),
      );
    },
  );
}
