import 'dart:convert';

enum DailyQuestKind { skill, creative }

class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.goal,
    this.progress = 0,
    this.rewardCollectibleId,
    this.skillTrigger,
    this.coinReward = 0,
  });

  final String id;
  final DailyQuestKind kind;
  final String title;
  final String description;
  final int goal;
  final int progress;
  final String? rewardCollectibleId;
  final String? skillTrigger;
  final int coinReward;

  bool get isCompleted => progress >= goal;
  bool get isClaimable => isCompleted;
  bool get isCreative => kind == DailyQuestKind.creative;

  DailyQuest copyWith({
    int? progress,
  }) {
    return DailyQuest(
      id: id,
      kind: kind,
      title: title,
      description: description,
      goal: goal,
      progress: progress ?? this.progress,
      rewardCollectibleId: rewardCollectibleId,
      skillTrigger: skillTrigger,
      coinReward: coinReward,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'title': title,
        'description': description,
        'goal': goal,
        'progress': progress,
        'rewardCollectibleId': rewardCollectibleId,
        'skillTrigger': skillTrigger,
        'coinReward': coinReward,
      };

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? DailyQuestKind.skill.name;
    return DailyQuest(
      id: json['id'] as String,
      kind: DailyQuestKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => DailyQuestKind.skill,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      goal: json['goal'] as int,
      progress: json['progress'] as int? ?? 0,
      rewardCollectibleId: json['rewardCollectibleId'] as String?,
      skillTrigger: json['skillTrigger'] as String?,
      coinReward: json['coinReward'] as int? ?? 0,
    );
  }

  static String encodeList(Iterable<DailyQuest> quests) {
    final encoded = quests.map((quest) => quest.toJson()).toList(growable: false);
    return jsonEncode(encoded);
  }

  static List<DailyQuest> decodeList(String value) {
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map((entry) => DailyQuest.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }
}
