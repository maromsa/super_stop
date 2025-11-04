import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/models/mood_entry.dart';
import 'package:super_stop/providers/mood_journal_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MoodJournalProvider', () {
    late DateTime currentTime;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      currentTime = DateTime(2025, 1, 1, 10);
    });

    Future<MoodJournalProvider> createProvider() async {
      final provider = MoodJournalProvider(clock: () => currentTime);
      await Future.delayed(Duration.zero);
      expect(provider.isReady, isTrue);
      return provider;
    }

    test('initial state is empty and onboarding pending', () async {
      final provider = await createProvider();
      expect(provider.entries, isEmpty);
      expect(provider.hasCompletedOnboarding, isFalse);
      expect(provider.hasCheckInToday, isFalse);
    });

    test('recordMood stores entry, updates check-in state, and trims history', () async {
      final provider = await createProvider();

      await provider.recordMood(Mood.happy);
      expect(provider.entries.length, equals(1));
      expect(provider.latestEntry?.mood, equals(Mood.happy));
      expect(provider.hasCheckInToday, isTrue);

      currentTime = currentTime.add(const Duration(days: 1));
      await provider.recordMood(Mood.sad);
      expect(provider.entries.length, equals(2));
      expect(provider.latestEntry?.mood, equals(Mood.sad));
      expect(provider.hasCheckInToday, isTrue);
    });

    test('recentMoodDistribution counts moods within timeframe', () async {
      final provider = await createProvider();

      await provider.recordMood(Mood.happy);
      currentTime = currentTime.add(const Duration(days: 3));
      await provider.recordMood(Mood.angry);

      final distribution = provider.recentMoodDistribution(days: 7);
      expect(distribution[Mood.happy], equals(1));
      expect(distribution[Mood.angry], equals(1));
    });

    test('markOnboardingComplete persists state', () async {
      final provider = await createProvider();
      await provider.markOnboardingComplete();
      expect(provider.hasCompletedOnboarding, isTrue);

      final secondProvider = MoodJournalProvider(clock: () => currentTime);
      await Future.delayed(Duration.zero);
      expect(secondProvider.hasCompletedOnboarding, isTrue);
    });

    test('resetJournal clears entries and check-in time', () async {
      final provider = await createProvider();
      await provider.recordMood(Mood.calm);
      expect(provider.entries, isNotEmpty);

      await provider.resetJournal();
      expect(provider.entries, isEmpty);
      expect(provider.hasCheckInToday, isFalse);
    });
  });
}
