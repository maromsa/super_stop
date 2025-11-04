import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyGoalsProvider with ChangeNotifier {
  static const String _kStreakKey = 'daily_streak';
  static const String _kLastDateKey = 'last_activity_date';
  static const String _kGamesPlayedKey = 'games_played_today';
  static const String _kFocusMinutesKey = 'focus_minutes_today';
  static const String _kDailyGoalKey = 'daily_goal_games';

  int _streak = 0;
  int _gamesPlayedToday = 0;
  int _focusMinutesToday = 0;
  int _dailyGoal = 3; // Default: 3 games per day
  DateTime? _lastActivityDate;
  bool _goalMetPreviousDay = false;
  final DateTime Function() _clock;

  int get streak => _streak;
  int get gamesPlayedToday => _gamesPlayedToday;
  int get focusMinutesToday => _focusMinutesToday;
  int get dailyGoal => _dailyGoal;
  bool get isGoalCompleted => _gamesPlayedToday >= _dailyGoal;
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
    _streak = prefs.getInt(_kStreakKey) ?? 0;
    _gamesPlayedToday = prefs.getInt(_kGamesPlayedKey) ?? 0;
    _focusMinutesToday = prefs.getInt(_kFocusMinutesKey) ?? 0;
    _dailyGoal = prefs.getInt(_kDailyGoalKey) ?? 3;
    
    final lastDateString = prefs.getString(_kLastDateKey);
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
    await prefs.setInt(_kStreakKey, _streak);
    await prefs.setInt(_kGamesPlayedKey, _gamesPlayedToday);
    await prefs.setInt(_kFocusMinutesKey, _focusMinutesToday);
    await prefs.setInt(_kDailyGoalKey, _dailyGoal);
    
    if (_lastActivityDate != null) {
      await prefs.setString(_kLastDateKey, _lastActivityDate!.toIso8601String());
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
}

