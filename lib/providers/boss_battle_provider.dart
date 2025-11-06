import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/boss_battle.dart';
import '../utils/prefs_keys.dart';
import 'collectible_provider.dart';
import 'coin_provider.dart';
import 'daily_quest_provider.dart';

class BossBattleAttemptResult {
  const BossBattleAttemptResult({
    required this.correctAnswers,
    required this.totalTasks,
    required this.completed,
  });

  final int correctAnswers;
  final int totalTasks;
  final bool completed;
}

class BossBattleProvider with ChangeNotifier {
  BossBattleProvider() {
    _hydrate();
  }

  final Map<String, BossBattle> _battles = <String, BossBattle>{
    for (final battle in _seedBattles()) battle.id: battle,
  };
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<BossBattle> get battles {
    final list = _battles.values.toList(growable: true)
      ..sort((a, b) => a.recommendedLevel.compareTo(b.recommendedLevel));
    return List<BossBattle>.unmodifiable(list);
  }

  BossBattle? resolve(String id) => _battles[id];

  Future<BossBattleAttemptResult> attemptBattle(
    String id,
    List<int> answers, {
    CoinProvider? coinProvider,
    CollectibleProvider? collectibleProvider,
    DailyQuestProvider? dailyQuestProvider,
  }) async {
    final battle = _battles[id];
    if (battle == null) {
      throw ArgumentError.value(id, 'id', 'Boss battle not found');
    }
    var correct = 0;
    for (var i = 0; i < battle.tasks.length && i < answers.length; i++) {
      if (battle.tasks[i].correctAnswer == answers[i]) {
        correct++;
      }
    }
    final completed = correct == battle.tasks.length;
    if (completed && !battle.completed) {
      _battles[id] = battle.markCompleted();
      coinProvider?.addCoins(20);
      if (dailyQuestProvider != null) {
        await dailyQuestProvider.registerSkillEvent(
          'executive',
          coinProvider: coinProvider,
          collectibleProvider: collectibleProvider,
        );
      }
      if (collectibleProvider != null) {
        await collectibleProvider.unlockCollectible('boss_crown');
      }
      await _persist();
      notifyListeners();
    }
    return BossBattleAttemptResult(
      correctAnswers: correct,
      totalTasks: battle.tasks.length,
      completed: completed,
    );
  }

  Future<void> resetForTesting() async {
    _battles
      ..clear()
      ..addAll({for (final battle in _seedBattles()) battle.id: battle});
    await _persist();
    notifyListeners();
  }

  static List<BossBattle> _seedBattles() => <BossBattle>[
        const BossBattle(
          id: 'planner_bot',
          name: 'בוט התכנון',
          domain: BossBattleDomain.planning,
          recommendedLevel: 3,
          tasks: <BossBattleTask>[
            const BossBattleTask(
              id: 'planner_bot_1',
              prompt: 'מה צריך לעשות ראשון כדי להתכונן לחוג?',
              choices: <String>['לאסוף תיק, לשתות מים, להתקשר לחבר', 'לרגוע מול הטלוויזיה', 'לקפוץ ישר לחוג'],
              correctAnswer: 0,
            ),
            const BossBattleTask(
              id: 'planner_bot_2',
              prompt: 'סדרו את השלבים: להכין שיעורים, לארוז נשנוש, לבדוק שהאפליקציה פתוחה',
              choices: <String>['1-2-3', '2-1-3', '3-1-2'],
              correctAnswer: 1,
            ),
          ],
        ),
        const BossBattle(
          id: 'memory_mage',
          name: 'קוסם הזיכרון',
          domain: BossBattleDomain.workingMemory,
          recommendedLevel: 5,
          tasks: <BossBattleTask>[
            const BossBattleTask(
              id: 'memory_mage_1',
              prompt: 'מה הייתה מילת הקוד שנשמעה בתחילת הקרב?',
              choices: <String>['רעם', 'ניצוץ', 'אופק'],
              correctAnswer: 1,
            ),
            const BossBattleTask(
              id: 'memory_mage_2',
              prompt: 'אילו שני חפצים הופיעו יחד? ',
              choices: <String>['שעון וספר', 'מפתח וקונצל', 'כדור וקסדה'],
              correctAnswer: 0,
            ),
            const BossBattleTask(
              id: 'memory_mage_3',
              prompt: 'חיזרו על הסדרה: 🎵, 🔔, 🎵, ? ',
              choices: <String>['🎵', '🔔', '✨'],
              correctAnswer: 0,
            ),
          ],
        ),
        const BossBattle(
          id: 'sequence_guardian',
          name: 'שומרת הסדר',
          domain: BossBattleDomain.sequencing,
          recommendedLevel: 6,
          tasks: <BossBattleTask>[
            const BossBattleTask(
              id: 'sequence_guardian_1',
              prompt: 'גררו את השלבים לבניית מגדל קוביות',
              choices: <String>['בחירה חופשית', 'לסדר מהגדול לקטן, ואז לייצב', 'להתחיל מהקטן'],
              correctAnswer: 1,
            ),
            const BossBattleTask(
              id: 'sequence_guardian_2',
              prompt: 'מה מגיע אחרי תכנון, חימום קצר?',
              choices: <String>['מנוחה', 'התחלה מדורגת', 'לדלג לשלב האחרון'],
              correctAnswer: 1,
            ),
          ],
        ),
      ];

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.bossBattleState);
    if (serialized != null && serialized.isNotEmpty) {
      try {
        final stored = BossBattle.decodeList(serialized);
        for (final battle in stored) {
          if (_battles.containsKey(battle.id)) {
            _battles[battle.id] = battle;
          } else {
            _battles[battle.id] = battle;
          }
        }
      } catch (_) {
        // ignore
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.bossBattleState, BossBattle.encodeList(_battles.values));
  }
}
