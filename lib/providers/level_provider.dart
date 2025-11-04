import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelProvider with ChangeNotifier {
  static const String _kLevelKey = 'player_level';
  static const String _kExperienceKey = 'player_experience';
  
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
    _level = prefs.getInt(_kLevelKey) ?? 1;
    _experience = prefs.getInt(_kExperienceKey) ?? 0;
    notifyListeners();
  }

  Future<void> _saveLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLevelKey, _level);
    await prefs.setInt(_kExperienceKey, _experience);
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
      throw ArgumentError.value(multiplier, 'multiplier', 'Multiplier must be positive.');
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

