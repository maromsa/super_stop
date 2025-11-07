import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mood_entry.dart';
import '../models/mood_journal_state_snapshot.dart';

class UserStateRepository {
  UserStateRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<MoodJournalStateSnapshot?> fetchMoodJournal(String uid) async {
    final doc = await _moodJournalDocument(uid).get();
    final data = doc.data();
    if (data == null) {
      return null;
    }

    final entries = (data['entries'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) {
          final map = item as Map<String, dynamic>?;
          final moodName = map?['mood'] as String?;
          final timestamp = map?['timestamp'];
          final asDate = timestamp is Timestamp ? timestamp.toDate() : DateTime.tryParse('$timestamp');
          return MoodEntry(
            mood: Mood.values.firstWhere(
              (mood) => mood.name == moodName,
              orElse: () => Mood.happy,
            ),
            timestamp: asDate ?? DateTime.now(),
          );
        })
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final lastCheckInRaw = data['lastCheckIn'];
    DateTime? lastCheckIn;
    if (lastCheckInRaw is Timestamp) {
      lastCheckIn = lastCheckInRaw.toDate();
    } else if (lastCheckInRaw is String) {
      lastCheckIn = DateTime.tryParse(lastCheckInRaw);
    }

    return MoodJournalStateSnapshot(
      entries: entries,
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      lastCheckIn: lastCheckIn,
    );
  }

  Future<void> saveMoodJournal(String uid, MoodJournalStateSnapshot snapshot) async {
    final entries = snapshot.entries
        .map((entry) => <String, dynamic>{
              'mood': entry.mood.name,
              'timestamp': Timestamp.fromDate(entry.timestamp),
            })
        .toList();

    await _moodJournalDocument(uid).set(
      <String, dynamic>{
        'entries': entries,
        'onboardingCompleted': snapshot.onboardingCompleted,
        'lastCheckIn': snapshot.lastCheckIn != null ? Timestamp.fromDate(snapshot.lastCheckIn!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  DocumentReference<Map<String, dynamic>> _moodJournalDocument(String uid) {
    return _firestore.collection('users').doc(uid).collection('appState').doc('moodJournal');
  }
}
