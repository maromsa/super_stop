import 'dart:convert';

enum FocusBurstDifficulty { mellow, balanced, turbo }

class FocusBurstCue {
  const FocusBurstCue({
    required this.prompt,
    required this.durationSeconds,
    required this.sensoryColor,
  });

  final String prompt;
  final int durationSeconds;
  final int sensoryColor;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'prompt': prompt,
        'durationSeconds': durationSeconds,
        'sensoryColor': sensoryColor,
      };

  factory FocusBurstCue.fromJson(Map<String, dynamic> json) {
    return FocusBurstCue(
      prompt: json['prompt'] as String,
      durationSeconds: json['durationSeconds'] as int,
      sensoryColor: json['sensoryColor'] as int,
    );
  }
}

class FocusBurstPlan {
  const FocusBurstPlan({
    required this.id,
    required this.difficulty,
    required this.cues,
    required this.breathCount,
    required this.targetReactions,
  });

  final String id;
  final FocusBurstDifficulty difficulty;
  final List<FocusBurstCue> cues;
  final int breathCount;
  final int targetReactions;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'difficulty': difficulty.name,
        'cues': cues.map((cue) => cue.toJson()).toList(growable: false),
        'breathCount': breathCount,
        'targetReactions': targetReactions,
      };

  factory FocusBurstPlan.fromJson(Map<String, dynamic> json) {
    final difficultyName = json['difficulty'] as String? ?? FocusBurstDifficulty.mellow.name;
    final cuesJson = json['cues'] as List<dynamic>? ?? <dynamic>[];
    return FocusBurstPlan(
      id: json['id'] as String,
      difficulty: FocusBurstDifficulty.values.firstWhere(
        (value) => value.name == difficultyName,
        orElse: () => FocusBurstDifficulty.mellow,
      ),
      cues: cuesJson
          .map((entry) => FocusBurstCue.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
      breathCount: json['breathCount'] as int? ?? 3,
      targetReactions: json['targetReactions'] as int? ?? 5,
    );
  }

  static String encode(FocusBurstPlan plan) => jsonEncode(plan.toJson());

  static FocusBurstPlan? tryDecode(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(value) as Map<String, dynamic>;
    return FocusBurstPlan.fromJson(decoded);
  }
}

class FocusBurstResult {
  const FocusBurstResult({
    required this.planId,
    required this.completed,
    required this.averageReactionMs,
  });

  final String planId;
  final bool completed;
  final double averageReactionMs;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'planId': planId,
        'completed': completed,
        'averageReactionMs': averageReactionMs,
      };

  factory FocusBurstResult.fromJson(Map<String, dynamic> json) {
    return FocusBurstResult(
      planId: json['planId'] as String,
      completed: json['completed'] as bool? ?? false,
      averageReactionMs: (json['averageReactionMs'] as num?)?.toDouble() ?? 0,
    );
  }
}
