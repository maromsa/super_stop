import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/l10n/app_localizations.dart';
import 'package:super_stop/providers/coin_provider.dart';
import 'package:super_stop/providers/daily_goals_provider.dart';
import 'package:super_stop/providers/level_provider.dart';
import 'package:super_stop/providers/mood_journal_provider.dart';
import 'package:super_stop/screens/home_screen.dart';
import 'package:super_stop/services/achievement_service.dart';
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
            ChangeNotifierProvider(create: (_) => DailyGoalsProvider()),
            ChangeNotifierProvider(create: (_) => LevelProvider()),
            ChangeNotifierProvider(create: (_) => MoodJournalProvider()),
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
      expect(find.text('הישגים'), findsOneWidget);
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

      // Find and tap the impulse control game button
      final gameButton = find.text('משחק איפוק');
      expect(gameButton, findsOneWidget);
      
      await tester.tap(gameButton);
      await tester.pumpAndSettle();

      // Should show mode selector dialog
      expect(find.text('בחר צורת משחק'), findsOneWidget);
    });

    testWidgets('should show help dialog when help button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find help button
      final helpButton = find.byIcon(Icons.help_outline);
      expect(helpButton, findsOneWidget);

      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      // Should show instructions dialog
      expect(find.text('איך משחקים?'), findsOneWidget);
    });
  });
}

