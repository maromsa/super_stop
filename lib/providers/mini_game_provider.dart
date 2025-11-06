import 'dart:async';

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
        title: 'ריקוד מתיחות',
        description: 'בצעו מתיחות מהירות: הרימו ידיים למעלה, נגעו באצבעות הרגליים וסובבו כתפיים.',
        rewardCoins: 3,
      ),
      const MiniGame(
        id: 'gratitude_flip',
        title: 'רגעי תודה',
        description: 'כתבו שלושה רגעים חיוביים מהיום בפחות מדקה.',
        rewardCoins: 4,
      ),
      const MiniGame(
        id: 'desk_dash',
        title: 'מרוץ השולחן',
        description: 'מהרו לסדר חמישה חפצים סביבכם לפני שההפסקה מסתיימת.',
        rewardCoins: 5,
      ),
      const MiniGame(
        id: 'pattern_tap',
        title: 'קצב התבנית',
        description: 'תיפחו על השולחן בקצב 1-2-3-2-1 וחזרו על כך חמש פעמים.',
        rewardCoins: 3,
      ),
      const MiniGame(
        id: 'power_pose',
        title: 'תנוחת הכוח',
        description: 'החזיקו תנוחת גיבור על במשך 30 שניות תוך נשימה איטית.',
        rewardCoins: 4,
      ),
  ]);

  MiniGame? _current;
  int _streak = 0;
  DateTime? _lastCompletedDate;
  DateTime? _lastGeneratedDate;
  bool _completedToday = false;
  bool _isLoaded = false;

  MiniGame get currentMiniGame {
    final didUpdate = _ensureDailyState();
    if (didUpdate) {
      unawaited(_persist());
    }
    return _current ??= _selectForToday();
  }

  int get streak => _streak;
  bool get completedToday => _completedToday;
  bool get isLoaded => _isLoaded;

  Future<void> prepareForBreak() async {
    final didUpdate = _ensureDailyState();
    if (didUpdate) {
      await _persist();
      notifyListeners();
    }
  }

  Future<MiniGameCompletionResult> completeCurrentMiniGame() async {
    _ensureDailyState();
    if (_current == null) {
      _current = _selectForToday();
      _lastGeneratedDate ??= _normalizedDate(_clock());
    }
    final game = _current!;
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
      notifyListeners();
      return MiniGameCompletionResult(
        wasFirstCompletionToday: false,
        streak: _streak,
        rewardCoins: 0,
        unlockedBadgeId: null,
      );
    }

    final unlockedBadgeId = _resolveBadgeIdForStreak(_streak);
    await _persist();
    notifyListeners();

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

  bool _ensureDailyState() {
    final today = _normalizedDate(_clock());
    var didUpdate = false;

    if (_lastGeneratedDate == null || !_lastGeneratedDate!.isAtSameMomentAs(today)) {
      _current = _selectForToday();
      _lastGeneratedDate = today;
      if (_completedToday) {
        _completedToday = false;
      }
      didUpdate = true;
    } else if (_current == null) {
      _current = _selectForToday();
      didUpdate = true;
    }

    if (_lastCompletedDate != null) {
      final lastCompleted = _normalizedDate(_lastCompletedDate!);
      if (!today.isAtSameMomentAs(lastCompleted)) {
        final gap = today.difference(lastCompleted).inDays;
        if (gap > 1 && _streak != 0) {
          _streak = 0;
          didUpdate = true;
        }
        if (_completedToday) {
          _completedToday = false;
          didUpdate = true;
        }
      }
    } else if (_completedToday) {
      _completedToday = false;
      didUpdate = true;
    }

    if (_current == null) {
      _current = _selectForToday();
      didUpdate = true;
    }

    return didUpdate;
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
    final lastGeneratedIso = prefs.getString(PrefsKeys.miniGameGeneratedOn);
    if (lastGeneratedIso != null) {
      _lastGeneratedDate = DateTime.tryParse(lastGeneratedIso);
    }
    _completedToday = prefs.getBool(PrefsKeys.miniGameCompletedToday) ?? false;
    final storedId = prefs.getString(PrefsKeys.miniGameCurrentId);
    if (storedId != null) {
      _current = _dailyMiniGames.firstWhere(
        (game) => game.id == storedId,
        orElse: () => _selectForToday(),
      );
    }

    final didUpdate = _ensureDailyState();
    _isLoaded = true;
    if (didUpdate) {
      await _persist();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.miniGameStreak, _streak);
    if (_lastCompletedDate != null) {
      await prefs.setString(PrefsKeys.miniGameLastCompleted, _lastCompletedDate!.toIso8601String());
    } else {
      await prefs.remove(PrefsKeys.miniGameLastCompleted);
    }
    await prefs.setBool(PrefsKeys.miniGameCompletedToday, _completedToday);
    if (_current != null) {
      await prefs.setString(PrefsKeys.miniGameCurrentId, _current!.id);
    } else {
      await prefs.remove(PrefsKeys.miniGameCurrentId);
    }
    if (_lastGeneratedDate != null) {
      await prefs.setString(PrefsKeys.miniGameGeneratedOn, _lastGeneratedDate!.toIso8601String());
    } else {
      await prefs.remove(PrefsKeys.miniGameGeneratedOn);
    }
  }

  Map<String, dynamic> debugState() {
    return {
      'streak': _streak,
      'completedToday': _completedToday,
      'lastCompletedDate': _lastCompletedDate?.toIso8601String(),
      'lastGeneratedDate': _lastGeneratedDate?.toIso8601String(),
      'currentMiniGame': _current?.toJson(),
    };
  }

  DateTime _normalizedDate(DateTime date) => DateTime(date.year, date.month, date.day);
}
