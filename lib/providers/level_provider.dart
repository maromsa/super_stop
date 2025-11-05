import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/prefs_keys.dart';

class LevelProvider with ChangeNotifier {
  int _level = 1;
  int _experience = 0;

  int get level => _level;
  int get experience => _experience;
  int get experienceForNextLevel => _level * 100;
  double get experienceProgress => _experience / experienceForNextLevel;
  String get levelTitle => _getLevelTitle(_level);
  double get experiencePercentage => (experienceProgress.clamp(0.0, 1.0)) * 100;

  LevelProvider() {
    _loadLevel();
  }

  String _getLevelTitle(int level) {
    if (level < 5) return 'מתחיל';
    if (level < 10) return 'מתקדם';
    if (level < 15) return 'מומחה';
    if (level < 20) return 'אמן';
    if (level < 25) return 'מאסטר';
    return 'אגדה';
  }

  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    _level = prefs.getInt(PrefsKeys.playerLevel) ?? 1;
    _experience = prefs.getInt(PrefsKeys.playerExperience) ?? 0;
    notifyListeners();
  }

  Future<void> _saveLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.playerLevel, _level);
    await prefs.setInt(PrefsKeys.playerExperience, _experience);
    notifyListeners();
  }

  Future<bool> addExperience(int amount) async {
    final oldLevel = _level;
    _experience += amount;
    
    while (_experience >= experienceForNextLevel) {
      _experience -= experienceForNextLevel;
      _level++;
    }
    
    await _saveLevel();
    
    if (_level > oldLevel) {
      return true; // Leveled up!
    }
    return false;
  }

  Future<bool> addExperienceWithBonus(int baseAmount, {double multiplier = 1.0}) {
    if (multiplier < 0) {
      throw ArgumentError.value(multiplier, 'multiplier', 'המקדם חייב להיות חיובי.');
    }
    final boostedAmount = (baseAmount * multiplier).round();
    return addExperience(boostedAmount);
  }

  Future<void> resetProgress() async {
    _level = 1;
    _experience = 0;
    await _saveLevel();
  }

  int getTotalExperience() {
    int total = 0;
    for (int i = 1; i < _level; i++) {
      total += i * 100;
    }
    return total + _experience;
  }
}

