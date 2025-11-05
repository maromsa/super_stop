import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';
import '../providers/coin_provider.dart';
import '../utils/prefs_keys.dart';

enum QuestType { mood, focusMinutes, games }

class _QuestTexts {
  const _QuestTexts(this.title, this.description);

  final String title;
  final String description;
}

_QuestTexts _resolveQuestTexts(QuestType type, int goal, {String? gameId}) {
  switch (type) {
    case QuestType.mood:
      final description = goal == 1
          ? 'סמנו בדיקת מצב רוח אחת היום.'
          : 'סמנו $goal בדיקות מצב רוח היום.';
      return _QuestTexts('מצפן מצבי רוח', description);
    case QuestType.focusMinutes:
      return _QuestTexts('גל ריכוז אישי', 'צברו $goal דקות ריכוז.');
    case QuestType.games:
      if (gameId == 'impulse') {
        final text = goal == 1 ? 'פעם אחת' : '$goal פעמים';
        return _QuestTexts('אלופי האיפוק', 'שחקו באתגר האיפוק $text.');
      }
      if (gameId == 'reaction') {
        final text = goal == 1 ? 'פעם אחת' : '$goal פעמים';
        return _QuestTexts('מרוץ התגובה', 'התמודדו עם מבחן התגובה $text.');
      }
      final text = goal == 1 ? 'סבב אחד' : '$goal סבבי משחק שונים';
      return _QuestTexts('מיקס משחקים יומי', 'שחקו $text.');
  }
}

class MysteryQuest {
  MysteryQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.goal,
    required this.rewardCoins,
    this.gameId,
    int? progress,
    bool? claimed,
  })  : progress = progress ?? 0,
        claimed = claimed ?? false;

  final String id;
  final String title;
  final String description;
  final QuestType type;
  final int goal;
  final String? gameId;
  final int rewardCoins;
  int progress;
  bool claimed;

  bool get isCompleted => progress >= goal;
  bool get isClaimable => isCompleted && !claimed && rewardCoins > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'goal': goal,
        'progress': progress,
        'rewardCoins': rewardCoins,
        'gameId': gameId,
        'claimed': claimed,
      };

  factory MysteryQuest.fromJson(Map<String, dynamic> json) {
    final type = QuestType.values.firstWhere((value) => value.name == json['type']);
    final goal = json['goal'] as int;
    final gameId = json['gameId'] as String?;
    final texts = _resolveQuestTexts(type, goal, gameId: gameId);
    return MysteryQuest(
      id: json['id'] as String,
      title: texts.title,
      description: texts.description,
      type: type,
      goal: goal,
      progress: json['progress'] as int? ?? 0,
      rewardCoins: json['rewardCoins'] as int? ?? 0,
      gameId: gameId,
      claimed: json['claimed'] as bool? ?? false,
    );
  }
}

class MysteryQuestProvider with ChangeNotifier {
  MysteryQuestProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;

  List<MysteryQuest> _activeQuests = <MysteryQuest>[];
  DateTime? _generatedOn;
  bool _isLoaded = false;

  List<MysteryQuest> get activeQuests => List<MysteryQuest>.unmodifiable(_activeQuests);
  bool get isLoaded => _isLoaded;

  List<MysteryQuest> registerMoodEntry(Mood mood) {
    _ensureDailyQuests();
    final updated = <MysteryQuest>[];
    for (final quest in _activeQuests.where((q) => q.type == QuestType.mood)) {
      quest.progress += 1;
      if (quest.isCompleted) {
        updated.add(quest);
      }
    }
    _persist();
    if (updated.isNotEmpty) notifyListeners();
    return updated;
  }

  List<MysteryQuest> registerFocusMinutes(int minutes) {
    _ensureDailyQuests();
    final updated = <MysteryQuest>[];
    for (final quest in _activeQuests.where((q) => q.type == QuestType.focusMinutes)) {
      quest.progress += minutes;
      if (quest.isCompleted) {
        updated.add(quest);
      }
    }
    _persist();
    if (updated.isNotEmpty) notifyListeners();
    return updated;
  }

  List<MysteryQuest> registerGamePlayed(String gameId) {
    _ensureDailyQuests();
    final updated = <MysteryQuest>[];
    for (final quest in _activeQuests.where((q) => q.type == QuestType.games)) {
      if (quest.gameId == null || quest.gameId == gameId) {
        quest.progress += 1;
        if (quest.isCompleted) {
          updated.add(quest);
        }
      }
    }
    _persist();
    if (updated.isNotEmpty) notifyListeners();
    return updated;
  }

  MysteryQuest? claimReward(String questId, CoinProvider coinProvider) {
    final quest = _activeQuests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw ArgumentError.value(questId, 'questId', 'המשימה לא נמצאה'),
    );
    if (!quest.isClaimable) {
      return null;
    }
    if (quest.rewardCoins > 0) {
      coinProvider.addCoins(quest.rewardCoins);
    }
    quest.claimed = true;
    _persist();
    notifyListeners();
    return quest;
  }

  void resetForTesting() {
    _activeQuests = <MysteryQuest>[];
    _generatedOn = null;
    _persist();
  }

  void _ensureDailyQuests() {
    final today = _normalizedDate(_clock());
    if (_generatedOn == null || !_normalizedDate(_generatedOn!).isAtSameMomentAs(today)) {
      _activeQuests = _generateQuests(today.year, today.month, today.day, _clock().millisecondsSinceEpoch);
      _generatedOn = today;
      _persist();
      notifyListeners();
    }
  }

  List<MysteryQuest> _generateQuests(int year, int month, int day, int seedSource) {
    final seed = year * 10000 + month * 100 + day;
    final variant = (seed + seedSource) % 3;

    final moodGoal = 1 + (seed % 2);
    final focusGoal = 10 + (seed % 3) * 5; // 10, 15, or 20 minutes
    final gameGoal = 2 + (seed % 2); // 2 or 3 games

    final quests = <MysteryQuest>[
      () {
        final texts = _resolveQuestTexts(QuestType.mood, moodGoal);
        return MysteryQuest(
          id: 'mood_$seed',
          title: texts.title,
          description: texts.description,
          type: QuestType.mood,
          goal: moodGoal,
          rewardCoins: 5 + variant,
        );
      }(),
      () {
        final texts = _resolveQuestTexts(QuestType.focusMinutes, focusGoal);
        return MysteryQuest(
          id: 'focus_$seed',
          title: texts.title,
          description: texts.description,
          type: QuestType.focusMinutes,
          goal: focusGoal,
          rewardCoins: 6 + variant,
        );
      }(),
    ];

    final gameId = variant == 0
        ? null
        : variant == 1
            ? 'impulse'
            : 'reaction';
    final gameTexts = _resolveQuestTexts(QuestType.games, gameGoal, gameId: gameId);
    final gameQuest = MysteryQuest(
      id: 'game_$seed',
      title: gameTexts.title,
      description: gameTexts.description,
      type: QuestType.games,
      goal: gameGoal,
      rewardCoins: 4 + variant,
      gameId: gameId,
    );
    quests.add(gameQuest);
    return quests;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.mysteryQuestState);
    final generatedDate = prefs.getString(PrefsKeys.mysteryQuestGeneratedOn);
    if (generatedDate != null) {
      _generatedOn = DateTime.tryParse(generatedDate);
    }
    if (serialized != null && serialized.isNotEmpty) {
      try {
        final decoded = jsonDecode(serialized) as List<dynamic>;
        _activeQuests = decoded
            .map((entry) => MysteryQuest.fromJson(entry as Map<String, dynamic>))
            .toList(growable: false);
      } catch (_) {
        _activeQuests = <MysteryQuest>[];
      }
    }

    _ensureDailyQuests();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefsKeys.mysteryQuestState,
      jsonEncode(_activeQuests.map((q) => q.toJson()).toList(growable: false)),
    );
    if (_generatedOn != null) {
      await prefs.setString(PrefsKeys.mysteryQuestGeneratedOn, _generatedOn!.toIso8601String());
    }
  }

  DateTime _normalizedDate(DateTime value) => DateTime(value.year, value.month, value.day);
}
