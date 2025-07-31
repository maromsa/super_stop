import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Make sure to import your app's main entry point and the screen
import 'package:super_stop/main.dart' as app;
import 'package:super_stop/screens/impulse_control_game_screen.dart';

void main() {
  // Ensure the integration test bindings are initialized
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Impulse Control Game Screen Tests', () {

    testWidgets('Test Case 1: User clicks too early and sees failure message',
            (WidgetTester tester) async {
          // Start the app
          app.main();
          await tester.pumpAndSettle(); // Wait for app to load

          // For this test, let's assume you navigate to the game screen.
          // If the game screen is the home screen, you can skip this part.
          // Example of navigation:
          // await tester.tap(find.text('Go to Impulse Game'));
          // await tester.pumpAndSettle();

          // Find the start button
          final startButton = find.widgetWithText(ElevatedButton, 'התחל');
          expect(startButton, findsOneWidget);

          // Tap the start button
          await tester.tap(startButton);
          await tester.pump(); // Let the state update to 'waiting'

          // The button text should now be "...המתן..."
          expect(find.text('...המתן...'), findsOneWidget);

          // Tap immediately again (too early)
          await tester.tap(find.widgetWithText(ElevatedButton, '...המתן...'));
          await tester.pumpAndSettle(); // Wait for UI to update after the early tap

          // Check for the failure message
          expect(find.text('עצור! לחצת מוקדם מדי, נסה שוב'), findsOneWidget);

          // The button should now say "שחק שוב"
          expect(find.widgetWithText(ElevatedButton, 'שחק שוב'), findsOneWidget);
        });

    testWidgets('Test Case 2: User waits 5 seconds and sees success message',
            (WidgetTester tester) async {
          // Start the app
          app.main();
          await tester.pumpAndSettle();

          // Find and tap the start button
          final startButton = find.widgetWithText(ElevatedButton, 'התחל');
          await tester.tap(startButton);
          await tester.pump(); // Let state update

          // Verify we are in the waiting state
          expect(find.text('...המתן...'), findsOneWidget);

          // *** This is the crucial part ***
          // We wait for 6 seconds, which is longer than the game's timer.
          // This simulates a patient user.
          await tester.pump(const Duration(seconds: 6));

          // After 6 seconds, the timer should have fired and updated the state.
          // Check for the success message.
          expect(find.text('כל הכבוד! הצלחת לעצור בזמן!'), findsOneWidget);

          // The button should now say "שחק שוב"
          expect(find.widgetWithText(ElevatedButton, 'שחק שוב'), findsOneWidget);
        });
  });
}