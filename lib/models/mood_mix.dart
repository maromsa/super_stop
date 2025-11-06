import 'dart:convert';

import '../models/mood_entry.dart';

class MoodMixLayer {
  const MoodMixLayer({
    required this.mood,
    required this.track,
    required this.volume,
  });

  final Mood mood;
  final String track;
  final double volume;

  MoodMixLayer copyWith({
    String? track,
    double? volume,
  }) {
    return MoodMixLayer(
      mood: mood,
      track: track ?? this.track,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mood': mood.name,
        'track': track,
        'volume': volume,
      };

  factory MoodMixLayer.fromJson(Map<String, dynamic> json) {
    final moodName = json['mood'] as String? ?? Mood.calm.name;
    return MoodMixLayer(
      mood: Mood.values.firstWhere(
        (value) => value.name == moodName,
        orElse: () => Mood.calm,
      ),
      track: json['track'] as String,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class MoodMixState {
  const MoodMixState({
    required this.layers,
    this.activeMood,
    this.lastPreviewedTrack,
  });

  final List<MoodMixLayer> layers;
  final Mood? activeMood;
  final String? lastPreviewedTrack;

  MoodMixState copyWith({
    List<MoodMixLayer>? layers,
    Mood? activeMood,
    bool clearActiveMood = false,
    String? lastPreviewedTrack,
    bool clearLastPreview = false,
  }) {
    return MoodMixState(
      layers: layers ?? this.layers,
      activeMood: clearActiveMood ? null : activeMood ?? this.activeMood,
      lastPreviewedTrack: clearLastPreview ? null : lastPreviewedTrack ?? this.lastPreviewedTrack,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'layers': layers.map((layer) => layer.toJson()).toList(growable: false),
        'activeMood': activeMood?.name,
        'lastPreviewedTrack': lastPreviewedTrack,
      };

  factory MoodMixState.fromJson(Map<String, dynamic> json) {
    final activeMoodName = json['activeMood'] as String?;
    final layersJson = json['layers'] as List<dynamic>? ?? <dynamic>[];
    return MoodMixState(
      layers: layersJson
          .map((entry) => MoodMixLayer.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
      activeMood: activeMoodName == null
          ? null
          : Mood.values.firstWhere(
              (value) => value.name == activeMoodName,
              orElse: () => Mood.calm,
            ),
      lastPreviewedTrack: json['lastPreviewedTrack'] as String?,
    );
  }

  static String encode(MoodMixState state) => jsonEncode(state.toJson());

  static MoodMixState decode(String value) {
    final decoded = jsonDecode(value) as Map<String, dynamic>;
    return MoodMixState.fromJson(decoded);
  }
}
