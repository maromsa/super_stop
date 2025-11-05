import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/prefs_keys.dart';

class MiniGame {
  const MiniGame({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
  });

  final String id;
  final String title;
  final String description;
  final int rewardCoins;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'rewardCoins': rewardCoins,
      };
}

class MiniGameCompletionResult {
  const MiniGameCompletionResult({
    required this.wasFirstCompletionToday,
    required this.streak,
    required this.rewardCoins,
    this.unlockedBadgeId,
  });

  final bool wasFirstCompletionToday;
  final int streak;
  final int rewardCoins;
  final String? unlockedBadgeId;
}

class MiniGameProvider with ChangeNotifier {
  MiniGameProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;

  static final List<MiniGame> _dailyMiniGames = List<MiniGame>.unmodifiable([
    const MiniGame(
      id: 'stretch_shuffle',
      title: 'Stretch Shuffle',
      description: 'Do a quick stretch routine: reach up high, touch your toes, roll your shoulders.',
      rewardCoins: 3,
    ),
    const MiniGame(
      id: 'gratitude_flip',
      title: 'Gratitude Flip',
      description: 'List three positive moments from today in under a minute.',
      rewardCoins: 4,
    ),
    const MiniGame(
      id: 'desk_dash',
      title: 'Desk Dash',
      description: 'Race to tidy five items around you before the break ends.',
      rewardCoins: 5,
    ),
    const MiniGame(
      id: 'pattern_tap',
      title: 'Pattern Tap',
      description: 'Tap out the rhythm 1-2-3-2-1 on your desk and repeat five times.',
      rewardCoins: 3,
    ),
    const MiniGame(
      id: 'power_pose',
      title: 'Power Pose',
      description: 'Hold a superhero pose for 30 seconds while breathing slowly.',
      rewardCoins: 4,
    ),
  ]);

  MiniGame? _current;
  int _streak = 0;
  DateTime? _lastCompletedDate;
  bool _completedToday = false;
  bool _isLoaded = false;

  MiniGame get currentMiniGame {
    _ensureDailyState();
    return _current ??= _selectForToday();
  }

  int get streak => _streak;
  bool get completedToday => _completedToday;
  bool get isLoaded => _isLoaded;

  Future<void> prepareForBreak() async {
    _ensureDailyState();
    if (_current == null) {
      _current = _selectForToday();
      await _persist();
    }
  }

  Future<MiniGameCompletionResult> completeCurrentMiniGame() async {
    _ensureDailyState();
    final game = currentMiniGame;
    final today = _normalizedDate(_clock());

    var wasFirstCompletionToday = !_completedToday;
    if (wasFirstCompletionToday) {
      if (_lastCompletedDate != null) {
        final last = _normalizedDate(_lastCompletedDate!);
        final gap = today.difference(last).inDays;
        if (gap == 1) {
          _streak += 1;
        } else if (gap > 1) {
          _streak = 1;
        } else {
          // Same-day completion handled by _completedToday flag, but guard just in case.
          _streak = _streak == 0 ? 1 : _streak;
          wasFirstCompletionToday = false;
        }
      } else {
        _streak = 1;
      }
    }

    _completedToday = true;
    _lastCompletedDate = today;

    if (!wasFirstCompletionToday) {
      // Repeated attempt in same day: streak unchanged, no rewards.
      await _persist();
      return MiniGameCompletionResult(
        wasFirstCompletionToday: false,
        streak: _streak,
        rewardCoins: 0,
        unlockedBadgeId: null,
      );
    }

    final unlockedBadgeId = _resolveBadgeIdForStreak(_streak);
    await _persist();

    return MiniGameCompletionResult(
      wasFirstCompletionToday: true,
      streak: _streak,
      rewardCoins: game.rewardCoins,
      unlockedBadgeId: unlockedBadgeId,
    );
  }

  MiniGame _selectForToday() {
    final today = _normalizedDate(_clock());
    final dayOfYear = int.parse('${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}');
    final index = dayOfYear % _dailyMiniGames.length;
    return _dailyMiniGames[index];
  }

  void _ensureDailyState() {
    if (_current == null && _isLoaded) {
      _current = _selectForToday();
    }
    final today = _normalizedDate(_clock());
    if (_lastCompletedDate == null) {
      _completedToday = false;
      return;
    }

    final last = _normalizedDate(_lastCompletedDate!);
    if (today.isAtSameMomentAs(last)) {
      return;
    }

    final gap = today.difference(last).inDays;
    if (gap > 1) {
      _streak = 0;
    }
    _completedToday = false;
    _current = _selectForToday();
  }

  String? _resolveBadgeIdForStreak(int streak) {
    switch (streak) {
      case 3:
        return 'mini_badge_bronze';
      case 7:
        return 'mini_badge_silver';
      case 14:
        return 'mini_badge_gold';
      default:
        return null;
    }
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _streak = prefs.getInt(PrefsKeys.miniGameStreak) ?? 0;
    final lastCompletedIso = prefs.getString(PrefsKeys.miniGameLastCompleted);
    if (lastCompletedIso != null) {
      _lastCompletedDate = DateTime.tryParse(lastCompletedIso);
    }
    _completedToday = prefs.getBool(PrefsKeys.miniGameCompletedToday) ?? false;
    final storedId = prefs.getString(PrefsKeys.miniGameCurrentId);
    if (storedId != null) {
      _current = _dailyMiniGames.firstWhere(
        (game) => game.id == storedId,
        orElse: () => _selectForToday(),
      );
    }

    _ensureDailyState();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.miniGameStreak, _streak);
    if (_lastCompletedDate != null) {
      await prefs.setString(PrefsKeys.miniGameLastCompleted, _lastCompletedDate!.toIso8601String());
    }
    await prefs.setBool(PrefsKeys.miniGameCompletedToday, _completedToday);
    if (_current != null) {
      await prefs.setString(PrefsKeys.miniGameCurrentId, _current!.id);
    }
  }

  Map<String, dynamic> debugState() {
    return {
      'streak': _streak,
      'completedToday': _completedToday,
      'lastCompletedDate': _lastCompletedDate?.toIso8601String(),
      'currentMiniGame': _current?.toJson(),
    };
  }

  DateTime _normalizedDate(DateTime date) => DateTime(date.year, date.month, date.day);
}
