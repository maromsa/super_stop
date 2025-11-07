import 'mood_entry.dart';

/// An immutable snapshot of the mood journal state that can be persisted
/// remotely and restored locally.
class MoodJournalStateSnapshot {
  MoodJournalStateSnapshot({
    required List<MoodEntry> entries,
    required this.onboardingCompleted,
    this.lastCheckIn,
  }) : entries = List<MoodEntry>.unmodifiable(entries);

  final List<MoodEntry> entries;
  final bool onboardingCompleted;
  final DateTime? lastCheckIn;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'onboardingCompleted': onboardingCompleted,
        'lastCheckIn': lastCheckIn?.toIso8601String(),
      };

  static MoodJournalStateSnapshot fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => MoodEntry.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final lastCheckInRaw = json['lastCheckIn'];
    DateTime? lastCheckIn;
    if (lastCheckInRaw is String && lastCheckInRaw.isNotEmpty) {
      lastCheckIn = DateTime.tryParse(lastCheckInRaw);
    }

    return MoodJournalStateSnapshot(
      entries: entries,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      lastCheckIn: lastCheckIn,
    );
  }
}
