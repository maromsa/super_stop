import 'dart:convert';

enum CalmPowerUpType { bonusCoins, mysteryBoost, companionGlow }

class CalmPowerUp {
  const CalmPowerUp({
    required this.id,
    required this.type,
    required this.label,
    required this.description,
    required this.value,
    this.earnedAt,
    this.consumedAt,
  });

  final String id;
  final CalmPowerUpType type;
  final String label;
  final String description;
  final int value;
  final DateTime? earnedAt;
  final DateTime? consumedAt;

  bool get isActive => consumedAt == null;

  CalmPowerUp markConsumed(DateTime dateTime) => CalmPowerUp(
        id: id,
        type: type,
        label: label,
        description: description,
        value: value,
        earnedAt: earnedAt,
        consumedAt: dateTime,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'label': label,
        'description': description,
        'value': value,
        'earnedAt': earnedAt?.toIso8601String(),
        'consumedAt': consumedAt?.toIso8601String(),
      };

  factory CalmPowerUp.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? CalmPowerUpType.bonusCoins.name;
    return CalmPowerUp(
      id: json['id'] as String,
      type: CalmPowerUpType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => CalmPowerUpType.bonusCoins,
      ),
      label: json['label'] as String,
      description: json['description'] as String,
      value: json['value'] as int? ?? 0,
      earnedAt: json['earnedAt'] != null ? DateTime.tryParse(json['earnedAt'] as String) : null,
      consumedAt: json['consumedAt'] != null ? DateTime.tryParse(json['consumedAt'] as String) : null,
    );
  }

  static String encodeList(Iterable<CalmPowerUp> powerUps) {
    final encoded = powerUps.map((item) => item.toJson()).toList(growable: false);
    return jsonEncode(encoded);
  }

  static List<CalmPowerUp> decodeList(String serialized) {
    final decoded = jsonDecode(serialized) as List<dynamic>;
    return decoded
        .map((entry) => CalmPowerUp.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }
}
