import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/daily_goals_provider.dart';

void main() {
  group('DailyGoalsProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should initialize with default values', () {
      final provider = DailyGoalsProvider();
      expect(provider.streak, equals(0));
      expect(provider.gamesPlayedToday, equals(0));
      expect(provider.focusMinutesToday, equals(0));
      expect(provider.dailyGoal, equals(3));
      expect(provider.isGoalCompleted, isFalse);
    });

    test('should mark game played and increment counter', () async {
      final provider = DailyGoalsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      await provider.markGamePlayed();
      expect(provider.gamesPlayedToday, equals(1));
      
      await provider.markGamePlayed();
      expect(provider.gamesPlayedToday, equals(2));
    });

    test('should track focus minutes', () async {
      final provider = DailyGoalsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      await provider.completeFocusSession(5);
      expect(provider.focusMinutesToday, equals(5));
      
      await provider.completeFocusSession(10);
      expect(provider.focusMinutesToday, equals(15));
    });

    test('should detect goal completion', () async {
      final provider = DailyGoalsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(provider.isGoalCompleted, isFalse);
      
      await provider.markGamePlayed();
      await provider.markGamePlayed();
      expect(provider.isGoalCompleted, isFalse);
      
      await provider.markGamePlayed();
      expect(provider.isGoalCompleted, isTrue);
    });

    test('should allow setting custom daily goal', () async {
      final provider = DailyGoalsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      await provider.setDailyGoal(5);
      expect(provider.dailyGoal, equals(5));
      expect(provider.isGoalCompleted, isFalse);
      
      // Play 5 games
      for (int i = 0; i < 5; i++) {
        await provider.markGamePlayed();
      }
      expect(provider.isGoalCompleted, isTrue);
    });

    test('should track games played', () async {
      final provider = DailyGoalsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // First game
      await provider.markGamePlayed();
      expect(provider.gamesPlayedToday, equals(1));
      expect(provider.streak, isA<int>());
    });
  });
}

