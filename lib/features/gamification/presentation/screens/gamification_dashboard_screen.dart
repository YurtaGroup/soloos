import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../widgets/daily_score_card.dart';
import '../widgets/xp_progress_card.dart';
import '../widgets/streaks_card.dart';
import '../widgets/category_progress_list.dart';
import '../widgets/daily_missions_card.dart';
import '../widgets/ai_coach_card.dart';

class GamificationDashboardScreen extends StatefulWidget {
  const GamificationDashboardScreen({super.key});

  @override
  State<GamificationDashboardScreen> createState() =>
      _GamificationDashboardScreenState();
}

class _GamificationDashboardScreenState
    extends State<GamificationDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GamificationViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(vm),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Score ring
                DailyScoreCard(
                  score: vm.todayScoreValue,
                  xpEarned: vm.todayScore?.xpEarned ?? 0,
                ),
                const SizedBox(height: 12),

                // XP / Level
                XpProgressCard(progress: vm.progress),
                const SizedBox(height: 20),

                // Coach suggestions
                if (vm.coachSuggestions.isNotEmpty) ...[
                  _sectionHeader('🧠 Coach'),
                  const SizedBox(height: 8),
                  ...vm.coachSuggestions.map((s) => AiCoachCard(
                        suggestion: s,
                        onDismiss: () =>
                            vm.dismissCoachSuggestion(s.id),
                      )),
                  const SizedBox(height: 12),
                ],

                // Daily missions
                _sectionHeader(
                  '🎯 Daily Missions',
                  trailing:
                      '${vm.missionsCompletedCount}/${vm.totalMissionsCount}',
                ),
                const SizedBox(height: 8),
                DailyMissionsCard(
                  missions: vm.todayMissions,
                  onComplete: vm.completeMissionManually,
                ),
                const SizedBox(height: 20),

                // Streaks
                _sectionHeader('🔥 Streaks'),
                const SizedBox(height: 8),
                StreaksCard(activeStreaks: vm.activeStreaks),
                const SizedBox(height: 20),

                // Category breakdown
                _sectionHeader('📊 Category Scores'),
                const SizedBox(height: 8),
                if (vm.todayScore != null)
                  CategoryProgressList(
                    categoryScores: vm.todayScore!.categoryScores,
                  )
                else
                  _EmptyCategories(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(GamificationViewModel vm) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ Progress',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Level ${vm.progress.level} · ${vm.progress.levelTitle}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
      ],
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Complete actions across modules to see category scores.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    );
  }
}
