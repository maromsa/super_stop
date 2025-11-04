import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/daily_goals_provider.dart';

void main() {
  group('DailyGoalsProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late DateTime currentTime;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      currentTime = DateTime(2025, 1, 1, 10);
    });

    Future<DailyGoalsProvider> createProvider() async {
      final provider = DailyGoalsProvider(clock: () => currentTime);
      await Future.delayed(Duration.zero);
      return provider;
    }

    test('should initialize with default values and helpers', () async {
      final provider = await createProvider();

      expect(provider.streak, equals(0));
      expect(provider.gamesPlayedToday, equals(0));
      expect(provider.focusMinutesToday, equals(0));
      expect(provider.dailyGoal, equals(3));
      expect(provider.isGoalCompleted, isFalse);
      expect(provider.remainingGames, equals(3));
      expect(provider.gamesProgress, equals(0.0));
    });

    test('should mark game played and increment counters', () async {
      final provider = await createProvider();

      await provider.markGamePlayed();
      expect(provider.gamesPlayedToday, equals(1));
      expect(provider.remainingGames, equals(2));
      expect(provider.gamesProgress, closeTo(1 / 3, 0.0001));

      await provider.markGamePlayed();
      expect(provider.gamesPlayedToday, equals(2));
      expect(provider.remainingGames, equals(1));
    });

    test('should cap progress helpers when exceeding goal', () async {
      final provider = await createProvider();

      for (int i = 0; i < 5; i++) {
        await provider.markGamePlayed();
      }

      expect(provider.gamesPlayedToday, equals(5));
      expect(provider.remainingGames, equals(0));
      expect(provider.gamesProgress, equals(1.0));
      expect(provider.isGoalCompleted, isTrue);
    });

    test('should track focus minutes', () async {
      final provider = await createProvider();

      await provider.completeFocusSession(5);
      expect(provider.focusMinutesToday, equals(5));

      await provider.completeFocusSession(10);
      expect(provider.focusMinutesToday, equals(15));
    });

    test('should allow setting custom daily goal and validate negative', () async {
      final provider = await createProvider();

      await provider.setDailyGoal(5);
      expect(provider.dailyGoal, equals(5));

      expect(provider.remainingGames, equals(5));
      await provider.markGamePlayed();
      expect(provider.remainingGames, equals(4));

      await expectLater(provider.setDailyGoal(-1), throwsArgumentError);
    });

    test('resetDailyProgress should clear counters and optionally streak', () async {
      final provider = await createProvider();

      await provider.setDailyGoal(1);
      await provider.markGamePlayed();
      await provider.completeFocusSession(20);
      expect(provider.gamesPlayedToday, equals(1));
      expect(provider.focusMinutesToday, equals(20));

      await provider.resetDailyProgress();
      expect(provider.gamesPlayedToday, equals(0));
      expect(provider.focusMinutesToday, equals(0));
      expect(provider.streak, equals(1));

      await provider.markGamePlayed();
      expect(provider.streak, equals(1));

      await provider.resetDailyProgress(preserveStreak: false);
      expect(provider.streak, equals(0));
    });

    test('should manage streak across consecutive days when goals met', () async {
      final provider = await createProvider();

      // Day 1: meet daily goal
      await provider.setDailyGoal(2);
      await provider.markGamePlayed();
      await provider.markGamePlayed();
      expect(provider.streak, equals(1));

      // Advance to next day
      currentTime = currentTime.add(const Duration(days: 1, hours: 2));
      await provider.markGamePlayed();
      await provider.markGamePlayed();
      expect(provider.streak, equals(2));

      // Skip a day
      currentTime = currentTime.add(const Duration(days: 2));
      await provider.markGamePlayed();
      expect(provider.streak, equals(1));
    });
  });
}

