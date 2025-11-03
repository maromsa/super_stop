import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/services/achievement_service.dart';
import 'package:super_stop/models/achievement.dart';

void main() {
  group('AchievementService', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should initialize with all achievements', () {
      final service = AchievementService();
      expect(service.achievements.length, greaterThanOrEqualTo(10));
    });

    test('should have achievements with required properties', () {
      final service = AchievementService();
      
      for (final achievement in service.achievements) {
        expect(achievement.id, isNotEmpty);
        expect(achievement.isUnlocked, isA<bool>());
      }
    });

    test('unlockAchievement should set isUnlocked to true', () async {
      final service = AchievementService();
      await Future.delayed(Duration.zero);

      final achievement = service.achievements.firstWhere(
        (ach) => ach.id == 'impulse_score_10',
      );

      expect(achievement.isUnlocked, isFalse);
      
      await service.unlockAchievement('impulse_score_10');
      expect(achievement.isUnlocked, isTrue);
    });

    test('unlockAchievement should return null if already unlocked', () async {
      final service = AchievementService();
      await Future.delayed(Duration.zero);

      await service.unlockAchievement('impulse_score_10');
      final result = await service.unlockAchievement('impulse_score_10');
      
      expect(result, isNull);
    });

    test('unlockAchievement should return achievement id when unlocked', () async {
      final service = AchievementService();
      await Future.delayed(Duration.zero);

      final result = await service.unlockAchievement('impulse_score_10');
      expect(result, equals('impulse_score_10'));
    });

    test('markGamePlayed should unlock Trifecta achievement when all games are played', () async {
      final service = AchievementService();
      await Future.delayed(Duration.zero);

      final trifectaAchievement = service.achievements.firstWhere(
        (ach) => ach.id == 'play_all_three',
      );

      await service.markGamePlayed('impulse');
      await service.markGamePlayed('reaction');
      expect(trifectaAchievement.isUnlocked, isFalse);

      final result = await service.markGamePlayed('stroop');
      expect(trifectaAchievement.isUnlocked, isTrue);
      expect(result, equals('play_all_three'));
    });

    test('getAchievement should return correct achievement', () {
      final service = AchievementService();
      
      final achievement = service.getAchievement('impulse_score_10');
      expect(achievement, isNotNull);
      expect(achievement?.id, equals('impulse_score_10'));
    });

    test('getAchievement should return null for invalid id', () {
      final service = AchievementService();
      
      final achievement = service.getAchievement('invalid_id');
      expect(achievement, isNull);
    });

    test('should have achievements with emojis and colors', () {
      final service = AchievementService();
      
      for (final achievement in service.achievements) {
        // Check that new achievements have emoji and color
        if (achievement.id.startsWith('streak') || 
            achievement.id.startsWith('focus') ||
            achievement.id.startsWith('coin') ||
            achievement.id.startsWith('breathing')) {
          expect(achievement.emoji, isNotNull);
          expect(achievement.color, isNotNull);
        }
      }
    });
  });
}

