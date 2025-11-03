// lib/models/achievement.dart

import 'package:flutter/material.dart';

class Achievement {
  final String id;
  bool isUnlocked;
  final IconData? icon;
  final String? emoji;
  final Color? color;

  Achievement({
    required this.id,
    this.isUnlocked = false,
    this.icon,
    this.emoji,
    this.color,
  });
}