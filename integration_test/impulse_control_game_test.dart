import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_stop/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Impulse Control Game Screen initial state', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text("לחץ על 'התחל' כדי לשחק"), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('התחל'), findsOneWidget);
  });
}

