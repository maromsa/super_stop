import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/coin_provider.dart';
import 'providers/daily_goals_provider.dart';
import 'providers/level_provider.dart';
import 'providers/mood_journal_provider.dart';
import 'router/app_router.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/achievement_service.dart';
import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
        ChangeNotifierProvider(create: (_) => CoinProvider()),
        ChangeNotifierProvider(create: (_) => DailyGoalsProvider()),
        ChangeNotifierProvider(create: (_) => LevelProvider()),
        ChangeNotifierProvider(create: (_) => MoodJournalProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          locale: const Locale('he'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.homeTitle,
          onGenerateRoute: AppRouter.onGenerateRoute,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            fontFamily: 'Alef',
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            fontFamily: 'Alef',
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const _AppLaunchDecider(),
        );
      },
    );
  }
}

class _AppLaunchDecider extends StatelessWidget {
  const _AppLaunchDecider();

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodJournalProvider>(
      builder: (context, journal, _) {
        if (!journal.isReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (journal.hasCompletedOnboarding) {
          return const HomeScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}