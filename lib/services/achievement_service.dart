import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';
import '../utils/prefs_keys.dart';

class AchievementService with ChangeNotifier {
  final List<Achievement> _achievements = [
    Achievement(id: 'impulse_score_10', icon: Icons.timer, emoji: '⏱️', color: Colors.blue),
    Achievement(id: 'reaction_time_250', icon: Icons.bolt, emoji: '⚡', color: Colors.orange),
    Achievement(id: 'stroop_score_20', icon: Icons.psychology, emoji: '🧠', color: Colors.purple),
    Achievement(id: 'play_all_three', icon: Icons.games, emoji: '🎮', color: Colors.green),
    Achievement(id: 'new_high_score', icon: Icons.trending_up, emoji: '📈', color: Colors.red),
    Achievement(id: 'streak_7', icon: Icons.local_fire_department, emoji: '🔥', color: Colors.deepOrange),
    Achievement(id: 'streak_30', icon: Icons.local_fire_department, emoji: '🔥', color: Colors.red),
    Achievement(id: 'focus_master', icon: Icons.school, emoji: '🎓', color: Colors.indigo),
    Achievement(id: 'coin_collector', icon: Icons.monetization_on, emoji: '💰', color: Colors.amber),
    Achievement(id: 'breathing_guru', icon: Icons.air, emoji: '🧘', color: Colors.teal),
  ];

  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements =>
      _achievements.where((ach) => ach.isUnlocked).toList(growable: false);

  AchievementService() {
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    for (var ach in _achievements) {
        ach.isUnlocked = prefs.getBool('${PrefsKeys.achievementsPrefix}${ach.id}') ?? false;
    }
    notifyListeners();
  }

  Future<String?> unlockAchievement(String id) async {
    final achievement = _achievements.firstWhere((ach) => ach.id == id, orElse: () => Achievement(id: 'not_found'));
    if (achievement.id == 'not_found' || achievement.isUnlocked) return null;

    achievement.isUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${PrefsKeys.achievementsPrefix}${achievement.id}', true);
    notifyListeners();
    return id; // Return the id to show popup
  }

  // This is the new method that was missing
  Future<String?> markGamePlayed(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${PrefsKeys.playedPrefix}$gameId', true);

      final playedImpulse = prefs.getBool('${PrefsKeys.playedPrefix}impulse') ?? false;
      final playedReaction = prefs.getBool('${PrefsKeys.playedPrefix}reaction') ?? false;
      final playedStroop = prefs.getBool('${PrefsKeys.playedPrefix}stroop') ?? false;

    if (playedImpulse && playedReaction && playedStroop) {
      return await unlockAchievement('play_all_three');
    }
    return null;
  }

  Achievement? getAchievement(String id) {
    try {
      return _achievements.firstWhere((ach) => ach.id == id);
    } catch (e) {
      return null;
    }
  }

  bool isAchievementUnlocked(String id) {
    return _achievements.any((ach) => ach.id == id && ach.isUnlocked);
  }

  Future<List<String>> unlockMultiple(Iterable<String> ids) async {
    final unlocked = <String>[];
    for (final id in ids) {
      final result = await unlockAchievement(id);
      if (result != null) {
        unlocked.add(result);
      }
    }
    return unlocked;
  }

  Future<void> resetAchievements({Iterable<String>? preserveIds}) async {
    final prefs = await SharedPreferences.getInstance();
    final preserved = preserveIds?.toSet() ?? <String>{};

    for (final achievement in _achievements) {
      if (preserved.contains(achievement.id)) {
        continue;
      }
      achievement.isUnlocked = false;
        await prefs.remove('${PrefsKeys.achievementsPrefix}${achievement.id}');
    }
    notifyListeners();
  }
}