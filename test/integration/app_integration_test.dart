import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_stop/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

      Future<void> launchAndReachHome(WidgetTester tester) async {
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
      }

      testWidgets('app should start and display home screen', (WidgetTester tester) async {
        await launchAndReachHome(tester);

      // Verify home screen is displayed (check for key elements)
      // The home screen should have at least one of these elements
      final hasTitle = find.text('בחר אתגר').evaluate().isNotEmpty;
      final hasGames = find.text('משחק איפוק').evaluate().isNotEmpty || 
                      find.text('מבחן תגובה').evaluate().isNotEmpty;
      
      // At least one key element should be present
      expect(hasTitle || hasGames, isTrue, reason: 'Home screen should display');
    });

    testWidgets('verify stats widgets are present', (WidgetTester tester) async {
        await launchAndReachHome(tester);

      // Verify stats icons are displayed (at least one should be present)
      final hasStats = find.byIcon(Icons.local_fire_department).evaluate().isNotEmpty ||
                      find.byIcon(Icons.flag).evaluate().isNotEmpty ||
                      find.byIcon(Icons.monetization_on).evaluate().isNotEmpty;
      
      expect(hasStats, isTrue, reason: 'Stats should be displayed');
    });
  });
}

