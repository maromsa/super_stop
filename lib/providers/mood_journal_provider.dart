import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';
import '../utils/prefs_keys.dart';

class MoodJournalProvider with ChangeNotifier {
  MoodJournalProvider({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;
  final List<MoodEntry> _entries = <MoodEntry>[];
  bool _onboardingCompleted = false;
  DateTime? _lastCheckIn;
  bool _isReady = false;

  List<MoodEntry> get entries => List.unmodifiable(_entries);
  bool get hasEntries => _entries.isNotEmpty;
  MoodEntry? get latestEntry => _entries.isEmpty ? null : _entries.last;
  bool get hasCompletedOnboarding => _onboardingCompleted;
  bool get isReady => _isReady;

  bool get hasCheckInToday {
    if (_lastCheckIn == null) {
      return false;
    }
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final checkInDay = DateTime(_lastCheckIn!.year, _lastCheckIn!.month, _lastCheckIn!.day);
    return today.isAtSameMomentAs(checkInDay);
  }

  Future<void> recordMood(Mood mood) async {
    final prefs = await SharedPreferences.getInstance();
    final now = _clock();
    final entry = MoodEntry(mood: mood, timestamp: now);
    _entries.add(entry);
    while (_entries.length > 60) {
      _entries.removeAt(0);
    }
    _lastCheckIn = now;
    await prefs.setString(PrefsKeys.moodEntries, MoodEntry.encodeList(_entries));
    await prefs.setString(PrefsKeys.lastMoodCheckIn, now.toIso8601String());
    notifyListeners();
  }

  Map<Mood, int> recentMoodDistribution({int days = 7}) {
    final cutoff = _clock().subtract(Duration(days: days));
    final counts = <Mood, int>{for (final mood in Mood.values) mood: 0};
    for (final entry in _entries.where((entry) => entry.timestamp.isAfter(cutoff))) {
      counts.update(entry.mood, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = true;
    await prefs.setBool(PrefsKeys.onboardingCompleted, true);
    notifyListeners();
  }

  Future<void> resetJournal() async {
    final prefs = await SharedPreferences.getInstance();
    _entries.clear();
    _lastCheckIn = null;
    await prefs.remove(PrefsKeys.moodEntries);
    await prefs.remove(PrefsKeys.lastMoodCheckIn);
    notifyListeners();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = prefs.getBool(PrefsKeys.onboardingCompleted) ?? false;

    final encodedEntries = prefs.getString(PrefsKeys.moodEntries);
    if (encodedEntries != null && encodedEntries.isNotEmpty) {
      _entries
        ..clear()
        ..addAll(MoodEntry.decodeList(encodedEntries)..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
    }

    final lastCheckInString = prefs.getString(PrefsKeys.lastMoodCheckIn);
    if (lastCheckInString != null) {
      _lastCheckIn = DateTime.tryParse(lastCheckInString);
    }

    _isReady = true;
    notifyListeners();
  }
}
