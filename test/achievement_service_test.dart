import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/models/achievement.dart';
import 'package:super_stop/services/achievement_service.dart';

void main() {
  group('AchievementService', () {

    test('unlockAchievement should set isUnlocked to true', () async {
      // Setup: Create a fake in-memory storage
      SharedPreferences.setMockInitialValues({});

      // Arrange: Create an instance of our service
      final achievementService = AchievementService();
      // Wait for the service to load the (empty) achievements
      await achievementService.loadAchievements();

      // Find the achievement we want to test
      final achievementToTest = achievementService.achievements.firstWhere(
              (ach) => ach.id == 'impulse_score_10'
      );

      // Act: Call the method we want to test
      await achievementService.unlockAchievement('impulse_score_10');

      // Assert: Check if the result is what we expect
      expect(achievementToTest.isUnlocked, isTrue);
    });

    test('markGamePlayed should unlock Trifecta achievement when all games are played', () async {
      // Setup
      SharedPreferences.setMockInitialValues({});
      final achievementService = AchievementService();
      await achievementService.loadAchievements();

      final trifectaAchievement = achievementService.achievements.firstWhere(
              (ach) => ach.id == 'play_all_three'
      );

      // Act
      await achievementService.markGamePlayed('impulse');
      await achievementService.markGamePlayed('reaction');
      // At this point, the trifecta should still be locked
      expect(trifectaAchievement.isUnlocked, isFalse);

      await achievementService.markGamePlayed('stroop');
      // After playing the third game, it should be unlocked

      // Assert
      expect(trifectaAchievement.isUnlocked, isTrue);
    });
  });
}