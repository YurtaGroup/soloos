import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../theme/tokens.dart';
import '../../../../theme/text_styles.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/pro_service.dart';
import '../../../../services/claude_service.dart';
import '../../../../services/locale_service.dart';
import '../../../../models/app_models.dart';
import '../../../ideas/presentation/viewmodels/ideas_view_model.dart';
import '../../../health/presentation/viewmodels/habits_view_model.dart';
import '../../../work/presentation/viewmodels/projects_view_model.dart';
import '../../../work/presentation/viewmodels/standup_view_model.dart';
import '../../../family/presentation/viewmodels/contacts_view_model.dart';
import '../../../finance/presentation/viewmodels/finance_view_model.dart';
import '../../../family/presentation/viewmodels/family_viewmodel.dart';
import 'dashboard_screen.dart';

const _uuid = Uuid();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _challengeController = TextEditingController();
  final _habitController = TextEditingController();
  final _storage = StorageService();
  int _currentPage = 0;
  bool _isSettingUp = false;

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextIfFilled(TextEditingController controller) {
    if (controller.text.trim().isEmpty) return;
    _next();
  }

  Future<void> _finish() async {
    if (_habitController.text.trim().isEmpty) return;
    setState(() => _isSettingUp = true);

    final name = _nameController.text.trim();
    final business = _businessController.text.trim();
    final challenge = _challengeController.text.trim();
    final habit = _habitController.text.trim();

    await _storage.setUserName(name);

    // Show AI disclosure and get consent before first AI call
    if (!_storage.aiConsentGiven && mounted) {
      final ls = context.read<LocaleService>();
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(ls.t('ai_disclosure_title')),
          content: Text(ls.t('ai_disclosure_body'),
              style: const TextStyle(height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ls.t('ai_disclosure_decline')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ls.t('ai_disclosure_accept')),
            ),
          ],
        ),
      );
      await _storage.setAiConsentGiven(accepted == true);
    }

    // Try AI-powered personalized setup
    try {
      final claude = ClaudeService();
      final raw = await claude.generateOnboardingSetup(
        userName: name,
        business: business,
        challenge: challenge,
        habit: habit,
      );
      _applyAiSetup(raw, name, business, challenge, habit);
    } catch (_) {
      _applyFallbackSetup(name, business, challenge, habit);
    }

    // Start 30-day Pro trial
    final pro = ProService();
    await pro.init();
    await pro.startTrial();
    await _storage.setOnboardingDone();
    if (!mounted) return;

    // Reload all ViewModels
    context.read<ProjectsViewModel>().reload();
    context.read<HabitsViewModel>().reload();
    context.read<IdeasViewModel>().reload();
    context.read<StandupViewModel>().reload();
    context.read<ContactsViewModel>().reload();
    context.read<FinanceViewModel>().reload();
    context.read<FamilyViewModel>().reload();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _applyAiSetup(String raw, String name, String business, String challenge, String habit) {
    try {
      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```\w*\n?'), '')
            .replaceFirst(RegExp(r'\n?```$'), '');
      }
      final data = jsonDecode(cleaned) as Map<String, dynamic>;

      final projectName = data['project_name'] as String? ?? business;
      final tasks = (data['project_tasks'] as List?)?.cast<String>() ?? [];
      final priorities = (data['task_priorities'] as List?)?.cast<String>() ?? [];
      final habitName = data['habit_name'] as String? ?? habit;
      final habitEmoji = data['habit_emoji'] as String? ?? '';
      final digest = data['digest'] as String? ?? '';

      final now = DateTime.now();
      final existingProjects = _storage.getProjects();
      final newProject = Project(
        id: _uuid.v4(),
        name: projectName,
        description: business,
        tasks: List.generate(tasks.length, (i) => Task(
          id: _uuid.v4(),
          title: tasks[i],
          priority: i < priorities.length ? priorities[i] : 'medium',
          createdAt: now,
        )),
        createdAt: now,
      );
      _storage.saveProjects([newProject, ...existingProjects]);

      final existingHabits = _storage.getHabits();
      final newHabit = Habit(
        id: _uuid.v4(),
        name: habitName,
        emoji: habitEmoji,
      );
      _storage.saveHabits([newHabit, ...existingHabits]);

      if (digest.isNotEmpty) {
        _storage.setLastAiDigest(digest);
        _storage.setLastDigestDate(now.toIso8601String());
      }

      final existingLogs = _storage.getStandupLogs();
      existingLogs.insert(0, StandupLog(
        id: _uuid.v4(),
        date: now,
        wins: 'Set up Solo OS and defined my priorities.',
        challenges: challenge,
        priorities: 'Focus on $projectName — ${tasks.isNotEmpty ? tasks.first : "get started"}',
      ));
      _storage.saveStandupLogs(existingLogs);
    } catch (_) {
      _applyFallbackSetup(name, business, challenge, habit);
    }
  }

  void _applyFallbackSetup(String name, String business, String challenge, String habit) {
    final now = DateTime.now();

    final existingProjects = _storage.getProjects();
    final newProject = Project(
      id: _uuid.v4(),
      name: business,
      description: '',
      tasks: [
        Task(id: _uuid.v4(), title: 'Define top 3 priorities for this week', priority: 'high', createdAt: now),
        Task(id: _uuid.v4(), title: 'Tackle: $challenge', priority: 'high', createdAt: now),
        Task(id: _uuid.v4(), title: 'Review progress at end of day', priority: 'medium', createdAt: now),
      ],
      createdAt: now,
    );
    _storage.saveProjects([newProject, ...existingProjects]);

    final existingHabits = _storage.getHabits();
    final newHabit = Habit(id: _uuid.v4(), name: habit, emoji: '');
    _storage.saveHabits([newHabit, ...existingHabits]);

    final existingLogs = _storage.getStandupLogs();
    existingLogs.insert(0, StandupLog(
      id: _uuid.v4(),
      date: now,
      wins: 'Set up Solo OS and defined my priorities.',
      challenges: challenge,
      priorities: 'Focus on $business',
    ));
    _storage.saveStandupLogs(existingLogs);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocaleService>();
    return Scaffold(
      // Onboarding is intentionally dark — photo-scrim pattern, not app chrome
      backgroundColor: ColorTokens.night950,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              // Screen 1 — Hook
              _IntroPage(
                title: loc.t('ob_hook_title'),
                subtitle: loc.t('ob_hook_sub'),
                onNext: _next,
                buttonText: loc.t('continue_btn'),
              ),
              // Screen 2 — Promise
              _IntroPage(
                title: loc.t('ob_promise_title'),
                subtitle: loc.t('ob_promise_sub'),
                onNext: _next,
                buttonText: loc.t('ob_show_me'),
              ),
              // Screen 3 — Name
              _QuestionPage(
                question: loc.t('ob_setup_title'),
                hint: loc.t('name_hint'),
                controller: _nameController,
                onNext: () => _nextIfFilled(_nameController),
                buttonText: loc.t('continue_btn'),
                autoCapitalize: TextCapitalization.words,
              ),
              // Screen 4 — Business
              _QuestionPage(
                question: loc.t('ob_q_business'),
                hint: loc.t('ob_q_business_hint'),
                controller: _businessController,
                onNext: () => _nextIfFilled(_businessController),
                buttonText: loc.t('continue_btn'),
                autoCapitalize: TextCapitalization.sentences,
              ),
              // Screen 5 — Challenge
              _QuestionPage(
                question: loc.t('ob_q_challenge'),
                hint: loc.t('ob_q_challenge_hint'),
                controller: _challengeController,
                onNext: () => _nextIfFilled(_challengeController),
                buttonText: loc.t('continue_btn'),
                autoCapitalize: TextCapitalization.sentences,
              ),
              // Screen 6 — Habit + Launch
              _FinalPage(
                question: loc.t('ob_q_habit'),
                hint: loc.t('ob_q_habit_hint'),
                controller: _habitController,
                isLoading: _isSettingUp,
                trialText: loc.t('ob_trial_badge'),
                noCardText: loc.t('ob_no_card'),
                ctaText: loc.t('ob_cta'),
                loadingText: loc.t('ob_loading'),
                onFinish: _finish,
              ),
            ],
          ),
          // Page indicator
          if (!_isSettingUp)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 100,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? ColorTokens.lime500
                        : ColorTokens.ink500.withValues(alpha: 0.4),
                    borderRadius: RadiusTokens.pillAll,
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Intro page (hook & promise) ────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  final String title, subtitle, buttonText;
  final VoidCallback onNext;

  const _IntroPage({
    required this.title,
    required this.subtitle,
    required this.onNext,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.night950,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpaceTokens.s32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Text(
                title,
                style: TextStyles.displayLg(context).copyWith(
                  color: ColorTokens.ink100,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: SpaceTokens.s16),
              Text(
                subtitle,
                style: TextStyles.bodyLg(context).copyWith(
                  color: ColorTokens.ink500,
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 4),
              _OnboardingCTA(text: buttonText, onPressed: onNext),
              const SizedBox(height: SpaceTokens.s48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single-question page ─────────────────────────────────────────────────────

class _QuestionPage extends StatelessWidget {
  final String question, hint, buttonText;
  final TextEditingController controller;
  final VoidCallback onNext;
  final TextCapitalization autoCapitalize;

  const _QuestionPage({
    required this.question,
    required this.hint,
    required this.controller,
    required this.onNext,
    required this.buttonText,
    this.autoCapitalize = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.night950,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpaceTokens.s32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                question,
                style: TextStyles.displayLg(context).copyWith(
                  color: ColorTokens.ink100,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: SpaceTokens.s24),
              TextField(
                controller: controller,
                style: TextStyles.bodyLg(context).copyWith(
                    color: ColorTokens.ink100),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyles.bodyLg(context).copyWith(
                      color: ColorTokens.ink700),
                  filled: true,
                  fillColor: ColorTokens.night900,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: SpaceTokens.s16, vertical: SpaceTokens.s16),
                  border: OutlineInputBorder(
                    borderRadius: RadiusTokens.smAll,
                    borderSide: BorderSide(color: ColorTokens.night800),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: RadiusTokens.smAll,
                    borderSide: BorderSide(color: ColorTokens.night800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: RadiusTokens.smAll,
                    borderSide: BorderSide(color: ColorTokens.lime500, width: 1.5),
                  ),
                ),
                textCapitalization: autoCapitalize,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onNext(),
              ),
              const Spacer(flex: 3),
              _OnboardingCTA(text: buttonText, onPressed: onNext),
              const SizedBox(height: SpaceTokens.s48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Final page (habit + CTA + loading) ─────────────────────────────────────

class _FinalPage extends StatelessWidget {
  final String question, hint, trialText, noCardText, ctaText, loadingText;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onFinish;

  const _FinalPage({
    required this.question,
    required this.hint,
    required this.controller,
    required this.isLoading,
    required this.trialText,
    required this.noCardText,
    required this.ctaText,
    required this.loadingText,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.night950,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpaceTokens.s32),
          child: isLoading ? _buildLoading(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorTokens.lime500,
          ),
        ),
        const SizedBox(height: SpaceTokens.s24),
        Text(
          loadingText,
          textAlign: TextAlign.center,
          style: TextStyles.bodyLg(context).copyWith(
            color: ColorTokens.ink500,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 2),
        Text(
          question,
          style: TextStyles.displayLg(context).copyWith(
            color: ColorTokens.ink100,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: SpaceTokens.s24),
        TextField(
          controller: controller,
          style: TextStyles.bodyLg(context).copyWith(color: ColorTokens.ink100),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyles.bodyLg(context).copyWith(color: ColorTokens.ink700),
            filled: true,
            fillColor: ColorTokens.night900,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: SpaceTokens.s16, vertical: SpaceTokens.s16),
            border: OutlineInputBorder(
              borderRadius: RadiusTokens.smAll,
              borderSide: BorderSide(color: ColorTokens.night800),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: RadiusTokens.smAll,
              borderSide: BorderSide(color: ColorTokens.night800),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: RadiusTokens.smAll,
              borderSide: BorderSide(color: ColorTokens.lime500, width: 1.5),
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onFinish(),
        ),
        const SizedBox(height: SpaceTokens.s16),
        // Trial badge — no emoji, text-only
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: SpaceTokens.s16, vertical: SpaceTokens.s12),
          decoration: BoxDecoration(
            color: ColorTokens.lime500.withValues(alpha: 0.08),
            borderRadius: RadiusTokens.smAll,
            border: Border.all(
                color: ColorTokens.lime500.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_outlined,
                  size: 18, color: ColorTokens.lime500),
              const SizedBox(width: SpaceTokens.s12),
              Expanded(
                child: Text(
                  trialText,
                  style: TextStyles.bodySm(context)
                      .copyWith(color: ColorTokens.ink500),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
        _OnboardingCTA(text: ctaText, onPressed: onFinish),
        const SizedBox(height: SpaceTokens.s8),
        Center(
          child: Text(
            noCardText,
            style:
                TextStyles.bodySm(context).copyWith(color: ColorTokens.ink700),
          ),
        ),
        const SizedBox(height: SpaceTokens.s48),
      ],
    );
  }
}

// ─── Shared CTA button ────────────────────────────────────────────────────────
// Dark-mode primary: lime fill, ink label.

class _OnboardingCTA extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _OnboardingCTA({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: MotionTokens.duration,
          curve: MotionTokens.curve,
          padding: const EdgeInsets.symmetric(vertical: SpaceTokens.s16),
          decoration: BoxDecoration(
            color: ColorTokens.lime500,
            borderRadius: RadiusTokens.smAll,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyles.bodyMd(context).copyWith(
                color: ColorTokens.ink900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
