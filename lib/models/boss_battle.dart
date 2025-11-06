import 'dart:convert';

enum BossBattleDomain { planning, workingMemory, sequencing }

class BossBattleTask {
  const BossBattleTask({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.correctAnswer,
  });

  final String id;
  final String prompt;
  final List<String> choices;
  final int correctAnswer;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'prompt': prompt,
        'choices': choices,
        'correctAnswer': correctAnswer,
      };

  factory BossBattleTask.fromJson(Map<String, dynamic> json) {
    final choicesJson = json['choices'] as List<dynamic>? ?? <dynamic>[];
    return BossBattleTask(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      choices: choicesJson.map((choice) => choice as String).toList(growable: false),
      correctAnswer: json['correctAnswer'] as int? ?? 0,
    );
  }
}

class BossBattle {
  const BossBattle({
    required this.id,
    required this.name,
    required this.domain,
    required this.tasks,
    required this.recommendedLevel,
    this.completed = false,
  });

  final String id;
  final String name;
  final BossBattleDomain domain;
  final List<BossBattleTask> tasks;
  final int recommendedLevel;
  final bool completed;

  BossBattle markCompleted() => BossBattle(
        id: id,
        name: name,
        domain: domain,
        tasks: tasks,
        recommendedLevel: recommendedLevel,
        completed: true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'domain': domain.name,
        'tasks': tasks.map((task) => task.toJson()).toList(growable: false),
        'recommendedLevel': recommendedLevel,
        'completed': completed,
      };

  factory BossBattle.fromJson(Map<String, dynamic> json) {
    final domainName = json['domain'] as String? ?? BossBattleDomain.planning.name;
    final tasksJson = json['tasks'] as List<dynamic>? ?? <dynamic>[];
    return BossBattle(
      id: json['id'] as String,
      name: json['name'] as String,
      domain: BossBattleDomain.values.firstWhere(
        (value) => value.name == domainName,
        orElse: () => BossBattleDomain.planning,
      ),
      tasks: tasksJson
          .map((entry) => BossBattleTask.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
      recommendedLevel: json['recommendedLevel'] as int? ?? 1,
      completed: json['completed'] as bool? ?? false,
    );
  }

  static String encodeList(Iterable<BossBattle> battles) {
    final encoded = battles.map((battle) => battle.toJson()).toList(growable: false);
    return jsonEncode(encoded);
  }

  static List<BossBattle> decodeList(String value) {
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map((entry) => BossBattle.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }
}
