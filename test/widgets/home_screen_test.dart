import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/l10n/app_localizations.dart';
import 'package:super_stop/providers/adaptive_focus_challenge_provider.dart';
import 'package:super_stop/providers/boss_battle_provider.dart';
import 'package:super_stop/providers/calm_mode_provider.dart';
import 'package:super_stop/providers/coin_provider.dart';
import 'package:super_stop/providers/collectible_provider.dart';
import 'package:super_stop/providers/community_challenge_provider.dart';
import 'package:super_stop/providers/daily_goals_provider.dart';
import 'package:super_stop/providers/daily_quest_provider.dart';
import 'package:super_stop/providers/habit_story_provider.dart';
import 'package:super_stop/providers/level_provider.dart';
import 'package:super_stop/providers/mood_journal_provider.dart';
import 'package:super_stop/providers/mood_music_mixer_provider.dart';
import 'package:super_stop/providers/mystery_quest_provider.dart';
import 'package:super_stop/providers/social_treasure_provider.dart';
import 'package:super_stop/providers/virtual_companion_provider.dart';
import 'package:super_stop/screens/home_screen.dart';
import 'package:super_stop/services/achievement_service.dart';
import 'package:super_stop/services/firebase_auth_service.dart';
import 'package:super_stop/theme_provider.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

      Widget createTestWidget() {
        return MultiProvider(
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
            ChangeNotifierProvider(create: (_) => FirebaseAuthService(bypassAuth: true)),
            ChangeNotifierProxyProvider<MoodJournalProvider, AdaptiveFocusChallengeProvider>(
              create: (_) => AdaptiveFocusChallengeProvider(),
              update: (_, journal, provider) {
                provider ??= AdaptiveFocusChallengeProvider();
                provider.updateFromMoodJournal(journal);
                return provider;
              },
            ),
          ],
          child: MaterialApp(
            locale: const Locale('he'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        );
      }

      testWidgets('should display home screen with all key elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for main title
        expect(find.text('בחר אתגר'), findsOneWidget);

        // Check for game buttons
        expect(find.text('משחק איפוק'), findsOneWidget);
        expect(find.text('מבחן תגובה'), findsOneWidget);
        expect(find.text('מבחן סטרופ'), findsOneWidget);

        // Check for additional tools
        expect(find.text('כלים נוספים'), findsOneWidget);
        expect(find.text('תרגיל נשימה'), findsOneWidget);
        expect(find.text('טיימר ריכוז'), findsOneWidget);
        expect(find.text('לוח התקדמות'), findsOneWidget);

        // Check for settings and achievements buttons
        expect(find.text('הישגים'), findsWidgets);
        expect(find.text('הגדרות'), findsOneWidget);
      });

    testWidgets('should display level and stats information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for level display (should show "רמה 1" or similar)
      expect(find.textContaining('רמה'), findsWidgets);
      
      // Check for stats badges
      expect(find.byIcon(Icons.local_fire_department), findsWidgets);
      expect(find.byIcon(Icons.flag), findsWidgets);
      expect(find.byIcon(Icons.monetization_on), findsWidgets);
    });

    testWidgets('should navigate to game mode selector on game button tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the impulse control game button (ensure it's visible first)
      final gameButton = find.text('משחק איפוק');
      expect(gameButton, findsOneWidget);

      await tester.ensureVisible(gameButton);
      await tester.tap(gameButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should show mode selector dialog
      expect(find.text('בחר צורת משחק'), findsOneWidget);
    });

    testWidgets('should show help dialog when help button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find help button using tooltip text
      final helpButton = find.byTooltip('איך משחקים?');
      expect(helpButton, findsOneWidget);

      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      // Should show instructions dialog
      expect(find.text('איך משחקים?'), findsOneWidget);
    });
  });
}

