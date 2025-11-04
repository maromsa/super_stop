import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/prefs_keys.dart';

class DailyGoalsProvider with ChangeNotifier {
  int _streak = 0;
  int _gamesPlayedToday = 0;
  int _focusMinutesToday = 0;
  int _dailyGoal = 3; // Default: 3 games per day
  DateTime? _lastActivityDate;
  bool _goalMetPreviousDay = false;
  final DateTime Function() _clock;
  final List<int> _weeklyGames = List<int>.filled(7, 0, growable: true);
  final List<int> _weeklyFocus = List<int>.filled(7, 0, growable: true);

  int get streak => _streak;
  int get gamesPlayedToday => _gamesPlayedToday;
  int get focusMinutesToday => _focusMinutesToday;
  int get dailyGoal => _dailyGoal;
  bool get isGoalCompleted => _gamesPlayedToday >= _dailyGoal;
  List<int> get weeklyGames => List.unmodifiable(_weeklyGames);
  List<int> get weeklyFocusMinutes => List.unmodifiable(_weeklyFocus);
  int get totalWeeklyGames => _weeklyGames.fold(0, (sum, value) => sum + value);
  int get totalWeeklyFocusMinutes => _weeklyFocus.fold(0, (sum, value) => sum + value);
  int get remainingGames {
    final remaining = _dailyGoal - _gamesPlayedToday;
    if (remaining < 0) {
      return 0;
    }
    return remaining;
  }
  double get gamesProgress {
    if (_dailyGoal <= 0) {
      return 1.0;
    }
    final ratio = _gamesPlayedToday / _dailyGoal;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  DailyGoalsProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _loadData();
    _checkDateReset();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _streak = prefs.getInt(PrefsKeys.dailyStreak) ?? 0;
    _gamesPlayedToday = prefs.getInt(PrefsKeys.gamesPlayedToday) ?? 0;
    _focusMinutesToday = prefs.getInt(PrefsKeys.focusMinutesToday) ?? 0;
    _dailyGoal = prefs.getInt(PrefsKeys.dailyGoalGames) ?? 3;
    
    final weeklyGamesStrings = prefs.getStringList(PrefsKeys.weeklyGames);
    if (weeklyGamesStrings != null && weeklyGamesStrings.isNotEmpty) {
      _weeklyGames
        ..clear()
        ..addAll(weeklyGamesStrings.map((value) => int.tryParse(value) ?? 0));
      while (_weeklyGames.length < 7) {
        _weeklyGames.insert(0, 0);
      }
      while (_weeklyGames.length > 7) {
        _weeklyGames.removeAt(0);
      }
    }

    final weeklyFocusStrings = prefs.getStringList(PrefsKeys.weeklyFocus);
    if (weeklyFocusStrings != null && weeklyFocusStrings.isNotEmpty) {
      _weeklyFocus
        ..clear()
        ..addAll(weeklyFocusStrings.map((value) => int.tryParse(value) ?? 0));
      while (_weeklyFocus.length < 7) {
        _weeklyFocus.insert(0, 0);
      }
      while (_weeklyFocus.length > 7) {
        _weeklyFocus.removeAt(0);
      }
    }

    final lastDateString = prefs.getString(PrefsKeys.lastActivityDate);
    if (lastDateString != null) {
      _lastActivityDate = DateTime.parse(lastDateString);
    }
    
    notifyListeners();
  }

  Future<bool> _checkDateReset() async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastActivityDate == null) {
      return false;
    }

    final lastDate = DateTime(
      _lastActivityDate!.year,
      _lastActivityDate!.month,
      _lastActivityDate!.day,
    );

    if (!today.isAfter(lastDate)) {
      return false;
    }

    final dayGap = today.difference(lastDate).inDays;
    final metGoalYesterday = _gamesPlayedToday >= _dailyGoal && _dailyGoal > 0;

    _recordDailySnapshot(
      games: _gamesPlayedToday,
      focusMinutes: _focusMinutesToday,
      dayGap: dayGap,
    );

    if (dayGap == 1) {
      if (metGoalYesterday) {
        _goalMetPreviousDay = true;
      } else {
        _streak = 0;
        _goalMetPreviousDay = false;
      }
    } else {
      _streak = 0;
      _goalMetPreviousDay = false;
    }

    _gamesPlayedToday = 0;
    _focusMinutesToday = 0;
    _lastActivityDate = today;
    await _saveData();
    return true;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.dailyStreak, _streak);
    await prefs.setInt(PrefsKeys.gamesPlayedToday, _gamesPlayedToday);
    await prefs.setInt(PrefsKeys.focusMinutesToday, _focusMinutesToday);
    await prefs.setInt(PrefsKeys.dailyGoalGames, _dailyGoal);
    await prefs.setStringList(
      PrefsKeys.weeklyGames,
      _weeklyGames.map((value) => value.toString()).toList(),
    );
    await prefs.setStringList(
      PrefsKeys.weeklyFocus,
      _weeklyFocus.map((value) => value.toString()).toList(),
    );

    if (_lastActivityDate != null) {
      await prefs.setString(PrefsKeys.lastActivityDate, _lastActivityDate!.toIso8601String());
    }

    notifyListeners();
  }

  Future<void> markGamePlayed() async {
    final didResetForNewDay = await _checkDateReset();

    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastActivityDate == null) {
      _lastActivityDate = today;
    } else {
      final lastDate = DateTime(
        _lastActivityDate!.year,
        _lastActivityDate!.month,
        _lastActivityDate!.day,
      );

      if (today.isAfter(lastDate) && !didResetForNewDay) {
        _goalMetPreviousDay = false;
        _gamesPlayedToday = 0;
        _lastActivityDate = today;
      }
    }

    _gamesPlayedToday++;

    if (_streak == 0) {
      _streak = 1;
    }

    if (_dailyGoal > 0 && _gamesPlayedToday == _dailyGoal) {
      if (_goalMetPreviousDay) {
        _streak = _streak == 0 ? 1 : _streak + 1;
      } else {
        _streak = 1;
      }
      _goalMetPreviousDay = true;
    }

    await _saveData();
  }

  Future<void> completeFocusSession(int minutes) async {
    await _checkDateReset();
    _focusMinutesToday += minutes;
    await _saveData();
  }

  Future<void> setDailyGoal(int goal) async {
    if (goal < 0) {
      throw ArgumentError.value(goal, 'goal', 'Daily goal cannot be negative.');
    }
    _dailyGoal = goal;
    _goalMetPreviousDay = false;
    await _saveData();
  }

  Future<void> resetDailyProgress({bool preserveStreak = true}) async {
    _gamesPlayedToday = 0;
    _focusMinutesToday = 0;
    if (!preserveStreak) {
      _streak = 0;
    }
    _goalMetPreviousDay = false;
    final now = _clock();
    _lastActivityDate = DateTime(now.year, now.month, now.day);
    await _saveData();
  }

  void _recordDailySnapshot({required int games, required int focusMinutes, required int dayGap}) {
    _appendDailyValue(_weeklyGames, games);
    _appendDailyValue(_weeklyFocus, focusMinutes);

    if (dayGap > 1) {
      for (var i = 1; i < dayGap; i++) {
        _appendDailyValue(_weeklyGames, 0);
        _appendDailyValue(_weeklyFocus, 0);
      }
    }
  }

  void _appendDailyValue(List<int> list, int value) {
    if (list.length >= 7) {
      list.removeAt(0);
    }
    list.add(value);
    while (list.length < 7) {
      list.insert(0, 0);
    }
  }
}

