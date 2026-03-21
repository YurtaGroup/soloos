import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../widgets/common_widgets.dart';
import '../core/utils/stats_calculator.dart';
import '../features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'projects_screen.dart';
import 'habits_screen.dart';
import '../features/finance/presentation/screens/finance_dashboard_screen.dart';
import '../features/family/presentation/screens/family_dashboard_screen.dart';
import '../features/gamification/presentation/screens/gamification_dashboard_screen.dart';
import 'ideas_screen.dart';
import 'standup_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = StorageService();
  int _currentIndex = 0;

  static const List<Widget> _staticScreens = [
    ProjectsScreen(),
    HabitsScreen(),
    FinanceDashboardScreen(),
    IdeasScreen(),
    FamilyDashboardScreen(),
    GamificationDashboardScreen(),
  ];

  void _navigate(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final homeTab = _HomeTab(
      storage: _storage,
      digest: vm.digest,
      digestLoading: vm.digestLoading,
      onRefreshDigest: vm.refresh,
      onNavigate: _navigate,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [homeTab, ..._staticScreens],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final StorageService storage;
  final String digest;
  final bool digestLoading;
  final VoidCallback onRefreshDigest;
  final Function(int) onNavigate;

  const _HomeTab({
    required this.storage,
    required this.digest,
    required this.digestLoading,
    required this.onRefreshDigest,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = ls.t('good_morning');
    } else if (hour < 17) {
      greeting = ls.t('good_afternoon');
    } else {
      greeting = ls.t('good_evening');
    }

    final stats = StatsCalculator.calculate(
      projects: storage.getProjects(),
      habits: storage.getHabits(),
      transactions: storage.getTransactions(),
      ideas: storage.getIdeas(),
      contacts: storage.getContacts(),
    );
    final openTasks = stats.openTasks;
    final habitStreak = stats.habitStreak;
    final habitsToday = stats.habitsToday;
    final habits = storage.getHabits();
    final balance = stats.balance;
    final upcomingBdays = stats.upcomingBirthdays;
    final ideas = stats.activeIdeas;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${storage.userName.isEmpty ? 'Chief' : storage.userName} 👋',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── AI Daily Digest ──────────────────────────────────
              _DigestCard(
                digest: digest,
                loading: digestLoading,
                onRefresh: onRefreshDigest,
                hasApiKey: storage.apiKey.isNotEmpty,
              ),
              const SizedBox(height: 16),

              // ── Quick Stats ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _QuickStatCard(
                      label: ls.t('open_tasks'),
                      value: openTasks.toString(),
                      icon: Icons.check_box_outlined,
                      color: AppColors.workColor,
                      onTap: () => onNavigate(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickStatCard(
                      label: ls.t('habit_streak'),
                      value: '${habitStreak}d',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.healthColor,
                      onTap: () => onNavigate(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickStatCard(
                      label: ls.t('balance'),
                      value: '\$${balance.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.financeColor,
                      onTap: () => onNavigate(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Today's Habits ───────────────────────────────────
              if (habits.isNotEmpty) ...[
                SectionCard(
                  child: Column(
                    children: [
                      ModuleHeader(
                        title: ls.t('todays_habits'),
                        color: AppColors.healthColor,
                        icon: Icons.spa_outlined,
                        onAction: () => onNavigate(2),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '$habitsToday/${habits.length}',
                            style: TextStyle(
                              color: habitsToday == habits.length
                                  ? AppColors.healthColor
                                  : AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ls.t('completed'),
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          if (habitsToday == habits.length)
                            Text(ls.t('perfect_day'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: habits.isEmpty ? 0 : habitsToday / habits.length,
                          backgroundColor: AppColors.healthColor.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation(AppColors.healthColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Active Ideas ─────────────────────────────────────
              SectionCard(
                onTap: () => onNavigate(4),
                child: Column(
                  children: [
                    ModuleHeader(
                      title: ls.t('active_ideas'),
                      color: AppColors.ideasColor,
                      icon: Icons.lightbulb_outline_rounded,
                      onAction: () => onNavigate(4),
                      actionLabel: '+ Add',
                    ),
                    const SizedBox(height: 12),
                    if (ideas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          ls.t('no_active_ideas'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      )
                    else
                      ...ideas.map((idea) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.ideasColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    idea.title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          )),
                    Row(
                      children: List.generate(3, (i) {
                        final filled = i < ideas.length;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i < 2 ? 6 : 0, top: 8),
                            height: 3,
                            decoration: BoxDecoration(
                              color: filled
                                  ? AppColors.ideasColor
                                  : AppColors.ideasColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ls.t('idea_slots_used', {'n': ideas.length.toString()}),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Daily Standup ────────────────────────────────────
              GradientCard(
                colors: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StandupScreen()),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ls.t('daily_ai_standup'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ls.t('standup_subtitle'),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Upcoming Birthdays ───────────────────────────────
              if (upcomingBdays.isNotEmpty) ...[
                SectionCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactsScreen()),
                  ),
                  child: Column(
                    children: [
                      ModuleHeader(
                        title: ls.t('upcoming_birthdays'),
                        color: AppColors.accentRed,
                        icon: Icons.cake_outlined,
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContactsScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...upcomingBdays.take(3).map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(c.emoji, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.daysUntilBirthday == 0
                                        ? AppColors.accentRed.withOpacity(0.2)
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.daysUntilBirthday == 0
                                        ? ls.t('today_birthday')
                                        : 'in ${c.daysUntilBirthday}d',
                                    style: TextStyle(
                                      color: c.daysUntilBirthday == 0
                                          ? AppColors.accentRed
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _DigestCard extends StatelessWidget {
  final String digest;
  final bool loading;
  final VoidCallback onRefresh;
  final bool hasApiKey;

  const _DigestCard({
    required this.digest,
    required this.loading,
    required this.onRefresh,
    required this.hasApiKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF1C1917)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  ls.t('ai_daily_digest'),
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!loading)
                  GestureDetector(
                    onTap: hasApiKey ? onRefresh : null,
                    child: Icon(
                      Icons.refresh_rounded,
                      color: hasApiKey ? AppColors.primaryLight : AppColors.textMuted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: loading
                ? AiThinkingWidget(message: ls.t('analyzing_day'))
                : !hasApiKey
                    ? Text(
                        ls.t('add_api_key'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      )
                    : digest.isEmpty
                        ? GestureDetector(
                            onTap: onRefresh,
                            child: Text(
                              ls.t('tap_to_generate'),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          )
                        : Text(
                            digest,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, ls.t('nav_home')),
      (Icons.work_rounded, Icons.work_outline_rounded, ls.t('nav_work')),
      (Icons.spa_rounded, Icons.spa_outlined, ls.t('nav_health')),
      (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, ls.t('nav_finance')),
      (Icons.lightbulb_rounded, Icons.lightbulb_outline_rounded, ls.t('nav_ideas')),
      (Icons.favorite_rounded, Icons.favorite_border_rounded, ls.t('nav_family')),
      (Icons.bolt_rounded, Icons.bolt_outlined, ls.t('nav_progress')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.textMuted.withOpacity(0.15)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.$1 : item.$2,
                          color: selected ? AppColors.primary : AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
