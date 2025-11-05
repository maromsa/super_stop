import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/models/mood_entry.dart';
import 'package:super_stop/theme_provider.dart';

Future<void> pump() async => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('applyMoodTheme unlocks and persists mood themes', () async {
    final provider = ThemeProvider();
    await pump();

    expect(provider.activeMood, Mood.calm);
    expect(provider.unlockedMoods.contains(Mood.calm), isTrue);

    await provider.applyMoodTheme(Mood.excited);
    expect(provider.activeMood, Mood.excited);
    expect(provider.unlockedMoods.contains(Mood.excited), isTrue);

    final restored = ThemeProvider();
    await pump();
    expect(restored.activeMood, Mood.excited);
  });
}
