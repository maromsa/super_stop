import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/mini_game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('completing mini game once rewards coins and streak increments', () async {
    var now = DateTime(2025, 1, 1);
    final provider = MiniGameProvider(clock: () => now);

    await provider.prepareForBreak();
    final result = await provider.completeCurrentMiniGame();

    expect(result.wasFirstCompletionToday, isTrue);
    expect(result.rewardCoins, greaterThan(0));
    expect(provider.streak, 1);
    expect(provider.completedToday, isTrue);
  });

  test('second completion on same day does not grant additional rewards', () async {
    var now = DateTime(2025, 1, 2);
    final provider = MiniGameProvider(clock: () => now);

    await provider.prepareForBreak();
    await provider.completeCurrentMiniGame();

    final secondAttempt = await provider.completeCurrentMiniGame();

    expect(secondAttempt.wasFirstCompletionToday, isFalse);
    expect(secondAttempt.rewardCoins, 0);
    expect(provider.streak, 1);
  });

  test('streak progression unlocks cosmetic badges', () async {
    var now = DateTime(2025, 1, 3);
    final provider = MiniGameProvider(clock: () => now);

    String? badgeId;
    for (var day = 0; day < 7; day++) {
      await provider.prepareForBreak();
      final result = await provider.completeCurrentMiniGame();
      if (result.unlockedBadgeId != null) {
        badgeId = result.unlockedBadgeId;
      }
      now = now.add(const Duration(days: 1));
    }

    expect(provider.streak, greaterThanOrEqualTo(7));
    expect(badgeId, anyOf('mini_badge_bronze', 'mini_badge_silver', 'mini_badge_gold'));
  });

  test('daily mini game rotates even without completing previous day', () async {
    var now = DateTime(2025, 1, 10);
    final provider = MiniGameProvider(clock: () => now);

    await provider.prepareForBreak();
    final firstGameId = provider.currentMiniGame.id;

    now = now.add(const Duration(days: 1));
    await provider.prepareForBreak();
    final nextGameId = provider.currentMiniGame.id;

    expect(nextGameId, isNot(equals(firstGameId)));
    expect(provider.completedToday, isFalse);
  });
}
