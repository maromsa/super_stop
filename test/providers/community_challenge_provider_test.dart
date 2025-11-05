import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/coin_provider.dart';
import 'package:super_stop/providers/community_challenge_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('contributions update progress and personal totals', () async {
    final provider = CommunityChallengeProvider(clock: () => DateTime(2025, 3, 1));
    await Future<void>.delayed(Duration.zero);

    provider.registerGameContribution(games: 2);
    final challenge = provider.getChallenge('challenge_arcade');

    expect(challenge, isNotNull);
    expect(challenge!.progress, greaterThan(0));
    expect(challenge.personalContribution, greaterThan(0));
  });

  test('coin contributions spend coins and boost progress', () async {
    final provider = CommunityChallengeProvider(clock: () => DateTime(2025, 3, 2));
    final coinProvider = CoinProvider();
    await Future<void>.delayed(Duration.zero);
    await coinProvider.setCoins(20);

    final success = provider.contributeCoins('challenge_focus', coinProvider, coins: 5);
    expect(success, isTrue);
    expect(coinProvider.coins, 15);

    final challenge = provider.getChallenge('challenge_focus');
    expect(challenge!.progress, greaterThan(0));
  });

  test('claiming rewards grants coins when completed', () async {
    final provider = CommunityChallengeProvider(clock: () => DateTime(2025, 3, 3));
    final coinProvider = CoinProvider();
    await Future<void>.delayed(Duration.zero);
    await coinProvider.setCoins(0);

    final challenge = provider.getChallenge('challenge_mood')!;
    challenge.progress = challenge.target;

    final claimed = provider.claimReward(challenge.id, coinProvider);
    expect(claimed, isTrue);
    expect(coinProvider.coins, challenge.rewardCoins);
    expect(challenge.claimed, isTrue);
  });
}
