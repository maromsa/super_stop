import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

class AchievementService with ChangeNotifier {
  final List<Achievement> _achievements = [
    Achievement(id: 'impulse_score_10'),
    Achievement(id: 'reaction_time_250'),
    Achievement(id: 'stroop_score_20'),
    Achievement(id: 'play_all_three'),
    Achievement(id: 'new_high_score'),
  ];

  List<Achievement> get achievements => _achievements;

  AchievementService() {
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    for (var ach in _achievements) {
      ach.isUnlocked = prefs.getBool('ach_${ach.id}') ?? false;
    }
    notifyListeners();
  }

  Future<void> unlockAchievement(String id) async {
    final achievement = _achievements.firstWhere((ach) => ach.id == id, orElse: () => Achievement(id: 'not_found'));
    if (achievement.id == 'not_found' || achievement.isUnlocked) return;

    achievement.isUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ach_${achievement.id}', true);
    notifyListeners();
    print('Achievement Unlocked: $id');
  }

  // This is the new method that was missing
  Future<void> markGamePlayed(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('played_$gameId', true);

    final playedImpulse = prefs.getBool('played_impulse') ?? false;
    final playedReaction = prefs.getBool('played_reaction') ?? false;
    final playedStroop = prefs.getBool('played_stroop') ?? false;

    if (playedImpulse && playedReaction && playedStroop) {
      unlockAchievement('play_all_three');
    }
  }
}