import 'package:flutter/material.dart';
import 'achievements_screen.dart';
import 'impulse_control_game_screen.dart';
import 'reaction_time_screen.dart';
import 'stroop_test_screen.dart';
import 'settings_screen.dart';
import 'breathing_exercise_screen.dart';
import 'focus_timer_screen.dart';
import 'progress_dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_goals_provider.dart';
import '../providers/level_provider.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_popup.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('איך משחקים?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('משחק איפוק:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('חכה שהעיגול יתמלא וירוק, ואז לחץ מהר!'),
                SizedBox(height: 15),
                Text('מבחן תגובה:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('חכה שהמסך יהפוך לירוק, ואז לחץ מהר!'),
                SizedBox(height: 15),
                Text('מבחן סטרופ:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('לחץ על הכפתור שצבעו תואם לצבע המילה, לא למילה עצמה.'),
              ],
            ),
          ),
          actions: <Widget>[ TextButton(child: const Text('הבנתי'), onPressed: () => Navigator.of(context).pop()) ],
        );
      },
    );
  }

  void _showReactionModeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('בחר מצב משחק'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReactionTimeScreen(mode: ReactionMode.classic)));
              },
              child: const Text('קלאסי (אינסופי)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReactionTimeScreen(mode: ReactionMode.fiveRoundTest)));
              },
              child: const Text('מבחן (5 סיבובים)'),
            ),
          ],
        );
      },
    );
  }

  // --- New: Method to show the mode selection dialog ---
  void _showImpulseModeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('בחר צורת משחק'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpulseControlGameScreen(mode: GameMode.classic)));
              },
              child: const Text('קלאסי'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpulseControlGameScreen(mode: GameMode.survival)));
              },
              child: const Text('הישרדות'),
            ),
          ],
        );
      },
    );
  }

  void _showStroopModeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('בחר מצב משחק'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StroopTestScreen(mode: StroopMode.sprint)));
              },
              child: const Text('ספרינט (60 שניות)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StroopTestScreen(mode: StroopMode.accuracy)));
              },
              child: const Text('דיוק (טעות אחת פוסלת)'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Stop'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              backgroundColor: Colors.amber.shade100,
              avatar: const Icon(Icons.monetization_on, color: Colors.amber),
              label: Consumer<CoinProvider>(
                builder: (context, coinProvider, child) {
                  return Text(
                    '${coinProvider.coins}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'איך משחקים?',
            onPressed: () => _showInstructionsDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Level and Stats Display
            Consumer3<DailyGoalsProvider, LevelProvider, CoinProvider>(
              builder: (context, goalsProvider, levelProvider, coinProvider, child) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade300,
                        Colors.blue.shade300,
                        Colors.pink.shade300,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Level Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star, size: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'רמה ${levelProvider.level}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                levelProvider.levelTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: levelProvider.experienceProgress,
                          minHeight: 20,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${levelProvider.experience} / ${levelProvider.experienceForNextLevel} XP',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatBadge(
                            Icons.local_fire_department,
                            '${goalsProvider.streak}',
                            'רצף',
                            Colors.orange,
                          ),
                          _buildStatBadge(
                            Icons.flag,
                            '${goalsProvider.gamesPlayedToday}/${goalsProvider.dailyGoal}',
                            'מטרה',
                            Colors.green,
                          ),
                          _buildStatBadge(
                            Icons.monetization_on,
                            '${coinProvider.coins}',
                            'מטבעות',
                            Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            const Text('בחר אתגר', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Games Section
            _GameSelectionButton(
              label: 'משחק איפוק',
              icon: Icons.timer,
              onPressed: () {
                _handleGamePlayed(context, 'impulse');
                _showImpulseModeSelector(context);
              },
            ),
            const SizedBox(height: 15),
            _GameSelectionButton(
              label: 'מבחן תגובה',
              icon: Icons.bolt,
              onPressed: () {
                _handleGamePlayed(context, 'reaction');
                _showReactionModeSelector(context);
              },
            ),
            const SizedBox(height: 15),
            _GameSelectionButton(
              label: 'מבחן סטרופ',
              icon: Icons.psychology,
              onPressed: () {
                _handleGamePlayed(context, 'stroop');
                _showStroopModeSelector(context);
              },
            ),
            
            const SizedBox(height: 30),
            const Text('כלים נוספים', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // ADHD Support Tools
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _CompactButton(
                      label: 'תרגיל נשימה',
                      icon: Icons.air,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BreathingExerciseScreen()),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _CompactButton(
                      label: 'טיימר ריכוז',
                      icon: Icons.timer_outlined,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FocusTimerScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _CompactButton(
                      label: 'לוח התקדמות',
                      icon: Icons.dashboard,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProgressDashboardScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('הישגים'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()));
                  },
                ),
                const SizedBox(width: 20),
                TextButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('הגדרות'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGamePlayed(BuildContext context, String gameId) async {
    final goalsProvider = Provider.of<DailyGoalsProvider>(context, listen: false);
    final levelProvider = Provider.of<LevelProvider>(context, listen: false);
    final achievementService = Provider.of<AchievementService>(context, listen: false);
    
    goalsProvider.markGamePlayed();
    final leveledUp = await levelProvider.addExperience(10);
    
    final achievementId = await achievementService.markGamePlayed(gameId);
    
    if (!context.mounted) return;
    
    if (achievementId != null) {
      _showAchievementPopup(context, achievementService, achievementId);
    }
    
    // Check for streak achievements
    if (goalsProvider.streak == 7) {
      final id = await achievementService.unlockAchievement('streak_7');
      if (!context.mounted) return;
      if (id != null) _showAchievementPopup(context, achievementService, id);
    } else if (goalsProvider.streak == 30) {
      final id = await achievementService.unlockAchievement('streak_30');
      if (!context.mounted) return;
      if (id != null) _showAchievementPopup(context, achievementService, id);
    }
    
    // Check for level up
    if (leveledUp) {
      if (!context.mounted) return;
      _showLevelUpDialog(context, levelProvider);
    }
  }

  void _showAchievementPopup(BuildContext context, AchievementService service, String achievementId) {
    final achievement = service.getAchievement(achievementId);
    if (achievement == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementPopup(
        title: _getAchievementTitle(achievementId),
        description: _getAchievementDescription(achievementId),
        icon: achievement.icon ?? Icons.emoji_events,
        color: achievement.color ?? Colors.amber,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showLevelUpDialog(BuildContext context, LevelProvider levelProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 עלית רמה! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('כל הכבוד!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('רמה ${levelProvider.level} - ${levelProvider.levelTitle}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('מעולה!'),
          ),
        ],
      ),
    );
  }

  String _getAchievementTitle(String id) {
    switch (id) {
      case 'impulse_score_10': return 'זן למתחילים';
      case 'reaction_time_250': return 'מהיר כברק';
      case 'stroop_score_20': return 'ריכוז שיא';
      case 'play_all_three': return 'אלוף השלישייה';
      case 'new_high_score': return 'שובר שיאים';
      case 'streak_7': return 'שבוע ברצף';
      case 'streak_30': return 'חודש ברצף';
      case 'focus_master': return 'מאסטר ריכוז';
      case 'coin_collector': return 'אספן מטבעות';
      case 'breathing_guru': return 'מאסטר נשימה';
      default: return 'הישג חדש!';
    }
  }

  String _getAchievementDescription(String id) {
    switch (id) {
      case 'impulse_score_10': return 'השגת ניקוד 10 במשחק האיפוק';
      case 'reaction_time_250': return 'השגת זמן תגובה מהיר מאוד';
      case 'stroop_score_20': return 'ענית נכון 20 פעמים';
      case 'play_all_three': return 'שחקת בכל שלושת המשחקים';
      case 'new_high_score': return 'קבעת שיא חדש';
      case 'streak_7': return 'שחקת 7 ימים ברצף';
      case 'streak_30': return 'שחקת 30 ימים ברצף';
      case 'focus_master': return 'השלמת 10 מפגשי ריכוז';
      case 'coin_collector': return 'אספת 100 מטבעות';
      case 'breathing_guru': return 'השלמת 20 מחזורי נשימה';
      default: return 'כל הכבוד על ההישג!';
    }
  }
}


class _GameSelectionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _GameSelectionButton({required this.label, required this.icon, required this.onPressed});

  @override
  State<_GameSelectionButton> createState() => _GameSelectionButtonState();
}

class _GameSelectionButtonState extends State<_GameSelectionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 280,
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 32, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _CompactButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}