import 'dart:convert';

enum CollectibleRarity { common, rare, epic, legendary }

class Collectible {
  const Collectible({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final CollectibleRarity rarity;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  Collectible copyWith({
    DateTime? unlockedAt,
  }) {
    return Collectible(
      id: id,
      name: name,
      description: description,
      icon: icon,
      rarity: rarity,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'rarity': rarity.name,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Collectible.fromJson(Map<String, dynamic> json) {
    final rarityName = json['rarity'] as String? ?? CollectibleRarity.common.name;
    return Collectible(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      rarity: CollectibleRarity.values.firstWhere(
        (value) => value.name == rarityName,
        orElse: () => CollectibleRarity.common,
      ),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
    );
  }

  static String encodeList(Iterable<Collectible> collectibles) {
    final encoded = collectibles.map((item) => item.toJson()).toList(growable: false);
    return jsonEncode(encoded);
  }

  static List<Collectible> decodeList(String value) {
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map((entry) => Collectible.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }
}
