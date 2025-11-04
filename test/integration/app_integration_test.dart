import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/main.dart' as app;

Future<void> _launchAndReachHome(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));

  Finder skipButton = find.text('דלג');
  if (skipButton.evaluate().isEmpty) {
    skipButton = find.text('Skip');
  }

  if (skipButton.evaluate().isNotEmpty) {
    await tester.tap(skipButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  // Give providers time to load home data
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('app should start and display home screen', (WidgetTester tester) async {
      await _launchAndReachHome(tester);

      final hasHebrewTitle = find.text('בחר אתגר').evaluate().isNotEmpty;
      final hasEnglishTitle = find.text('Choose a challenge').evaluate().isNotEmpty;
      final hasGames = find.text('משחק איפוק').evaluate().isNotEmpty ||
          find.text('Impulse Control Game').evaluate().isNotEmpty;

      expect(hasHebrewTitle || hasEnglishTitle || hasGames, isTrue, reason: 'Home screen should display');
    });

    testWidgets('verify stats widgets are present', (WidgetTester tester) async {
      await _launchAndReachHome(tester);

      final hasStats = find.byIcon(Icons.local_fire_department).evaluate().isNotEmpty ||
          find.byIcon(Icons.flag).evaluate().isNotEmpty ||
          find.byIcon(Icons.monetization_on).evaluate().isNotEmpty;

      expect(hasStats, isTrue, reason: 'Stats should be displayed');
    });
  });
}

