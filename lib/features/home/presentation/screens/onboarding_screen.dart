import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/demo_data_seeder.dart';
import '../../../../services/pro_service.dart';
import '../../../ideas/presentation/viewmodels/ideas_view_model.dart';
import '../../../health/presentation/viewmodels/habits_view_model.dart';
import '../../../work/presentation/viewmodels/projects_view_model.dart';
import '../../../work/presentation/viewmodels/standup_view_model.dart';
import '../../../family/presentation/viewmodels/contacts_view_model.dart';
import '../../../finance/presentation/viewmodels/finance_view_model.dart';
import '../../../family/presentation/viewmodels/family_viewmodel.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _storage = StorageService();
  int _currentPage = 0;
  bool _loadDemoData = false;

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      emoji: '🚀',
      title: 'Welcome to\nSolo OS',
      subtitle: 'Your AI-powered operating system\nfor solopreneurs.',
      gradient: [AppColors.gradientStart, AppColors.gradientEnd],
    ),
    _OnboardPage(
      emoji: '⚡',
      title: 'Do 20%.\nAchieve 80%.',
      subtitle: 'Solo OS handles the rest. AI does the heavy lifting\nso you can focus on what matters.',
      gradient: [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
    ),
    _OnboardPage(
      emoji: '🤖',
      title: 'Your AI\nExecutive Team',
      subtitle: 'Daily standup bot · Content manager ·\nIdea validator · Executive assistant',
      gradient: [const Color(0xFF065F46), const Color(0xFF0284C7)],
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    await _storage.setUserName(name);
    if (_loadDemoData) {
      await DemoDataSeeder.seedIfEmpty(_storage);
    }
    // Start 30-day trial for new users
    final pro = ProService();
    await pro.init();
    await pro.startTrial();
    await _storage.setOnboardingDone();
    if (!mounted) return;

    // Reload all ViewModels so they pick up seeded demo data
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          ..._pages.asMap().entries.map((e) => _IntroPage(page: e.value, onNext: _next)),
          _SetupPage(
            nameController: _nameController,
            loadDemoData: _loadDemoData,
            onToggleDemo: () => setState(() => _loadDemoData = !_loadDemoData),
            onFinish: _finish,
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _IntroPage extends StatelessWidget {
  final _OnboardPage page;
  final VoidCallback onNext;

  const _IntroPage({required this.page, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(page.emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 24),
              Text(
                page.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page.subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: page.gradient[0],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue →',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  final TextEditingController nameController;
  final bool loadDemoData;
  final VoidCallback onToggleDemo;
  final VoidCallback onFinish;

  const _SetupPage({
    required this.nameController,
    required this.loadDemoData,
    required this.onToggleDemo,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('👋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 20),
            Text(
              "Let's set up\nyour Solo OS",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Takes 10 seconds. AI features included.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Name
            const Text(
              'Your name',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Alex, Sarah, Marcus...',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Text('🎁', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '30-day free trial — all Pro features unlocked',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onToggleDemo,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: loadDemoData
                      ? AppColors.accentGreen.withOpacity(0.08)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: loadDemoData
                        ? AppColors.accentGreen.withOpacity(0.3)
                        : AppColors.textMuted.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      loadDemoData
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: loadDemoData
                          ? AppColors.accentGreen
                          : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Load sample data',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'See how Solo OS works with example projects & habits',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Launch Solo OS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 8),
                    Text('🚀', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
