import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/prefs_keys.dart';

enum FocusTimerPhase { idle, focus, breakTime, completed }

class FocusTimerController extends ChangeNotifier {
  FocusTimerController({Duration tickDuration = const Duration(seconds: 1)})
      : _tickDuration = tickDuration {
    _hydrate();
  }

  final Duration _tickDuration;
  Timer? _timer;

  FocusTimerPhase _phase = FocusTimerPhase.idle;
  int _timeRemainingSeconds = 0;
  int _selectedFocusMinutes = 5;
  int _selectedBreakMinutes = 2;
  bool _soundEnabled = true;
  int _completedSessions = 0;
  int _completionTicker = 0;
  int _rewardCoins = 5;
  int _rewardExperience = 0;
  bool _isLoaded = false;

  FocusTimerPhase get phase => _phase;
  int get timeRemainingSeconds => _timeRemainingSeconds;
  int get selectedFocusMinutes => _selectedFocusMinutes;
  int get selectedBreakMinutes => _selectedBreakMinutes;
  bool get soundEnabled => _soundEnabled;
  int get completedSessions => _completedSessions;
  int get completionTicker => _completionTicker;
  int get focusRewardCoins => _rewardCoins;
  int get focusRewardExperience => _rewardExperience;
  bool get isLoaded => _isLoaded;
  bool get isRunning => _timer?.isActive ?? false;

  Future<void> startFocus() async {
    _phase = FocusTimerPhase.focus;
    _timeRemainingSeconds = _selectedFocusMinutes * 60;
    _startTimer();
    notifyListeners();
  }

  Future<void> startBreak() async {
    _phase = FocusTimerPhase.breakTime;
    _timeRemainingSeconds = _selectedBreakMinutes * 60;
    _startTimer();
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_phase == FocusTimerPhase.focus || _phase == FocusTimerPhase.breakTime) {
      _startTimer();
      notifyListeners();
    }
  }

  void reset() {
    _timer?.cancel();
    _phase = FocusTimerPhase.idle;
    _timeRemainingSeconds = 0;
    notifyListeners();
  }

  Future<void> updateFocusMinutes(int minutes) async {
    _selectedFocusMinutes = minutes;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> updateBreakMinutes(int minutes) async {
    _selectedBreakMinutes = minutes;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setRewards({int? coins, int? experience}) async {
    if (coins != null) {
      _rewardCoins = coins;
    }
    if (experience != null) {
      _rewardExperience = experience;
    }
    await _savePreferences();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickDuration, (timer) {
      if (_timeRemainingSeconds > 0) {
        _timeRemainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    if (_phase == FocusTimerPhase.focus) {
      _completedSessions++;
      _completionTicker++;
      _phase = FocusTimerPhase.completed;
      _timeRemainingSeconds = 0;
      _savePreferences();
    } else if (_phase == FocusTimerPhase.breakTime) {
      _phase = FocusTimerPhase.idle;
      _timeRemainingSeconds = 0;
    }
    notifyListeners();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(PrefsKeys.focusSoundEnabled) ?? true;
    _selectedFocusMinutes = prefs.getInt(PrefsKeys.focusMinutes) ?? 5;
    _selectedBreakMinutes = prefs.getInt(PrefsKeys.breakMinutes) ?? 2;
    _completedSessions = prefs.getInt(PrefsKeys.focusSessionsCompleted) ?? 0;
    _rewardCoins = prefs.getInt(PrefsKeys.focusRewardCoins) ?? 5;
    _rewardExperience = prefs.getInt(PrefsKeys.focusRewardExperience) ?? 0;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.focusSoundEnabled, _soundEnabled);
    await prefs.setInt(PrefsKeys.focusMinutes, _selectedFocusMinutes);
    await prefs.setInt(PrefsKeys.breakMinutes, _selectedBreakMinutes);
    await prefs.setInt(PrefsKeys.focusSessionsCompleted, _completedSessions);
    await prefs.setInt(PrefsKeys.focusRewardCoins, _rewardCoins);
    await prefs.setInt(PrefsKeys.focusRewardExperience, _rewardExperience);
  }
}
