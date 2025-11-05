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
  int _completionEvents = 0;
  int _rewardCoins = 5;
  int _rewardExperience = 0;
  bool _isLoaded = false;
  bool _autoStartBreak = false;

  FocusTimerPhase get phase => _phase;
  int get timeRemainingSeconds => _timeRemainingSeconds;
  int get selectedFocusMinutes => _selectedFocusMinutes;
  int get selectedBreakMinutes => _selectedBreakMinutes;
  bool get soundEnabled => _soundEnabled;
  int get completedSessions => _completedSessions;
  int get completionEvents => _completionEvents;
  int get focusRewardCoins => _rewardCoins;
  int get focusRewardExperience => _rewardExperience;
  bool get isLoaded => _isLoaded;
  bool get isRunning => _timer?.isActive ?? false;
  bool get autoStartBreak => _autoStartBreak;

  Future<void> startFocus() async {
    _activateTimedPhase(FocusTimerPhase.focus, _selectedFocusMinutes);
  }

  Future<void> startBreak() async {
    _activateTimedPhase(FocusTimerPhase.breakTime, _selectedBreakMinutes);
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _stopTimer();
    notifyListeners();
  }

  void resume() {
    if (_timeRemainingSeconds <= 0 || isRunning) {
      return;
    }
    if (_phase == FocusTimerPhase.focus || _phase == FocusTimerPhase.breakTime) {
      _startTimer();
      notifyListeners();
    }
  }

  void reset() {
    _stopTimer();
    _phase = FocusTimerPhase.idle;
    _timeRemainingSeconds = 0;
    notifyListeners();
  }

  Future<void> updateFocusMinutes(int minutes) async {
    await _updateDurations(focusMinutes: minutes);
  }

  Future<void> updateBreakMinutes(int minutes) async {
    await _updateDurations(breakMinutes: minutes);
  }

  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled == value) {
      return;
    }
    _soundEnabled = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setRewards({int? coins, int? experience}) async {
    var didChange = false;
    if (coins != null) {
      if (_rewardCoins != coins) {
        _rewardCoins = coins;
        didChange = true;
      }
    }
    if (experience != null) {
      if (_rewardExperience != experience) {
        _rewardExperience = experience;
        didChange = true;
      }
    }
    if (!didChange) {
      return;
    }
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setAutoStartBreak(bool value) async {
    if (_autoStartBreak == value) {
      return;
    }
    _autoStartBreak = value;
    await _savePreferences();
    notifyListeners();
  }

  void skipBreak() {
    if (_phase != FocusTimerPhase.breakTime && _phase != FocusTimerPhase.completed) {
      return;
    }
    _stopTimer();
    _phase = FocusTimerPhase.idle;
    _timeRemainingSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    if (_timeRemainingSeconds <= 0) {
      _onTimerComplete();
      return;
    }
    _timer = Timer.periodic(_tickDuration, (timer) {
      if (_timeRemainingSeconds > 0) {
        _timeRemainingSeconds--;
        notifyListeners();
        return;
      }
      timer.cancel();
      _timer = null;
      _onTimerComplete();
    });
  }

  void _onTimerComplete() {
    switch (_phase) {
      case FocusTimerPhase.focus:
        _completedSessions++;
        _completionEvents++;
        _phase = FocusTimerPhase.completed;
        _timeRemainingSeconds = 0;
        unawaited(_savePreferences());
        notifyListeners();
        if (_autoStartBreak && _selectedBreakMinutes > 0) {
          _scheduleAutoStartBreak();
        }
        break;
      case FocusTimerPhase.breakTime:
        _phase = FocusTimerPhase.idle;
        _timeRemainingSeconds = 0;
        notifyListeners();
        break;
      case FocusTimerPhase.idle:
      case FocusTimerPhase.completed:
        break;
    }
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(PrefsKeys.focusSoundEnabled) ?? true;
    _selectedFocusMinutes = prefs.getInt(PrefsKeys.focusMinutes) ?? 5;
    _selectedBreakMinutes = prefs.getInt(PrefsKeys.breakMinutes) ?? 2;
    _completedSessions = prefs.getInt(PrefsKeys.focusSessionsCompleted) ?? 0;
    _rewardCoins = prefs.getInt(PrefsKeys.focusRewardCoins) ?? 5;
    _rewardExperience = prefs.getInt(PrefsKeys.focusRewardExperience) ?? 0;
    _autoStartBreak = prefs.getBool(PrefsKeys.focusAutoStartBreak) ?? false;
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
    await prefs.setBool(PrefsKeys.focusAutoStartBreak, _autoStartBreak);
  }

  void _activateTimedPhase(FocusTimerPhase phase, int durationMinutes) {
    _phase = phase;
    _timeRemainingSeconds = durationMinutes * 60;
    _startTimer();
    notifyListeners();
  }

  Future<void> _updateDurations({int? focusMinutes, int? breakMinutes}) async {
    var didChange = false;
    if (focusMinutes != null && focusMinutes != _selectedFocusMinutes) {
      _selectedFocusMinutes = focusMinutes;
      didChange = true;
    }
    if (breakMinutes != null && breakMinutes != _selectedBreakMinutes) {
      _selectedBreakMinutes = breakMinutes;
      didChange = true;
    }
    if (!didChange) {
      return;
    }
    await _savePreferences();
    notifyListeners();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleAutoStartBreak() {
    unawaited(Future<void>.microtask(() async {
      if (_phase != FocusTimerPhase.completed) {
        return;
      }
      await startBreak();
    }));
  }
}
