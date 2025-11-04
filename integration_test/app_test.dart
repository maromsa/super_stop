import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_stop/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Allows skipping onboarding and reaching home', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final skipButton = find.text('דלג');
    expect(skipButton, findsOneWidget);

    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    expect(find.text('בחר אתגר'), findsOneWidget);
  });
}

