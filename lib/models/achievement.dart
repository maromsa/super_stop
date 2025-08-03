// lib/models/achievement.dart

class Achievement {
  final String id;
  bool isUnlocked;

  Achievement({
    required this.id,
    this.isUnlocked = false,
  });
}