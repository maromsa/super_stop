import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/models/achievement.dart'; // Make sure this path is correct for your project
import 'package:super_stop/services/achievement_service.dart'; // Make sure this path is correct

void main() {
  group('AchievementService', () {

    // This is needed to make SharedPreferences work in tests
    TestWidgetsFlutterBinding.ensureInitialized();

    test('unlockAchievement should set isUnlocked to true', () async {
      SharedPreferences.setMockInitialValues({});

      final achievementService = AchievementService();
      // The service automatically loads achievements in its constructor,
      // so we wait a moment for it to complete.
      await Future.delayed(Duration.zero);

      final achievementToTest = achievementService.achievements.firstWhere(
              (ach) => ach.id == 'impulse_score_10'
      );

      await achievementService.unlockAchievement('impulse_score_10');

      expect(achievementToTest.isUnlocked, isTrue);
    });

    test('markGamePlayed should unlock Trifecta achievement when all games are played', () async {
      SharedPreferences.setMockInitialValues({});
      final achievementService = AchievementService();
      await Future.delayed(Duration.zero);

      final trifectaAchievement = achievementService.achievements.firstWhere(
              (ach) => ach.id == 'play_all_three'
      );

      await achievementService.markGamePlayed('impulse');
      await achievementService.markGamePlayed('reaction');
      expect(trifectaAchievement.isUnlocked, isFalse);

      await achievementService.markGamePlayed('stroop');
      expect(trifectaAchievement.isUnlocked, isTrue);
    });
  });
}