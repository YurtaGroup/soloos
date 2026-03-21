import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/locale_service.dart';
import 'services/google_calendar_service.dart';
import 'features/ideas/presentation/viewmodels/ideas_view_model.dart';
import 'features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'features/finance/presentation/viewmodels/finance_view_model.dart';
import 'features/family/presentation/viewmodels/family_viewmodel.dart';
import 'features/gamification/presentation/viewmodels/gamification_viewmodel.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final storage = StorageService();
  await storage.init();

  final localeService = LocaleService();
  await localeService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeService),
        ChangeNotifierProvider.value(value: GoogleCalendarService()),
        ChangeNotifierProvider(create: (_) => IdeasViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
        ChangeNotifierProvider(create: (_) => FamilyViewModel()),
        ChangeNotifierProvider(create: (_) => GamificationViewModel()),
      ],
      child: SoloOSApp(isOnboarded: storage.onboardingDone),
    ),
  );
}

class SoloOSApp extends StatelessWidget {
  final bool isOnboarded;
  const SoloOSApp({super.key, required this.isOnboarded});

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();

    return MaterialApp(
      title: 'Solo OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
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
      home: isOnboarded ? const DashboardScreen() : const OnboardingScreen(),
    );
  }
}
