import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:super_stop/l10n/app_localizations.dart';

import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementsScreen extends StatelessWidget {
  // --- This is the constructor that was missing ---
  const AchievementsScreen({super.key});

  // Helper function with hardcoded Hebrew text
  String _getTitle(BuildContext context, String id) {
    switch (id) {
      case 'impulse_score_10': return '⏱️ זן למתחילים';
      case 'reaction_time_250': return '⚡ מהיר כברק';
      case 'stroop_score_20': return '🧠 ריכוז שיא';
      case 'play_all_three': return '🎮 אלוף השלישייה';
      case 'new_high_score': return '📈 שובר שיאים';
      case 'streak_7': return '🔥 שבוע ברצף';
      case 'streak_30': return '🔥 חודש ברצף';
      case 'focus_master': return '🎓 מאסטר ריכוז';
      case 'coin_collector': return '💰 אספן מטבעות';
        case 'breathing_guru': return '🧘 מאסטר נשימה';
        default: return AppLocalizations.of(context)!.achievementUnknown;
    }
  }

  String _getDescription(BuildContext context, String id) {
    switch (id) {
      case 'impulse_score_10': return 'השג ניקוד 10 במשחק האיפוק';
      case 'reaction_time_250': return 'השג זמן תגובה של פחות מ-250ms';
      case 'stroop_score_20': return 'ענה נכון 20 פעמים במבחן סטרופ';
      case 'play_all_three': return 'שחק בכל שלושת המשחקים';
      case 'new_high_score': return 'קבע שיא חדש בכל משחק שהוא';
      case 'streak_7': return 'שחק 7 ימים ברצף';
      case 'streak_30': return 'שחק 30 ימים ברצף';
      case 'focus_master': return 'השלם 10 מפגשי ריכוז';
      case 'coin_collector': return 'אסוף 100 מטבעות';
      case 'breathing_guru': return 'השלם 20 מחזורי נשימה';
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
            padding: const EdgeInsets.all(8),
            itemCount: achievementService.achievements.length,
            itemBuilder: (context, index) {
              final Achievement achievement = achievementService.achievements[index];
              final isUnlocked = achievement.isUnlocked;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: isUnlocked ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isUnlocked && achievement.color != null
                        ? LinearGradient(
                            colors: [
                              achievement.color!.withOpacity(0.3),
                              achievement.color!.withOpacity(0.1),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? (achievement.color ?? Colors.amber).withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        achievement.emoji ?? (isUnlocked ? '🏆' : '🔒'),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    title: Text(
                      _getTitle(context, achievement.id),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? null : Colors.grey,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      _getDescription(context, achievement.id),
                      style: TextStyle(
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    trailing: isUnlocked
                        ? Icon(
                            achievement.icon ?? Icons.emoji_events,
                            color: achievement.color ?? Colors.amber,
                            size: 30,
                          )
                        : const Icon(Icons.lock, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}