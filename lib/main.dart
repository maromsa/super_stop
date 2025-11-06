import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/adaptive_focus_challenge_provider.dart';
import 'providers/boss_battle_provider.dart';
import 'providers/calm_mode_provider.dart';
import 'providers/coin_provider.dart';
import 'providers/collectible_provider.dart';
import 'providers/community_challenge_provider.dart';
import 'providers/daily_goals_provider.dart';
import 'providers/daily_quest_provider.dart';
import 'providers/habit_story_provider.dart';
import 'providers/level_provider.dart';
import 'providers/mood_journal_provider.dart';
import 'providers/mood_music_mixer_provider.dart';
import 'providers/mystery_quest_provider.dart';
import 'providers/social_treasure_provider.dart';
import 'providers/virtual_companion_provider.dart';
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
          ChangeNotifierProvider(create: (_) => CollectibleProvider()),
          ChangeNotifierProvider(create: (_) => CommunityChallengeProvider()),
          ChangeNotifierProvider(create: (_) => MysteryQuestProvider()),
          ChangeNotifierProvider(create: (_) => DailyGoalsProvider()),
          ChangeNotifierProvider(create: (_) => DailyQuestProvider()),
          ChangeNotifierProvider(create: (_) => CalmModeProvider()),
          ChangeNotifierProvider(create: (_) => SocialTreasureProvider()),
          ChangeNotifierProvider(create: (_) => BossBattleProvider()),
          ChangeNotifierProvider(create: (_) => MoodMusicMixerProvider()),
          ChangeNotifierProxyProvider2<DailyGoalsProvider, AchievementService, VirtualCompanionProvider>(
            create: (_) => VirtualCompanionProvider(),
            update: (_, goals, achievements, companion) {
              companion ??= VirtualCompanionProvider();
              companion.updateFrom(goals, achievements);
              return companion;
            },
          ),
          ChangeNotifierProxyProvider2<DailyGoalsProvider, CollectibleProvider, HabitStoryProvider>(
            create: (_) => HabitStoryProvider(),
            update: (_, goals, collectibles, story) {
              story ??= HabitStoryProvider();
              unawaited(story.updateFromGoals(goals, collectibles: collectibles));
              return story;
            },
          ),
          ChangeNotifierProvider(create: (_) => LevelProvider()),
          ChangeNotifierProvider(create: (_) => MoodJournalProvider()),
          ChangeNotifierProxyProvider<MoodJournalProvider, AdaptiveFocusChallengeProvider>(
            create: (_) => AdaptiveFocusChallengeProvider(),
            update: (_, journal, provider) {
              provider ??= AdaptiveFocusChallengeProvider();
              provider.updateFromMoodJournal(journal);
              return provider;
            },
          ),
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
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
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