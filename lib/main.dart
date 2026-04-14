import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/locale_service.dart';
import 'services/google_calendar_service.dart';
import 'services/api_service.dart';
import 'services/claude_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/analytics_service.dart';
import 'services/pro_service.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/ideas/presentation/viewmodels/ideas_view_model.dart';
import 'features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'features/finance/presentation/viewmodels/finance_view_model.dart';
import 'features/family/presentation/viewmodels/family_viewmodel.dart';
import 'features/gamification/presentation/viewmodels/gamification_viewmodel.dart';
import 'features/health/presentation/viewmodels/habits_view_model.dart';
import 'features/work/presentation/viewmodels/projects_view_model.dart';
import 'features/work/presentation/viewmodels/standup_view_model.dart';
import 'features/family/presentation/viewmodels/contacts_view_model.dart';
import 'features/home/presentation/screens/onboarding_screen.dart';
import 'features/home/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Load env (may not exist in production web builds)
  bool apiReady = false;
  String sentryDsn = '';
  try {
    await dotenv.load(fileName: '.env');
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
    if (baseUrl.isNotEmpty) {
      ClaudeService.proxyBaseUrl = baseUrl;
      apiReady = true;
    }
  } catch (e) {
    debugPrint('Env load skipped: $e');
  }

  // Local storage always available
  final storage = StorageService();
  await storage.init();

  // Initialize API service (restores JWT tokens from local storage)
  if (apiReady) {
    await ApiService.init();
  }

  // Initialize notifications
  await NotificationService().init();

  // Initialize analytics (batched, offline-safe)
  await AnalyticsService().init();

  // Restore Pro/trial status (persists across restarts)
  await ProService().init();

  final localeService = LocaleService();
  await localeService.init();

  final themeService = ThemeService();
  await themeService.init();

  final app = MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: localeService),
      ChangeNotifierProvider.value(value: themeService),
      ChangeNotifierProvider.value(value: GoogleCalendarService()),
      ChangeNotifierProvider(create: (_) => IdeasViewModel()),
      ChangeNotifierProvider(create: (_) => DashboardViewModel()),
      ChangeNotifierProvider(create: (_) => FinanceViewModel()),
      ChangeNotifierProvider(create: (_) => FamilyViewModel()),
      ChangeNotifierProvider(create: (_) => GamificationViewModel()),
      ChangeNotifierProvider(create: (_) => HabitsViewModel()),
      ChangeNotifierProvider(create: (_) => ProjectsViewModel()),
      ChangeNotifierProvider(create: (_) => StandupViewModel()),
      ChangeNotifierProvider(create: (_) => ContactsViewModel()),
    ],
    child: SoloOSApp(
      isOnboarded: storage.onboardingDone,
      apiReady: apiReady,
    ),
  );

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.environment =
            const String.fromEnvironment('ENV', defaultValue: 'production');
      },
      appRunner: () => runApp(app),
    );
  } else {
    runApp(app);
  }
}

class SoloOSApp extends StatelessWidget {
  final bool isOnboarded;
  final bool apiReady;
  const SoloOSApp({
    super.key,
    required this.isOnboarded,
    required this.apiReady,
  });

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final themeService = context.watch<ThemeService>();

    // Sync system status bar icons with the active theme.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: themeService.isDark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: themeService.isDark
          ? Brightness.dark
          : Brightness.light,
    ));

    return MaterialApp(
      title: 'Solo OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeService.mode,
      builder: (context, child) {
        // Gentle global bump so every Text widget reads larger without
        // touching individual screens. Respects the user's system scale:
        // we multiply on top of it and cap to avoid broken layouts.
        final mq = MediaQuery.of(context);
        final systemScale = mq.textScaler.scale(1.0);
        final boosted = (systemScale * 1.12).clamp(1.0, 1.6);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(boosted)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      locale: localeService.flutterLocale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ru', 'RU'),
        Locale('ky', 'KG'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: apiReady
          ? const _AuthGate()
          : isOnboarded
              ? const DashboardScreen()
              : const OnboardingScreen(),
    );
  }
}

/// Checks JWT auth state and routes accordingly.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _didReload = false;

  void _reloadAllViewModels(BuildContext context) {
    if (_didReload) return;
    _didReload = true;
    context.read<IdeasViewModel>().reload();
    context.read<HabitsViewModel>().reload();
    context.read<ProjectsViewModel>().reload();
    context.read<StandupViewModel>().reload();
    context.read<ContactsViewModel>().reload();
    context.read<FinanceViewModel>().reload();
    context.read<FamilyViewModel>().reload();
  }

  @override
  Widget build(BuildContext context) {
    if (ApiService.isAuthenticated) {
      // Reload ViewModels once after login so they fetch from API
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadAllViewModels(context);
      });

      final storage = StorageService();
      return storage.onboardingDone
          ? const DashboardScreen()
          : const OnboardingScreen();
    }

    // Reset reload flag on logout
    _didReload = false;
    return AuthScreen(
      onAuthSuccess: () => setState(() {}),
    );
  }
}
