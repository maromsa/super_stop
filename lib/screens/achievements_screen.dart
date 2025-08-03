import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementsScreen extends StatelessWidget {
  // --- This is the constructor that was missing ---
  const AchievementsScreen({super.key});

  // Helper function with hardcoded Hebrew text
  String _getTitle(BuildContext context, String id) {
    switch (id) {
      case 'impulse_score_10': return 'זן למתחילים';
      case 'reaction_time_250': return 'מהיר כברק';
      case 'stroop_score_20': return 'ריכוז שיא';
      case 'play_all_three': return 'אלוף השלישייה';
      case 'new_high_score': return 'שובר שיאים';
      default: return 'Unknown Achievement';
    }
  }

  String _getDescription(BuildContext context, String id) {
    switch (id) {
      case 'impulse_score_10': return 'השג ניקוד 10 במשחק האיפוק.';
      case 'reaction_time_250': return 'השג זמן תגובה של פחות מ-250ms.';
      case 'stroop_score_20': return 'ענה נכון 20 פעמים במבחן סטרופ.';
      case 'play_all_three': return 'שחק בכל שלושת המשחקים.';
      case 'new_high_score': return 'קבע שיא חדש בכל משחק שהוא.';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('הישגים'),
          ),
          body: ListView.builder(
            itemCount: achievementService.achievements.length,
            itemBuilder: (context, index) {
              final Achievement achievement = achievementService.achievements[index];
              return ListTile(
                leading: Icon(
                  achievement.isUnlocked ? Icons.emoji_events : Icons.lock,
                  color: achievement.isUnlocked ? Colors.amber : Colors.grey,
                  size: 40,
                ),
                title: Text(
                  _getTitle(context, achievement.id),
                  style: TextStyle(color: achievement.isUnlocked ? null : Colors.grey),
                ),
                subtitle: Text(
                  _getDescription(context, achievement.id),
                  style: TextStyle(color: achievement.isUnlocked ? null : Colors.grey),
                ),
              );
            },
          ),
        );
      },
    );
  }
}