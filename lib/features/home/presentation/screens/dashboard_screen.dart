// lib/features/home/presentation/screens/dashboard_screen.dart
//
// Quiet OS — Week 2 Dashboard Rebuild.
//
// Navigation choice: Option B — 5 tabs.
//   0: Home (Dashboard)
//   1: Tasks  → WorkHubScreen
//   2: CRM    → ContactsScreen
//   3: Calendar → CalendarScreen
//   4: Money  → FinanceDashboardScreen
//
// Rationale for B: Dashboard is the primary surface. Burying it behind a
// separate route (Option A) creates a discoverability cliff on first launch.
// With 5 items the nav is still scannable on a 393pt iPhone; each item
// has a clear, distinct label. Tap-to-home from any tab costs one tap.
//
// Demoted modules (Health, Ideas, Family, Circles, Gamification, Admin)
// live in a "MORE" section at the bottom of the Dashboard tab. Their
// screens are fully intact — just no longer in the top-level nav.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/app_row.dart';
import '../../../../theme/atoms/app_card.dart';
import '../../../../theme/atoms/app_button.dart';
import '../../../../theme/atoms/mono_text.dart';

import '../../../../services/storage_service.dart';

import '../../../work/presentation/viewmodels/projects_view_model.dart';
import '../../../work/domain/models/task.dart';
import '../../../family/presentation/viewmodels/contacts_view_model.dart';
import '../../../family/domain/models/contact.dart';
import '../../../finance/presentation/viewmodels/finance_view_model.dart';

// Nav-destination screens (internals untouched)
import 'work_hub_screen.dart';
import '../../../family/presentation/screens/contacts_screen.dart';
import '../../../settings/presentation/screens/calendar_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../finance/presentation/screens/finance_dashboard_screen.dart';

// Demoted module screens (reachable from MORE section)
import '../../../health/presentation/screens/habits_screen.dart';
import '../../../ideas/presentation/screens/ideas_screen.dart';
import '../../../family/presentation/screens/family_dashboard_screen.dart';
import '../../../circles/presentation/screens/circles_screen.dart';
import '../../../gamification/presentation/screens/gamification_dashboard_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';

// ---------------------------------------------------------------------------
// ROOT — DashboardScreen
// ---------------------------------------------------------------------------

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Static screens for tabs 1-4. Dashboard (tab 0) is built inline.
  static const _tabScreens = <Widget>[
    WorkHubScreen(),
    ContactsScreen(),
    CalendarScreen(),
    FinanceDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeDashboard(onNavigate: (i) => setState(() => _currentIndex = i)),
          ..._tabScreens,
        ],
      ),
      bottomNavigationBar: _QuietNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BOTTOM NAV — Material 3 NavigationBar, 5 items
// ---------------------------------------------------------------------------

class _QuietNav extends StatelessWidget {
  const _QuietNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake_rounded),
            label: 'CRM',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Money',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME DASHBOARD — single scrollable column
// ---------------------------------------------------------------------------

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _DashboardAppBar(storage: storage),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            SpaceTokens.s16, SpaceTokens.s24,
            SpaceTokens.s16, SpaceTokens.s48,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── TODAY ──────────────────────────────────────────
              _TodaySection(),
              const SizedBox(height: SpaceTokens.s32),

              // ── PIPELINE ────────────────────────────────────────
              _PipelineSection(onNavigate: onNavigate),
              const SizedBox(height: SpaceTokens.s32),

              // ── PULSE ───────────────────────────────────────────
              _PulseSection(),
              const SizedBox(height: SpaceTokens.s32),

              // ── MORE ────────────────────────────────────────────
              _MoreSection(),
            ]),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// APP BAR
// ---------------------------------------------------------------------------

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({required this.storage});

  final StorageService storage;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateString =>
      DateFormat('EEEE, MMMM d').format(DateTime.now());

  String get _firstName {
    final name = storage.userName.trim();
    if (name.isEmpty) return 'Timur';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    final topInset = MediaQuery.of(context).padding.top;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SpaceTokens.s16,
          topInset + SpaceTokens.s8,
          SpaceTokens.s8,
          SpaceTokens.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dateString,
                    style: TextStyles.bodyLg(context).copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
                _NavIconButton(
                  icon: Icons.terminal_outlined,
                  tooltip: 'Command palette',
                  onTap: () {/* placeholder — Week 3 */},
                ),
                _NavIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: 'Settings',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$_greeting, $_firstName.',
              style: TextStyles.displayLg(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return IconButton(
      icon: Icon(icon, size: 20),
      color: c.textSecondary,
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// TODAY SECTION
// ---------------------------------------------------------------------------

class _TodaySection extends StatelessWidget {
  const _TodaySection();

  /// Gather today's tasks: all incomplete + completed tasks due today.
  List<Task> _todayTasks(List<Task> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Tasks either due today or with no due date that are not done
    // (show all non-done + done ones from today).
    final result = allTasks.where((t) {
      if (t.dueDate != null) {
        final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return due == today;
      }
      // Tasks with no due date: show if not done or created today
      if (!t.isDone) return true;
      final created = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
      return created == today;
    }).toList();

    // Sort: in_progress first, then todo, then done
    result.sort((a, b) {
      int rank(Task t) {
        if (t.status == 'in_progress') return 0;
        if (!t.isDone) return 1;
        return 2;
      }
      return rank(a).compareTo(rank(b));
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<ProjectsViewModel>();

    // Flatten all tasks across all projects
    final allTasks = vm.projects.expand((p) => p.tasks).toList();
    final tasks = _todayTasks(allTasks);
    final doneCount = tasks.where((t) => t.isDone).length;
    final totalCount = tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel('Today', bottomPadding: 0),
            const Spacer(),
            if (totalCount > 0)
              MonoText(
                '$doneCount of $totalCount',
                size: 12,
                color: c.textSecondary,
              ),
          ],
        ),
        const SizedBox(height: SpaceTokens.s12),

        // Hairline separator
        Divider(height: 1, thickness: 1, color: c.border),

        if (tasks.isEmpty)
          _GhostRow(label: 'Plan your day')
        else ...[
          ...tasks.map((task) => _TodayTaskRow(task: task)),
          // Inline create row
          _GhostRow(label: 'Add task'),
        ],
      ],
    );
  }
}

class _TodayTaskRow extends StatelessWidget {
  const _TodayTaskRow({required this.task});

  final Task task;

  String _timeLabel() {
    if (task.dueDate == null) return task.isDone ? 'done' : '';
    final d = task.dueDate!;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final isDone = task.isDone;
    final isInProgress = task.status == 'in_progress';

    // Status dot
    Widget leadingDot;
    if (isDone) {
      leadingDot = Icon(Icons.check_circle_rounded, size: 16, color: c.success);
    } else if (isInProgress) {
      leadingDot = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: c.accent,
          shape: BoxShape.circle,
        ),
      );
    } else {
      leadingDot = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.border, width: 1.5),
        ),
      );
    }

    final timeLabel = _timeLabel();

    return AppRow(
      title: task.title,
      leading: SizedBox(width: 16, child: Center(child: leadingDot)),
      trailing: timeLabel.isNotEmpty
          ? MonoText(
              timeLabel,
              size: 14,
              color: isDone ? c.textDisabled : c.textSecondary,
            )
          : null,
      showDivider: true,
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: SpaceTokens.s12,
      ),
    );
  }
}

class _GhostRow extends StatelessWidget {
  const _GhostRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return Padding(
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
    );
  }
}

// ---------------------------------------------------------------------------
// PIPELINE SECTION
// ---------------------------------------------------------------------------

class _PipelineSection extends StatelessWidget {
  const _PipelineSection({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final vm = context.watch<ContactsViewModel>();
    final contacts = vm.contacts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel('Pipeline', bottomPadding: 0),
            const Spacer(),
            MonoText(
              contacts.isEmpty ? '0 active' : '${contacts.length} active',
              size: 12,
              color: c.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: SpaceTokens.s12),

        if (contacts.isEmpty)
          AppCard(
            dense: true,
            child: Center(
              child: AppButton(
                label: 'Add your first deal',
                variant: AppButtonVariant.secondary,
                onPressed: () => onNavigate(2), // CRM tab
              ),
            ),
          )
        else
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(width: SpaceTokens.s12),
              itemBuilder: (context, i) => _PipelineCard(contact: contacts[i]),
            ),
          ),
      ],
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.contact});

  final Contact contact;

  String get _stageLabel {
    switch (contact.relationship.toLowerCase()) {
      case 'client':
        return 'CLIENT';
      case 'prospect':
        return 'PROSPECT';
      case 'partner':
        return 'PARTNER';
      case 'investor':
        return 'INVESTOR';
      default:
        return contact.relationship.toUpperCase();
    }
  }

  String get _nextAction {
    final days = contact.daysSinceContact;
    if (days == -1) return 'reach out';
    if (days == 0) return 'contacted today';
    if (days <= 7) return 'follow up';
    return 'overdue ${days}d';
  }

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    return SizedBox(
      width: 168,
      child: AppCard(
        dense: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contact name
            Text(
              contact.name,
              style: TextStyles.bodyLg(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Stage label
            Text(
              _stageLabel,
              style: TextStyles.label(context).copyWith(
                color: c.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),

            // Hairline divider
            Divider(height: 1, thickness: 1, color: c.border),
            const SizedBox(height: SpaceTokens.s8),

            // Next action row
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 12, color: c.accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _nextAction,
                    style: TextStyles.bodySm(context).copyWith(
                      color: c.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PULSE SECTION
// ---------------------------------------------------------------------------

class _PulseSection extends StatelessWidget {
  const _PulseSection();

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    final finVm = context.watch<FinanceViewModel>();
    final projVm = context.watch<ProjectsViewModel>();

    final revenue = finVm.totalMonthlyIncome + finVm.totalOneTimeIncomeThisMonth;
    final expenses = finVm.totalMonthlyExpenses + finVm.totalMonthlyObligations;
    final net = revenue - expenses;

    // Task completion across all projects
    final allTasks = projVm.projects.expand((p) => p.tasks).toList();
    final doneTasks = allTasks.where((t) => t.isDone).length;
    final totalTasks = allTasks.length;

    // Simple sparkline data: 7 fake but plausible relative values
    // sourced from real ratio. Week 4 will wire actual time-series.
    final revenueSparkData = _mockSparkline(revenue);
    final expenseSparkData = _mockSparkline(expenses, seed: 7);

    final hasData = revenue > 0 || expenses > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel('Pulse', bottomPadding: 0),
            const Spacer(),
            Text(
              'this month',
              style: TextStyles.bodySm(context).copyWith(color: c.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: SpaceTokens.s12),
        Divider(height: 1, thickness: 1, color: c.border),

        if (!hasData) ...[
          _PulseRow(
            label: 'Revenue',
            value: r'$0',
            sparkData: null,
            sparkColor: c.accent,
          ),
          _PulseRow(
            label: 'Expenses',
            value: r'$0',
            sparkData: null,
            sparkColor: c.textSecondary,
          ),
          _PulseRow(
            label: 'Net',
            value: r'$0',
            sparkData: null,
            sparkColor: null,
            isLast: true,
          ),
        ] else ...[
          _PulseRow(
            label: 'Revenue',
            value: _fmt(revenue),
            sparkData: revenueSparkData,
            sparkColor: c.accent,
          ),
          _PulseRow(
            label: 'Expenses',
            value: _fmt(expenses),
            sparkData: expenseSparkData,
            sparkColor: c.textSecondary,
          ),
          _PulseRow(
            label: 'Net',
            value: _fmt(net),
            sparkData: null,
            sparkColor: null,
            isLast: false,
          ),
        ],
        _PulseRow(
          label: 'Tasks done',
          value: '$doneTasks / $totalTasks',
          sparkData: null,
          sparkColor: null,
          isLast: true,
          isMono: true,
        ),
      ],
    );
  }

  String _fmt(double amount) {
    final abs = amount.abs();
    final prefix = amount < 0 ? '-\$' : '\$';
    if (abs >= 1000) {
      return '$prefix${(abs / 1000).toStringAsFixed(1)}k';
    }
    return '$prefix${abs.toStringAsFixed(0)}';
  }

  // Mock 7-point sparkline that trends toward the value.
  // Produces a visually plausible shape without fake precision.
  List<double> _mockSparkline(double value, {int seed = 3}) {
    if (value == 0) return List.filled(7, 0.0);
    const steps = 7;
    final result = <double>[];
    for (int i = 0; i < steps; i++) {
      // Simple wave: varies ±30% around value, trending up toward end
      final factor = 0.7 + (i / (steps - 1)) * 0.3 +
          (((i + seed) % 3) - 1) * 0.12;
      result.add((value * factor).clamp(0, double.infinity));
    }
    return result;
  }
}

class _PulseRow extends StatelessWidget {
  const _PulseRow({
    required this.label,
    required this.value,
    required this.sparkData,
    required this.sparkColor,
    this.isLast = false,
    this.isMono = false,
  });

  final String label;
  final String value;
  final List<double>? sparkData;
  final Color? sparkColor;
  final bool isLast;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s12),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  label,
                  style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(width: SpaceTokens.s8),
              MonoText(
                value,
                size: 14,
                weight: FontWeight.w500,
                color: c.textPrimary,
              ),
              const Spacer(),
              if (sparkData != null && sparkColor != null)
                _Sparkline(
                  data: sparkData!,
                  color: sparkColor!,
                ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: c.border),
      ],
    );
  }
}

// Minimal sparkline using CustomPaint — 80×24 points.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 24,
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.every((v) => v == 0)) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * (size.width / (data.length - 1));
      final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.color != color;
}

// ---------------------------------------------------------------------------
// MORE SECTION — demoted modules
// ---------------------------------------------------------------------------

class _MoreSection extends StatelessWidget {
  const _MoreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('More', bottomPadding: SpaceTokens.s12),
        Divider(height: 1, thickness: 1, color: QColors.of(context).border),
        AppRow(
          title: 'Health & Habits',
          leading: const Icon(Icons.spa_outlined, size: 18),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HabitsScreen()),
          ),
        ),
        AppRow(
          title: 'Ideas',
          leading: const Icon(Icons.lightbulb_outline_rounded, size: 18),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IdeasScreen()),
          ),
        ),
        AppRow(
          title: 'Family',
          leading: const Icon(Icons.people_outline_rounded, size: 18),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FamilyDashboardScreen()),
          ),
        ),
        AppRow(
          title: 'Circles',
          leading: const Icon(Icons.bubble_chart_outlined, size: 18),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CirclesScreen()),
          ),
        ),
        AppRow(
          title: 'Gamification',
          leading: const Icon(Icons.bolt_outlined, size: 18),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GamificationDashboardScreen()),
          ),
        ),
        AppRow(
          title: 'Admin',
          leading: const Icon(Icons.admin_panel_settings_outlined, size: 18),
          trailing: const Icon(Icons.chevron_right, size: 18),
          showDivider: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          ),
        ),
      ],
    );
  }
}
