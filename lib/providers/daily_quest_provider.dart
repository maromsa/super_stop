import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_quest.dart';
import '../utils/prefs_keys.dart';
import 'collectible_provider.dart';
import 'coin_provider.dart';

class DailyQuestProvider with ChangeNotifier {
  DailyQuestProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;
  final Random _random = Random();
  List<DailyQuest> _quests = <DailyQuest>[];
  DateTime? _generatedOn;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<DailyQuest> get quests => List<DailyQuest>.unmodifiable(_quests);
  bool get hasCreativeQuest => _quests.any((quest) => quest.isCreative);

  DailyQuest? resolveById(String id) {
    for (final quest in _quests) {
      if (quest.id == id) {
        return quest;
      }
    }
    return null;
  }

  Future<List<DailyQuest>> registerSkillEvent(
    String trigger, {
    int amount = 1,
    CoinProvider? coinProvider,
    CollectibleProvider? collectibleProvider,
  }) async {
    _ensureDailyBoard();
    if (amount <= 0) {
      return const <DailyQuest>[];
    }
    var didChange = false;
    final completed = <DailyQuest>[];
    _quests = _quests.map((quest) {
      if (quest.kind != DailyQuestKind.skill) {
        return quest;
      }
      if (quest.skillTrigger != null && quest.skillTrigger != trigger) {
        return quest;
      }
      final updatedProgress = (quest.progress + amount).clamp(0, quest.goal);
      final updatedQuest = quest.copyWith(progress: updatedProgress);
      if (!quest.isCompleted && updatedQuest.isCompleted) {
        completed.add(updatedQuest);
      }
      if (updatedQuest.progress != quest.progress) {
        didChange = true;
      }
      return updatedQuest;
    }).toList(growable: false);

    if (completed.isNotEmpty) {
      await _rewardCompleted(completed, coinProvider, collectibleProvider);
    }
    if (didChange) {
      await _persist();
      notifyListeners();
    }
    return completed;
  }

  Future<List<DailyQuest>> registerCreativeProgress(
    String questId, {
    int amount = 1,
    CoinProvider? coinProvider,
    CollectibleProvider? collectibleProvider,
  }) async {
    _ensureDailyBoard();
    if (amount <= 0) {
      return const <DailyQuest>[];
    }
    var didChange = false;
    final completed = <DailyQuest>[];
    _quests = _quests.map((quest) {
      if (quest.id != questId) {
        return quest;
      }
      final updatedProgress = (quest.progress + amount).clamp(0, quest.goal);
      final updatedQuest = quest.copyWith(progress: updatedProgress);
      if (!quest.isCompleted && updatedQuest.isCompleted) {
        completed.add(updatedQuest);
      }
      if (updatedQuest.progress != quest.progress) {
        didChange = true;
      }
      return updatedQuest;
    }).toList(growable: false);

    if (completed.isNotEmpty) {
      await _rewardCompleted(completed, coinProvider, collectibleProvider);
    }
    if (didChange) {
      await _persist();
      notifyListeners();
    }
    return completed;
  }

  Future<void> resetForTesting() async {
    _quests = <DailyQuest>[];
    _generatedOn = null;
    await _persist();
    notifyListeners();
  }

  void _ensureDailyBoard() {
    final today = _normalizedDate(_clock());
    if (_generatedOn != null && _normalizedDate(_generatedOn!).isAtSameMomentAs(today) && _quests.isNotEmpty) {
      return;
    }
    _quests = _generateBoard(today);
    _generatedOn = today;
    _persist();
    notifyListeners();
  }

  List<DailyQuest> _generateBoard(DateTime today) {
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final variant = (seed + _random.nextInt(1000)) % 4;
    final creativePrompts = <String>[
      'ציירו את גיבור העל של הקשב שלכם וציינו כוח אחד שלו.',
      'כתבו שורת קומיקס על רגע שבו הצלחתם להתאפק.',
      'המציאו קמע חדש לחבר הדיגיטלי וספרו עליו.',
      'צלמו בצליל את מצב הרוח שלכם (אפשר להקליט לעצמכם).',
    ];
    final creativeDescription = creativePrompts[variant % creativePrompts.length];

    return <DailyQuest>[
      DailyQuest(
        id: 'skill_focus_$seed',
        kind: DailyQuestKind.skill,
        title: 'ניצוץ ריכוז',
        description: 'השלימו שני פרצי ריכוז אדפטיביים היום.',
        goal: 2,
        skillTrigger: 'focus_burst',
        rewardCollectibleId: variant.isEven ? 'cape_of_focus' : null,
        coinReward: 8 + variant,
      ),
      DailyQuest(
        id: 'skill_games_$seed',
        kind: DailyQuestKind.skill,
        title: 'סיבוב תזמון',
        description: variant % 2 == 0
            ? 'שחקו באתגר התגובה פעמיים.'
            : 'נצחו סבב אחד במשחק האיפוק.',
        goal: variant % 2 == 0 ? 2 : 1,
        skillTrigger: variant % 2 == 0 ? 'reaction' : 'impulse',
        rewardCollectibleId: variant % 2 == 0 ? null : 'avatar_spark',
        coinReward: 6,
      ),
      DailyQuest(
        id: 'creative_$seed',
        kind: DailyQuestKind.creative,
        title: 'משימת חופש',
        description: creativeDescription,
        goal: 1,
        rewardCollectibleId: variant % 3 == 0 ? 'story_quill' : null,
        coinReward: 4,
      ),
    ];
  }

  Future<void> _rewardCompleted(
    List<DailyQuest> quests,
    CoinProvider? coinProvider,
    CollectibleProvider? collectibleProvider,
  ) async {
    if (quests.isEmpty) {
      return;
    }
    for (final quest in quests) {
      if (quest.coinReward > 0 && coinProvider != null) {
        coinProvider.addCoins(quest.coinReward);
      }
      if (quest.rewardCollectibleId != null && collectibleProvider != null) {
        await collectibleProvider.unlockCollectible(quest.rewardCollectibleId!);
      }
    }
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.dailyQuestState);
    final generatedOn = prefs.getString(PrefsKeys.dailyQuestGeneratedOn);
    if (generatedOn != null) {
      _generatedOn = DateTime.tryParse(generatedOn);
    }
    if (serialized != null && serialized.isNotEmpty) {
      try {
        _quests = DailyQuest.decodeList(serialized);
      } catch (_) {
        _quests = <DailyQuest>[];
      }
    }
    _ensureDailyBoard();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.dailyQuestState, DailyQuest.encodeList(_quests));
    if (_generatedOn != null) {
      await prefs.setString(PrefsKeys.dailyQuestGeneratedOn, _generatedOn!.toIso8601String());
    }
  }

  DateTime _normalizedDate(DateTime value) => DateTime(value.year, value.month, value.day);
}
