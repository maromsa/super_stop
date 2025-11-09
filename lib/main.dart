import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'l10n/app_localizations.dart';
import 'providers/adaptive_focus_challenge_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_spark_lab_provider.dart';
import 'providers/boss_battle_provider.dart';
import 'providers/calm_mode_provider.dart';
import 'providers/coin_provider.dart';
import 'providers/collectible_provider.dart';
import 'providers/community_challenge_provider.dart';
import 'providers/daily_goals_provider.dart';
import 'providers/daily_quest_provider.dart';
import 'providers/focus_garden_provider.dart';
import 'providers/habit_story_provider.dart';
import 'providers/level_provider.dart';
import 'providers/mood_journal_provider.dart';
import 'providers/mood_music_mixer_provider.dart';
import 'providers/mystery_quest_provider.dart';
import 'providers/social_treasure_provider.dart';
import 'providers/virtual_companion_provider.dart';
import 'router/app_router.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/achievement_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/user_state_repository.dart';
import 'theme_provider.dart';
import 'firebase_options.dart';

const bool kBypassFirebaseAuth =
    bool.fromEnvironment('BYPASS_FIREBASE_AUTH') || bool.fromEnvironment('FLUTTER_TEST');

Future<void> main() async {
  await bootstrapApp();
}

Future<void> bootstrapApp({bool? bypassAuthOverride}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  final bool bypassAuth = bypassAuthOverride ?? kBypassFirebaseAuth;

  if (!bypassAuth) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  runApp(
    MultiProvider(
      providers: _buildProviders(bypassAuth: bypassAuth),
      child: const MyApp(),
    ),
  );
}

List<SingleChildWidget> _buildProviders({required bool bypassAuth}) {
  final providers = <SingleChildWidget>[
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => AchievementService()),
    ChangeNotifierProvider(create: (_) => CoinProvider()),
    ChangeNotifierProvider(create: (_) => FocusGardenProvider()),
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
  ];

  if (bypassAuth) {
    providers.add(
      ChangeNotifierProvider(create: (_) => FirebaseAuthService(bypassAuth: true)),
    );
  } else {
    providers.addAll([
      Provider<UserStateRepository>(
        create: (_) => UserStateRepository(FirebaseFirestore.instance),
      ),
      ChangeNotifierProxyProvider2<MoodJournalProvider, UserStateRepository, FirebaseAuthService>(
        create: (_) => FirebaseAuthService(),
        update: (_, journal, repository, authService) {
          authService ??= FirebaseAuthService();
          authService.updateDependencies(
            moodJournalProvider: journal,
            userStateRepository: repository,
          );
          return authService;
        },
      ),
    ]);
  }

  providers.add(
    ChangeNotifierProxyProvider<MoodJournalProvider, AdaptiveFocusChallengeProvider>(
      create: (_) => AdaptiveFocusChallengeProvider(),
      update: (_, journal, provider) {
        provider ??= AdaptiveFocusChallengeProvider();
        provider.updateFromMoodJournal(journal);
        return provider;
      },
    ),
  );

  providers.add(
    ChangeNotifierProxyProvider4<MoodJournalProvider, DailyGoalsProvider, AdaptiveFocusChallengeProvider,
        VirtualCompanionProvider, AiSparkLabProvider>(
      create: (_) => AiSparkLabProvider(),
      update: (_, journal, goals, focusChallenge, companion, provider) {
        provider ??= AiSparkLabProvider();
        provider.updateSources(
          moodJournal: journal,
          dailyGoals: goals,
          focusChallenge: focusChallenge,
          companion: companion,
        );
        return provider;
      },
    ),
  );

  return providers;
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
    return Consumer<FirebaseAuthService>(
      builder: (context, authService, _) {
        final l10n = AppLocalizations.of(context);

        if (authService.isAuthBypassed) {
          return _buildJournalDrivenContent(context, l10n);
        }

        if (!authService.hasCompletedInitialAuth || authService.isInitialSyncInProgress) {
          return _LoadingScaffold(message: l10n?.authSyncInProgress);
        }

        if (authService.user == null) {
          return const SignInScreen();
        }

        return _buildJournalDrivenContent(context, l10n);
      },
    );
  }
}

Widget _buildJournalDrivenContent(BuildContext context, AppLocalizations? l10n) {
  return Consumer<MoodJournalProvider>(
    builder: (context, journal, __) {
      if (!journal.isReady) {
        return _LoadingScaffold(message: l10n?.authSyncInProgress);
      }

      if (journal.hasCompletedOnboarding) {
        return const HomeScreen();
      }

      return const OnboardingScreen();
    },
  );
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}