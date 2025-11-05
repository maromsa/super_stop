import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/ambient_mix_provider.dart';

Future<void> pumpMicrotasks() async => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults load with expected tracks', () async {
    final provider = AmbientMixProvider();
    await pumpMicrotasks();

    expect(provider.focusTrack, 'tick.mp3');
    expect(provider.breakTrack, isNotEmpty);
    expect(provider.completeTrack, isNotEmpty);
    expect(provider.presets, isNotEmpty);
  });

  test('updating tracks clears selected preset', () async {
    final provider = AmbientMixProvider();
    await pumpMicrotasks();

    expect(provider.selectedPreset, isNotNull);
    await provider.updateFocusTrack('success.mp3');
    expect(provider.focusTrack, 'success.mp3');
    expect(provider.selectedPreset, isNull);
  });

  test('saving and loading presets works', () async {
    final provider = AmbientMixProvider();
    await pumpMicrotasks();

    await provider.updateFocusTrack('failure.mp3');
    await provider.updateBreakTrack('tick.mp3');
    await provider.savePreset('היפוך');

    expect(provider.presets.any((preset) => preset.name == 'היפוך'), isTrue);
    expect(provider.selectedPreset, 'היפוך');

    await provider.updateFocusTrack('success.mp3');
    await provider.loadPreset('היפוך');
    expect(provider.focusTrack, 'failure.mp3');
  });
}
