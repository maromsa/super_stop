import 'dart:convert';

enum Mood {
  happy,
  angry,
  sad,
  anxious,
  calm,
  excited,
}

class MoodEntry {
  MoodEntry({required this.mood, required this.timestamp});

  final Mood mood;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mood': mood.name,
        'timestamp': timestamp.toIso8601String(),
      };

  static MoodEntry fromJson(Map<String, dynamic> json) {
    final moodName = json['mood'] as String?;
    final timestampString = json['timestamp'] as String?;
    return MoodEntry(
      mood: Mood.values.firstWhere(
        (m) => m.name == moodName,
        orElse: () => Mood.happy,
      ),
      timestamp: timestampString != null
          ? DateTime.tryParse(timestampString) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static String encodeList(List<MoodEntry> entries) {
    final encoded = entries.map((entry) => entry.toJson()).toList();
    return jsonEncode(encoded);
  }

  static List<MoodEntry> decodeList(String source) {
    if (source.isEmpty) {
      return <MoodEntry>[];
    }
    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map((dynamic item) => MoodEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
