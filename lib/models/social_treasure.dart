import 'dart:convert';

class TreasureContributor {
  const TreasureContributor({
    required this.name,
    required this.clueId,
    required this.completedAt,
  });

  final String name;
  final String clueId;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'clueId': clueId,
        'completedAt': completedAt.toIso8601String(),
      };

  factory TreasureContributor.fromJson(Map<String, dynamic> json) {
    return TreasureContributor(
      name: json['name'] as String,
      clueId: json['clueId'] as String,
      completedAt: DateTime.tryParse(json['completedAt'] as String) ?? DateTime.now(),
    );
  }
}

class TreasureClue {
  const TreasureClue({
    required this.id,
    required this.prompt,
    this.isSolved = false,
  });

  final String id;
  final String prompt;
  final bool isSolved;

  TreasureClue markSolved() => TreasureClue(
        id: id,
        prompt: prompt,
        isSolved: true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'prompt': prompt,
        'isSolved': isSolved,
      };

  factory TreasureClue.fromJson(Map<String, dynamic> json) {
    return TreasureClue(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      isSolved: json['isSolved'] as bool? ?? false,
    );
  }
}

class TreasureHunt {
  const TreasureHunt({
    required this.id,
    required this.title,
    required this.theme,
    required this.clues,
    required this.code,
    this.contributors = const <TreasureContributor>[],
  });

  final String id;
  final String title;
  final String theme;
  final List<TreasureClue> clues;
  final String code;
  final List<TreasureContributor> contributors;

  bool get isComplete => clues.every((clue) => clue.isSolved);
  int get solvedCount => clues.where((clue) => clue.isSolved).length;

  TreasureHunt markClueSolved(String clueId, TreasureContributor contributor) {
    final updatedClues = clues
        .map((clue) => clue.id == clueId ? clue.markSolved() : clue)
        .toList(growable: false);
    final updatedContributors = <TreasureContributor>[...contributors, contributor];
    return TreasureHunt(
      id: id,
      title: title,
      theme: theme,
      clues: updatedClues,
      code: code,
      contributors: updatedContributors,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'theme': theme,
        'code': code,
        'clues': clues.map((clue) => clue.toJson()).toList(growable: false),
        'contributors': contributors.map((c) => c.toJson()).toList(growable: false),
      };

  factory TreasureHunt.fromJson(Map<String, dynamic> json) {
    final cluesJson = json['clues'] as List<dynamic>? ?? <dynamic>[];
    final contributorsJson = json['contributors'] as List<dynamic>? ?? <dynamic>[];
    return TreasureHunt(
      id: json['id'] as String,
      title: json['title'] as String,
      theme: json['theme'] as String,
      code: json['code'] as String,
      clues: cluesJson
          .map((entry) => TreasureClue.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
      contributors: contributorsJson
          .map((entry) => TreasureContributor.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static String encodeList(Iterable<TreasureHunt> hunts) {
    final encoded = hunts.map((hunt) => hunt.toJson()).toList(growable: false);
    return jsonEncode(encoded);
  }

  static List<TreasureHunt> decodeList(String value) {
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map((entry) => TreasureHunt.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }
}
