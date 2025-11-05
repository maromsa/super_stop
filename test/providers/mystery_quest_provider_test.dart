import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/models/mood_entry.dart';
import 'package:super_stop/providers/coin_provider.dart';
import 'package:super_stop/providers/mystery_quest_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('provider generates three daily quests', () async {
    final provider = MysteryQuestProvider(clock: () => DateTime(2025, 1, 10));
    await Future<void>.delayed(Duration.zero);

    expect(provider.activeQuests, hasLength(3));
    expect(provider.isLoaded, isTrue);
  });

  test('registering activity progresses quests and claims reward', () async {
    final provider = MysteryQuestProvider(clock: () => DateTime(2025, 2, 5));
    final coinProvider = CoinProvider();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final moodQuest = provider.activeQuests.firstWhere((q) => q.type == QuestType.mood);
    for (var i = 0; i < moodQuest.goal; i++) {
      provider.registerMoodEntry(Mood.happy);
    }

    expect(moodQuest.isCompleted, isTrue);
    final claimed = provider.claimReward(moodQuest.id, coinProvider);
    expect(claimed, isNotNull);
    expect(coinProvider.coins, claimed!.rewardCoins);
  });
}
