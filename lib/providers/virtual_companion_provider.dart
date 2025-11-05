import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/achievement_service.dart';
import '../utils/prefs_keys.dart';
import 'daily_goals_provider.dart';

class CompanionPresentation {
  const CompanionPresentation({
    required this.name,
    required this.emoji,
    required this.headline,
    required this.message,
    required this.badges,
    required this.bondLevel,
  });

  final String name;
  final String emoji;
  final String headline;
  final String message;
  final List<String> badges;
  final int bondLevel;
}

class VirtualCompanionProvider with ChangeNotifier {
  VirtualCompanionProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  static const String _name = 'Nova';
  static const List<String> _supportiveMessages = [
    'I lined up your next streak bonus—keep the rhythm going!',
    'Your focus fireflies are glowing extra bright today.',
    'I saved you the shiniest coin for your next session.',
    'Let’s unlock another badge together before sunset!',
  ];

  final DateTime Function() _clock;
  int _bondLevel = 10;
  double _moodScore = 0;
  Set<String> _badges = <String>{};
  DateTime? _lastInteraction;
  bool _isLoaded = false;
  String? _cachedHeadline;
  String? _cachedMessage;

  CompanionPresentation get presentation {
    _ensureDailyDecay();
    final emoji = _resolveEmoji();
    final headline = _cachedHeadline ?? _buildHeadline();
    final message = _cachedMessage ?? _buildMessage();
    return CompanionPresentation(
      name: _name,
      emoji: emoji,
      headline: headline,
      message: message,
      badges: _badges.take(4).toList(growable: false),
      bondLevel: _bondLevel,
    );
  }

  bool get isLoaded => _isLoaded;

  void updateFrom(DailyGoalsProvider goals, AchievementService achievements) {
    _ensureDailyDecay();
    final targetBond = (12 + goals.streak * 2 + achievements.unlockedAchievements.length).clamp(0, 100);
    final targetMood = (goals.gamesPlayedToday * 6 + goals.focusMinutesToday * 1.5).toDouble();
    final unlockedBadgeIds = achievements.unlockedAchievements.map((ach) => ach.id).toSet();

    var changed = false;
    if ((targetBond - _bondLevel).abs() >= 1) {
      _bondLevel = targetBond;
      changed = true;
    }
    if ((targetMood - _moodScore).abs() >= 0.5) {
      _moodScore = targetMood;
      changed = true;
    }
    final sameBadges = _badges.length == unlockedBadgeIds.length && _badges.containsAll(unlockedBadgeIds);
    if (!sameBadges) {
      _badges = unlockedBadgeIds;
      changed = true;
    }

    if (changed) {
      _lastInteraction = _clock();
      _cachedHeadline = null;
      _cachedMessage = null;
      _persist();
      notifyListeners();
    }
  }

  void registerQuestCelebration(String questId) {
    _ensureDailyDecay();
    _bondLevel = (_bondLevel + 8).clamp(0, 100);
    _moodScore = (_moodScore + 12).clamp(0, 150);
    _cachedHeadline = 'Quest complete sparkle!';
    _cachedMessage = 'That quest "$questId" just powered up our bond.';
    _lastInteraction = _clock();
    _persist();
    notifyListeners();
  }

  String nextNudge() {
    _ensureDailyDecay();
    final index = _clock().millisecondsSinceEpoch % _supportiveMessages.length;
    return _supportiveMessages[index];
  }

  void resetForTesting() {
    _bondLevel = 10;
    _moodScore = 0;
    _badges = <String>{};
    _lastInteraction = null;
    _cachedHeadline = null;
    _cachedMessage = null;
    _persist();
  }

  String _buildHeadline() {
    if (_bondLevel >= 80) {
      return 'Supercharged sidekick!';
    } else if (_bondLevel >= 50) {
      return 'Co-pilot ready to roll';
    } else if (_bondLevel >= 25) {
      return 'Let’s spark the streak';
    }
    return 'I missed our missions';
  }

  String _buildMessage() {
    if (_moodScore >= 120) {
      return 'All systems buzzing—want to chase a legendary badge next?';
    } else if (_moodScore >= 60) {
      return 'Your progress energy is contagious. Just one more focus burst!';
    } else if (_moodScore >= 20) {
      return 'I stacked a fresh mystery quest to keep things spicy.';
    }
    return 'Let’s kick off with a mini-game during your next break.';
  }

  String _resolveEmoji() {
    if (_bondLevel >= 80) {
      return '🚀';
    } else if (_bondLevel >= 50) {
      return '✨';
    } else if (_bondLevel >= 25) {
      return '😊';
    }
    return '🤗';
  }

  void _ensureDailyDecay() {
    final now = _clock();
    if (_lastInteraction == null) {
      return;
    }
    final hours = now.difference(_lastInteraction!).inHours;
    if (hours <= 0) return;
    final decaySteps = hours ~/ 12;
    if (decaySteps <= 0) return;
    _bondLevel = max(0, _bondLevel - decaySteps);
    _moodScore = max(0, _moodScore - decaySteps * 3);
    _cachedHeadline = null;
    _cachedMessage = null;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _bondLevel = prefs.getInt(PrefsKeys.companionBondLevel) ?? 10;
    _moodScore = prefs.getDouble(PrefsKeys.companionMoodScore) ?? 0;
    final badgesJson = prefs.getString(PrefsKeys.companionBadges);
    if (badgesJson != null && badgesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(badgesJson) as List<dynamic>;
        _badges = decoded.map((value) => value as String).toSet();
      } catch (_) {
        _badges = <String>{};
      }
    }
    final lastInteraction = prefs.getString(PrefsKeys.companionLastInteraction);
    if (lastInteraction != null) {
      _lastInteraction = DateTime.tryParse(lastInteraction);
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.companionBondLevel, _bondLevel);
    await prefs.setDouble(PrefsKeys.companionMoodScore, _moodScore);
    await prefs.setString(
      PrefsKeys.companionBadges,
      jsonEncode(_badges.toList(growable: false)),
    );
    if (_lastInteraction != null) {
      await prefs.setString(PrefsKeys.companionLastInteraction, _lastInteraction!.toIso8601String());
    }
  }
}
