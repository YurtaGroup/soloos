import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/demo_data_seeder.dart';
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

    // Seed base demo data first (finance, contacts, extra projects)
    await DemoDataSeeder.seedIfEmpty(_storage);

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
      // AI failed — use answers directly as fallback
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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  void _applyAiSetup(String raw, String name, String business, String challenge, String habit) {
    try {
      // Strip markdown code fences if present
      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '').replaceFirst(RegExp(r'\n?```$'), '');
      }
      final data = jsonDecode(cleaned) as Map<String, dynamic>;

      final projectName = data['project_name'] as String? ?? business;
      final tasks = (data['project_tasks'] as List?)?.cast<String>() ?? [];
      final priorities = (data['task_priorities'] as List?)?.cast<String>() ?? [];
      final habitName = data['habit_name'] as String? ?? habit;
      final habitEmoji = data['habit_emoji'] as String? ?? '🎯';
      final digest = data['digest'] as String? ?? '';

      // Create personalized project at the front of the list
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

      // Add personalized habit at the front
      final existingHabits = _storage.getHabits();
      final newHabit = Habit(
        id: _uuid.v4(),
        name: habitName,
        emoji: habitEmoji,
      );
      _storage.saveHabits([newHabit, ...existingHabits]);

      // Set AI digest with personalized content
      if (digest.isNotEmpty) {
        _storage.setLastAiDigest(digest);
        _storage.setLastDigestDate(now.toIso8601String());
      }

      // Save first standup from challenge
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

    // Create project from business answer
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

    // Create habit
    final existingHabits = _storage.getHabits();
    final newHabit = Habit(id: _uuid.v4(), name: habit, emoji: '🎯');
    _storage.saveHabits([newHabit, ...existingHabits]);

    // Create standup
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
      backgroundColor: const Color(0xFF0F172A),
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
                gradient: const [Color(0xFF0F172A), Color(0xFF1E40AF)],
                onNext: _next,
                buttonText: loc.t('continue_btn'),
              ),
              // Screen 2 — Promise
              _IntroPage(
                title: loc.t('ob_promise_title'),
                subtitle: loc.t('ob_promise_sub'),
                gradient: const [Color(0xFF581C87), Color(0xFFBE185D)],
                onNext: _next,
                buttonText: loc.t('ob_show_me'),
              ),
              // Screen 3 — Name
              _QuestionPage(
                question: loc.t('ob_setup_title'),
                hint: loc.t('name_hint'),
                controller: _nameController,
                gradient: const [Color(0xFF065F46), Color(0xFF0F172A)],
                onNext: () => _nextIfFilled(_nameController),
                buttonText: loc.t('continue_btn'),
                autoCapitalize: TextCapitalization.words,
              ),
              // Screen 4 — Business
              _QuestionPage(
                question: loc.t('ob_q_business'),
                hint: loc.t('ob_q_business_hint'),
                controller: _businessController,
                gradient: const [Color(0xFF1E3A5F), Color(0xFF0F172A)],
                onNext: () => _nextIfFilled(_businessController),
                buttonText: loc.t('continue_btn'),
                autoCapitalize: TextCapitalization.sentences,
              ),
              // Screen 5 — Challenge
              _QuestionPage(
                question: loc.t('ob_q_challenge'),
                hint: loc.t('ob_q_challenge_hint'),
                controller: _challengeController,
                gradient: const [Color(0xFF78350F), Color(0xFF0F172A)],
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
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Intro page (hook & promise) ────────────────────────────────

class _IntroPage extends StatelessWidget {
  final String title, subtitle, buttonText;
  final List<Color> gradient;
  final VoidCallback onNext;

  const _IntroPage({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onNext,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 17,
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 4),
              _WhiteButton(text: buttonText, onPressed: onNext),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single-question page ───────────────────────────────────────

class _QuestionPage extends StatelessWidget {
  final String question, hint, buttonText;
  final TextEditingController controller;
  final List<Color> gradient;
  final VoidCallback onNext;
  final TextCapitalization autoCapitalize;

  const _QuestionPage({
    required this.question,
    required this.hint,
    required this.controller,
    required this.gradient,
    required this.onNext,
    required this.buttonText,
    this.autoCapitalize = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                textCapitalization: autoCapitalize,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onNext(),
              ),
              const Spacer(flex: 3),
              _WhiteButton(text: buttonText, onPressed: onNext),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Final page (habit + CTA + loading) ─────────────────────────

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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4C1D95), Color(0xFF0F172A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: isLoading
              ? _buildLoading(context)
              : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          loadingText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onFinish(),
        ),
        const SizedBox(height: 20),
        // Trial badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Text('', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trialText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
        _WhiteButton(
          text: ctaText,
          onPressed: onFinish,
          color: const Color(0xFF4C1D95),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            noCardText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ─── Shared button ──────────────────────────────────────────────

class _WhiteButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const _WhiteButton({
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFF1E40AF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
