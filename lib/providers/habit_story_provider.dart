import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_story.dart';
import '../utils/prefs_keys.dart';
import 'collectible_provider.dart';
import 'daily_goals_provider.dart';

class HabitStoryProvider with ChangeNotifier {
  HabitStoryProvider() {
    _hydrate();
  }

  HabitStoryBook _book = const HabitStoryBook(heroName: 'גיבור הקשב', chapters: <HabitStoryChapter>[]);
  int _lastStreakRecorded = 0;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  HabitStoryBook get book => _book;
  List<HabitStoryChapter> get chapters => _book.chapters;
  String get heroName => _book.heroName;

  Future<void> updateFromGoals(
    DailyGoalsProvider goals, {
    CollectibleProvider? collectibles,
  }) async {
    if (!_isLoaded) {
      return;
    }
    final streak = goals.streak;
    if (streak <= _lastStreakRecorded) {
      return;
    }
    final chapter = _buildChapterForStreak(streak);
    _book = _book.addChapter(chapter);
    _lastStreakRecorded = streak;
    await _persist();
    if (collectibles != null) {
      await collectibles.unlockCollectible('story_quill');
    }
    notifyListeners();
  }

  Future<void> renameHero(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _book.heroName) {
      return;
    }
    _book = HabitStoryBook(heroName: trimmed, chapters: _book.chapters);
    await _persist();
    notifyListeners();
  }

  Future<void> resetForTesting() async {
    _book = const HabitStoryBook(heroName: 'גיבור הקשב', chapters: <HabitStoryChapter>[]);
    _lastStreakRecorded = 0;
    await _persist();
    notifyListeners();
  }

  HabitStoryChapter _buildChapterForStreak(int streak) {
    final title = streak == 1
        ? 'התחלה נוצצת'
        : streak == 3
            ? 'צוות האיפוק'
            : streak == 5
                ? 'הפתעת הגחליליות'
                : 'פרק רצף $streak';
      final body = switch (streak) {
        1 => 'הדמות הראשית התחילה את מסע ההרגלים עם חיוך ומלווה מוסיקלי עליז.',
        2 => 'שלב שני: תכנון קלף משימות שמאיר את הדרך למשימות היום.',
        3 => 'צוות של חבר או בן משפחה מצטרף למסע ומוסיף קצב חדש.',
        4 => 'המנטורית הדיגיטלית מעניקה תג הוקרה ומעודדת להמשיך.',
        5 => 'הופעה של מפת סוד חדשה שמגלה משימת על חדשה ומבריקה.',
        _ => 'המסע נמשך: כל צעדי הרצף בונים את עולם הסיפור של הגיבור.',
      };
    return HabitStoryChapter(
      id: 'streak_$streak',
      dayIndex: streak,
      title: title,
      body: body,
    );
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.habitStoryState);
    if (serialized != null && serialized.isNotEmpty) {
      try {
        _book = HabitStoryBook.decode(serialized);
        _lastStreakRecorded = _book.chapters.isEmpty ? 0 : _book.chapters.map((c) => c.dayIndex).reduce((a, b) => a > b ? a : b);
      } catch (_) {
        _book = const HabitStoryBook(heroName: 'גיבור הקשב', chapters: <HabitStoryChapter>[]);
        _lastStreakRecorded = 0;
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.habitStoryState, HabitStoryBook.encode(_book));
  }
}
