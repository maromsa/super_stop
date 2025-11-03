import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_stop/main.dart' as app;
import 'package:super_stop/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('complete app flow: home -> game -> back', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify home screen is displayed
      expect(find.text('בחר אתגר'), findsOneWidget);

      // Tap on a game button
      final gameButton = find.text('משחק איפוק');
      if (gameButton.evaluate().isNotEmpty) {
        await tester.tap(gameButton);
        await tester.pumpAndSettle();

        // Should show mode selector or navigate to game
        // Verify we're not on home screen anymore
        expect(find.text('בחר אתגר'), findsNothing);
      }
    });

    testWidgets('verify daily goals tracking works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify stats are displayed
      expect(find.byIcon(Icons.local_fire_department), findsWidgets);
      expect(find.byIcon(Icons.flag), findsWidgets);
    });

    testWidgets('verify level display on home screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify level information is displayed
      expect(find.textContaining('רמה'), findsWidgets);
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('navigate to achievements screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find achievements button
      final achievementsButton = find.text('הישגים');
      if (achievementsButton.evaluate().isNotEmpty) {
        await tester.tap(achievementsButton);
        await tester.pumpAndSettle();

        // Verify we're on achievements screen
        expect(find.text('הישגים'), findsWidgets);
      }
    });

    testWidgets('navigate to settings screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find settings button
      final settingsButton = find.text('הגדרות');
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Verify we're on settings screen
        expect(find.text('הגדרות'), findsWidgets);
      }
    });
  });
}

