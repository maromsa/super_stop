import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_stop/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check if emotion screen shows', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('איך אתה מרגיש עכשיו?'), findsOneWidget);
    expect(find.text('😄 שמח'), findsOneWidget);
  });
}

