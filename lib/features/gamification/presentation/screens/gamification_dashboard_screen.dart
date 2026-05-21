import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../theme/atoms/section_label.dart';
import '../../../../theme/atoms/app_card.dart';
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
    final c = QColors.of(context);
    final vm = context.watch<GamificationViewModel>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, vm, c),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                SpaceTokens.s16, 0, SpaceTokens.s16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Score ring
                DailyScoreCard(
                  score: vm.todayScoreValue,
                  xpEarned: vm.todayScore?.xpEarned ?? 0,
                ),
                const SizedBox(height: SpaceTokens.s12),

                // XP / Level
                XpProgressCard(progress: vm.progress),
                const SizedBox(height: SpaceTokens.s24),

                // Coach suggestions
                if (vm.coachSuggestions.isNotEmpty) ...[
                  SectionLabel('Coach'),
                  ...vm.coachSuggestions.map((s) => AiCoachCard(
                        suggestion: s,
                        onDismiss: () => vm.dismissCoachSuggestion(s.id),
                      )),
                  const SizedBox(height: SpaceTokens.s12),
                ],

                // Daily missions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionLabel('Daily Missions', bottomPadding: 0),
                    Text(
                      '${vm.missionsCompletedCount}/${vm.totalMissionsCount}',
                      style: TextStyles.bodySm(context)
                          .copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: SpaceTokens.s8),
                DailyMissionsCard(
                  missions: vm.todayMissions,
                  onComplete: vm.completeMissionManually,
                ),
                const SizedBox(height: SpaceTokens.s24),

                // Streaks
                SectionLabel('Streaks'),
                StreaksCard(activeStreaks: vm.activeStreaks),
                const SizedBox(height: SpaceTokens.s24),

                // Category breakdown
                SectionLabel('Category Scores'),
                if (vm.todayScore != null)
                  CategoryProgressList(
                    categoryScores: vm.todayScore!.categoryScores,
                  )
                else
                  _EmptyCategories(),
                const SizedBox(height: SpaceTokens.s32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GamificationViewModel vm, QColorSet c) {
    return SliverAppBar(
      floating: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress', style: TextStyles.displayMd(context)),
          Text(
            'Level ${vm.progress.level} · ${vm.progress.levelTitle}',
            style: TextStyles.bodySm(context)
                .copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = QColors.of(context);
    return AppCard(
      child: Text(
        'Complete actions across modules to see category scores.',
        style: TextStyles.bodyMd(context).copyWith(color: c.textSecondary),
      ),
    );
  }
}
