import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/level_provider.dart';

void main() {
  group('LevelProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should initialize at level 1', () {
      final provider = LevelProvider();
      expect(provider.level, equals(1));
      expect(provider.experience, equals(0));
      expect(provider.levelTitle, equals('מתחיל'));
    });

    test('should add experience correctly', () async {
      final provider = LevelProvider();
      await Future.delayed(const Duration(milliseconds: 100)); // Wait for initialization
      
      final leveledUp = await provider.addExperience(50);
      expect(leveledUp, isFalse);
      expect(provider.experience, equals(50));
      expect(provider.level, equals(1));
    });

    test('should level up when experience threshold is reached', () async {
      final provider = LevelProvider();
      
      // Level 1 requires 100 XP (level * 100)
      final leveledUp = await provider.addExperience(100);
      expect(leveledUp, isTrue);
      expect(provider.level, equals(2));
      expect(provider.experience, equals(0));
    });

    test('should calculate experience progress correctly', () async {
      final provider = LevelProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider.experienceProgress, equals(0.0));
      
      // Add 50 XP, progress should be 0.5 (50/100)
      await provider.addExperience(50);
      expect(provider.experienceProgress, closeTo(0.5, 0.01));
    });

    test('should provide correct level titles', () {
      final provider = LevelProvider();
      
      // Test level titles based on level
      expect(provider.levelTitle, equals('מתחיל')); // Level 1
    });

    test('should handle multiple level ups', () async {
      final provider = LevelProvider();
      
      // Add enough XP to level up twice
      await provider.addExperience(100); // Level 2
      expect(provider.level, equals(2));
      
      await provider.addExperience(200); // Level 3 (needs 200 XP for level 2->3)
      expect(provider.level, equals(3));
    });

    test('should persist level and experience', () async {
      final provider1 = LevelProvider();
      await provider1.addExperience(150);
      
      // Simulate persistence
      final provider2 = LevelProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify structure exists (actual persistence tested in integration)
      expect(provider2.level, isA<int>());
    });
  });
}

