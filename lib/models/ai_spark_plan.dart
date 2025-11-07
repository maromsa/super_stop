import 'package:flutter/foundation.dart';

/// Represents a highlighted AI suggestion card with supporting metadata.
@immutable
class AiSparkCard {
  const AiSparkCard({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.route,
    this.tags = const <String>[],
  });

  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> tags;
  final String? route;
}

/// Describes a playful micro-mission that the AI recommends.
@immutable
class AiSparkMission {
  const AiSparkMission({
    required this.id,
    required this.emoji,
    required this.label,
    this.route,
    this.rewardHint,
  });

  final String id;
  final String emoji;
  final String label;
  final String? route;
  final String? rewardHint;
}

/// Container for the full AI Spark Lab experience payload.
@immutable
class AiSparkPlan {
  const AiSparkPlan({
    required this.generatedAt,
    required this.focusCard,
    required this.breakCard,
    required this.challengeCard,
    required this.missions,
    required this.energyLevelLabel,
    required this.energyLevelScore,
  });

  final DateTime generatedAt;
  final AiSparkCard focusCard;
  final AiSparkCard breakCard;
  final AiSparkCard challengeCard;
  final List<AiSparkMission> missions;
  final String energyLevelLabel;
  final int energyLevelScore;
}
