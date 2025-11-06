import 'dart:convert';

class HabitStoryChapter {
  const HabitStoryChapter({
    required this.id,
    required this.dayIndex,
    required this.title,
    required this.body,
  });

  final String id;
  final int dayIndex;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'dayIndex': dayIndex,
        'title': title,
        'body': body,
      };

  factory HabitStoryChapter.fromJson(Map<String, dynamic> json) {
    return HabitStoryChapter(
      id: json['id'] as String,
      dayIndex: json['dayIndex'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

class HabitStoryBook {
  const HabitStoryBook({
    required this.heroName,
    required this.chapters,
  });

  final String heroName;
  final List<HabitStoryChapter> chapters;

  HabitStoryBook addChapter(HabitStoryChapter chapter) {
    if (chapters.any((existing) => existing.id == chapter.id)) {
      return this;
    }
    final updated = <HabitStoryChapter>[...chapters, chapter]
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    return HabitStoryBook(heroName: heroName, chapters: updated);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'heroName': heroName,
        'chapters': chapters.map((chapter) => chapter.toJson()).toList(growable: false),
      };

  factory HabitStoryBook.fromJson(Map<String, dynamic> json) {
    final chaptersJson = json['chapters'] as List<dynamic>? ?? <dynamic>[];
    return HabitStoryBook(
      heroName: json['heroName'] as String? ?? 'גיבור הקשב',
      chapters: chaptersJson
          .map((entry) => HabitStoryChapter.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static String encode(HabitStoryBook book) => jsonEncode(book.toJson());

  static HabitStoryBook decode(String value) {
    final decoded = jsonDecode(value) as Map<String, dynamic>;
    return HabitStoryBook.fromJson(decoded);
  }
}
