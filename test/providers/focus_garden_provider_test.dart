import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/focus_garden_provider.dart';
import 'package:super_stop/utils/prefs_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FocusGardenProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = FocusGardenProvider();
  });

  Future<void> _waitForLoad() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  group('FocusGardenProvider', () {
    test('initializes with default state', () async {
      await _waitForLoad();
      expect(provider.isLoaded, isTrue);
      expect(provider.growthPoints, equals(0));
      expect(provider.totalFocusMinutes, equals(0));
      expect(provider.dewDrops, equals(0));
      expect(provider.totalBreathingCycles, equals(0));
      expect(provider.wateringsToday, equals(0));
      expect(provider.currentStage.id, FocusGardenStageId.seed);
    });

    test('registerFocusSession adds sunlight and can level up', () async {
      await _waitForLoad();
      final update = await provider.registerFocusSession(20); // 20 * 5 = 100 sunlight

      expect(update.sunlightEarned, equals(100));
      expect(provider.growthPoints, equals(100));
      expect(provider.totalFocusMinutes, equals(20));
      expect(provider.currentStage.id, FocusGardenStageId.sprout);
      expect(update.stageLeveledUp, isTrue);
      expect(update.rewardCoins, greaterThan(0));
    });

    test('registerBreathingPractice awards dew drops', () async {
      await _waitForLoad();
      final update = await provider.registerBreathingPractice(cycles: 6);

      expect(update.dewEarned, equals(2));
      expect(provider.dewDrops, equals(2));
      expect(provider.totalBreathingCycles, equals(6));
    });

    test('applyDewBoost spends dew and adds growth', () async {
      await _waitForLoad();
      await provider.registerBreathingPractice(cycles: 9); // 3 dew

      final update = await provider.applyDewBoost();

      expect(update.dewSpent, equals(1));
      expect(update.sunlightEarned, equals(FocusGardenProvider.growthPerDew));
      expect(provider.dewDrops, equals(2));
      expect(provider.wateringsToday, equals(1));
    });

    test('applyDewBoost respects daily limit', () async {
      await _waitForLoad();
      await provider.registerBreathingPractice(cycles: 20); // plenty of dew

      await provider.applyDewBoost();
      await provider.applyDewBoost();
      await provider.applyDewBoost();
      final update = await provider.applyDewBoost();

      expect(provider.wateringsToday, equals(FocusGardenProvider.maxDailyWaterings));
      expect(update.dewSpent, equals(0));
      expect(update.stageLeveledUp, isFalse);
    });

    test('daily reset clears watering counter on new day', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        PrefsKeys.focusGardenState: jsonEncode({
          'growthPoints': 120,
          'totalFocusMinutes': 30,
          'dewDrops': 2,
          'totalBreathingCycles': 9,
          'wateringsToday': 2,
          'lastDailyResetIso': yesterday.toIso8601String(),
          'lastWateredIso': yesterday.toIso8601String(),
        }),
      });

      provider = FocusGardenProvider();
      await _waitForLoad();

      expect(provider.wateringsToday, equals(0));
      expect(provider.lastWatered, isNotNull);
    });
  });
}

