import 'package:flutter/material.dart';

import '../models/mood_entry.dart';

class MoodUtils {
  static const Map<Mood, String> _labelKeys = <Mood, String>{
    Mood.happy: 'moodHappy',
    Mood.angry: 'moodAngry',
    Mood.sad: 'moodSad',
    Mood.anxious: 'moodAnxious',
    Mood.calm: 'moodCalm',
    Mood.excited: 'moodExcited',
  };

  static const Map<Mood, String> _emoji = <Mood, String>{
    Mood.happy: '😄',
    Mood.angry: '😡',
    Mood.sad: '😢',
    Mood.anxious: '😰',
    Mood.calm: '😌',
    Mood.excited: '🤩',
  };

  static const Map<Mood, List<Color>> _gradients = <Mood, List<Color>>{
    Mood.happy: <Color>[Color(0xFFFBC02D), Color(0xFFFFEB3B)],
    Mood.angry: <Color>[Color(0xFFE53935), Color(0xFFEF5350)],
    Mood.sad: <Color>[Color(0xFF1E88E5), Color(0xFF64B5F6)],
    Mood.anxious: <Color>[Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    Mood.calm: <Color>[Color(0xFF26A69A), Color(0xFF4DB6AC)],
    Mood.excited: <Color>[Color(0xFFFF6F00), Color(0xFFFFA000)],
  };

  static String labelKeyOf(Mood mood) => _labelKeys[mood] ?? 'moodHappy';
  static String emojiOf(Mood mood) => _emoji[mood] ?? '😄';
  static List<Color> gradientOf(Mood mood) => _gradients[mood] ?? _gradients[Mood.happy]!;
}
