import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/focus_burst_plan.dart';
import '../models/mood_entry.dart';
import '../utils/prefs_keys.dart';
import 'collectible_provider.dart';
import 'coin_provider.dart';
import 'daily_quest_provider.dart';
import 'mood_journal_provider.dart';
import 'virtual_companion_provider.dart';

class AdaptiveFocusChallengeProvider with ChangeNotifier {
  AdaptiveFocusChallengeProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;
  final Random _random = Random();
  FocusBurstPlan? _currentPlan;
  FocusBurstDifficulty _difficulty = FocusBurstDifficulty.mellow;
  final List<FocusBurstResult> _recentResults = <FocusBurstResult>[];
  double _averageReactionMs = 0;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  FocusBurstPlan get currentPlan => _currentPlan ?? _generatePlan();
  FocusBurstDifficulty get currentDifficulty => _difficulty;
  double get averageReactionMs => _averageReactionMs;
  List<FocusBurstResult> get recentResults => List<FocusBurstResult>.unmodifiable(_recentResults);

  void updateFromMoodJournal(MoodJournalProvider journal) {
    if (!journal.hasEntries) {
      return;
    }
    final recent = journal.recentMoodDistribution(days: 5);
    final totalEntries = recent.values.fold<int>(0, (sum, value) => sum + value);
    if (totalEntries == 0) {
      return;
    }
    final agitationScore = (recent[Mood.excited] ?? 0) * 1.5 + (recent[Mood.anxious] ?? 0) * 1.2;
    final calmScore = (recent[Mood.calm] ?? 0) * 1.5 + (recent[Mood.happy] ?? 0) * 1.1;
    if (agitationScore > calmScore * 1.2) {
      _difficulty = FocusBurstDifficulty.mellow;
    } else if (calmScore > agitationScore * 1.3) {
      _difficulty = FocusBurstDifficulty.turbo;
    } else {
      _difficulty = FocusBurstDifficulty.balanced;
    }
    _currentPlan = null;
    _persist();
    notifyListeners();
  }

  Future<void> registerResult(
    FocusBurstResult result, {
    DailyQuestProvider? dailyQuest,
    CoinProvider? coins,
    CollectibleProvider? collectibles,
    VirtualCompanionProvider? companion,
  }) async {
    _recentResults
      ..add(result)
      ..sort((a, b) => b.averageReactionMs.compareTo(a.averageReactionMs));
    while (_recentResults.length > 10) {
      _recentResults.removeAt(0);
    }
    _averageReactionMs = _recentResults.fold<double>(0, (sum, entry) => sum + entry.averageReactionMs) /
        _recentResults.length;

    if (result.completed && dailyQuest != null) {
      await dailyQuest.registerSkillEvent(
        'focus_burst',
        coinProvider: coins,
        collectibleProvider: collectibles,
      );
    }
    if (result.completed && companion != null) {
      companion.registerFocusBurstVictory();
    }

    _adjustDifficulty(result);
    _currentPlan = null;
    await _persist();
    notifyListeners();
  }

  FocusBurstPlan _generatePlan() {
    final id = 'burst_${_clock().millisecondsSinceEpoch}_${_random.nextInt(999)}';
    final cues = <FocusBurstCue>[];
    final totalCues = _difficulty == FocusBurstDifficulty.turbo
        ? 6
        : _difficulty == FocusBurstDifficulty.balanced
            ? 5
            : 4;
    final baseDuration = _difficulty == FocusBurstDifficulty.mellow
        ? 6
        : _difficulty == FocusBurstDifficulty.balanced
            ? 5
            : 4;
    const palette = <int>[0xFF7C4DFF, 0xFF26C6DA, 0xFFFF5252, 0xFFFFC107];
    for (var i = 0; i < totalCues; i++) {
      final prompt = switch (_difficulty) {
        FocusBurstDifficulty.mellow => i.isEven ? 'נשמו עמוק ולחצו' : 'שלבו לחיצה עם נשימה ויזואלית',
        FocusBurstDifficulty.balanced => i % 3 == 0
            ? 'הגיבו כאשר הצבע משתנה'
            : 'סחטו לחיצה קצרה ואז שחררו',
        FocusBurstDifficulty.turbo => i % 2 == 0
            ? 'לחצו פעמיים במהירות'
            : 'לחצו רק כאשר מופיע הסמל',
      };
      cues.add(
        FocusBurstCue(
          prompt: prompt,
          durationSeconds: max(3, baseDuration - _random.nextInt(2)),
          sensoryColor: palette[i % palette.length],
        ),
      );
    }
    final plan = FocusBurstPlan(
      id: id,
      difficulty: _difficulty,
      cues: cues,
      breathCount: _difficulty == FocusBurstDifficulty.mellow ? 4 : 2,
      targetReactions: totalCues,
    );
    _currentPlan = plan;
    return plan;
  }

  void _adjustDifficulty(FocusBurstResult result) {
    if (!result.completed) {
      _difficulty = FocusBurstDifficulty.mellow;
      return;
    }
    if (result.averageReactionMs < 550 && _difficulty != FocusBurstDifficulty.turbo) {
      _difficulty = FocusBurstDifficulty.values[_difficulty.index + 1];
      return;
    }
    if (result.averageReactionMs > 1100 && _difficulty != FocusBurstDifficulty.mellow) {
      _difficulty = FocusBurstDifficulty.values[_difficulty.index - 1];
    }
  }

  void requestNewPlan() {
    _currentPlan = null;
    unawaited(_persist());
    notifyListeners();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(PrefsKeys.focusBurstState);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        final planJson = decoded['plan'] as Map<String, dynamic>?;
        if (planJson != null) {
          _currentPlan = FocusBurstPlan.fromJson(planJson);
        }
        final difficultyName = decoded['difficulty'] as String?;
        if (difficultyName != null) {
          _difficulty = FocusBurstDifficulty.values.firstWhere(
            (value) => value.name == difficultyName,
            orElse: () => _difficulty,
          );
        }
        final resultsJson = decoded['results'] as List<dynamic>?;
        if (resultsJson != null) {
          _recentResults
            ..clear()
            ..addAll(
              resultsJson
                  .map((entry) => FocusBurstResult.fromJson(entry as Map<String, dynamic>))
                  .toList(growable: false),
            );
        }
        _averageReactionMs = (decoded['averageReactionMs'] as num?)?.toDouble() ?? _averageReactionMs;
      } catch (_) {
        _currentPlan = null;
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'plan': _currentPlan?.toJson(),
      'difficulty': _difficulty.name,
      'averageReactionMs': _averageReactionMs,
      'results': _recentResults.map((entry) => entry.toJson()).toList(growable: false),
    };
    await prefs.setString(PrefsKeys.focusBurstState, jsonEncode(payload));
  }
}
