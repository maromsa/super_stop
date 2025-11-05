import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:super_stop/l10n/app_localizations.dart';

import '../models/mood_entry.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_goals_provider.dart';
import '../providers/level_provider.dart';
import '../providers/mood_journal_provider.dart';
import '../router/app_routes.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_popup.dart';
import 'impulse_control_game_screen.dart' show GameMode;
import 'reaction_time_screen.dart' show ReactionMode;
import 'stroop_test_screen.dart' show StroopMode;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showInstructionsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.homeInstructionsTitle),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(l10n.homeInstructionsImpulseTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(l10n.homeInstructionsImpulseBody),
                const SizedBox(height: 15),
                Text(l10n.homeInstructionsReactionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(l10n.homeInstructionsReactionBody),
                const SizedBox(height: 15),
                Text(l10n.homeInstructionsStroopTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(l10n.homeInstructionsStroopBody),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.homeInstructionsClose),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showReactionModeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.homeReactionModeTitle),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.reaction,
                  arguments: ReactionMode.classic,
                );
              },
              child: Text(l10n.homeReactionModeEndless),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.reaction,
                  arguments: ReactionMode.fiveRoundTest,
                );
              },
              child: Text(l10n.homeReactionModeTest),
            ),
          ],
        );
      },
    );
  }

  // --- New: Method to show the mode selection dialog ---
  void _showImpulseModeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.homeImpulseModeTitle),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.impulse,
                  arguments: GameMode.classic,
                );
              },
              child: Text(l10n.homeImpulseModeClassic),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.impulse,
                  arguments: GameMode.survival,
                );
              },
              child: Text(l10n.homeImpulseModeSurvival),
            ),
          ],
        );
      },
    );
  }

  void _showStroopModeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.homeStroopModeTitle),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.stroop,
                  arguments: StroopMode.sprint,
                );
              },
              child: Text(l10n.homeStroopModeSprint),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.stroop,
                  arguments: StroopMode.accuracy,
                );
              },
              child: Text(l10n.homeStroopModeAccuracy),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
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
              tooltip: l10n.homeInstructionsTooltip,
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
                            l10n.homeExperienceProgress(levelProvider.experience, levelProvider.experienceForNextLevel),
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
                              l10n.homeStatStreak,
                              Colors.orange,
                            ),
                            _buildStatBadge(
                              Icons.flag,
                              '${goalsProvider.gamesPlayedToday}/${goalsProvider.dailyGoal}',
                              l10n.homeStatGoal,
                              Colors.green,
                            ),
                            _buildStatBadge(
                              Icons.monetization_on,
                              '${coinProvider.coins}',
                              l10n.homeStatCoins,
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
              Consumer<MoodJournalProvider>(
                builder: (context, journal, _) {
                  final latest = journal.latestEntry;
                  final hasCheckIn = journal.hasCheckInToday;
                  final moodLabel = latest != null ? _resolveMoodLabel(latest.mood, l10n) : null;
                  final timeText = latest != null
                      ? l10n.moodCheckInLastTime(TimeOfDay.fromDateTime(latest.timestamp).format(context))
                      : l10n.moodDistributionEmpty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('🧠', style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.moodCheckInTitle,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              latest != null ? moodLabel ?? '' : l10n.moodCheckInPrompt,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeText,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                FilledButton.icon(
                                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.moodCheckIn),
                                  icon: const Icon(Icons.mood),
                                  label: Text(l10n.moodCheckInButton),
                                ),
                                const SizedBox(width: 12),
                                if (hasCheckIn)
                                  Text(
                                    l10n.moodCheckInToday,
                                    style: const TextStyle(color: Colors.green),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              Text(l10n.homeChooseChallenge, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Games Section
              _GameSelectionButton(
                label: l10n.homeGameImpulse,
                icon: Icons.timer,
                onPressed: () {
                  _handleGamePlayed(context, 'impulse');
                  _showImpulseModeSelector(context);
                },
              ),
              const SizedBox(height: 15),
              _GameSelectionButton(
                label: l10n.homeGameReaction,
                icon: Icons.bolt,
                onPressed: () {
                  _handleGamePlayed(context, 'reaction');
                  _showReactionModeSelector(context);
                },
              ),
              const SizedBox(height: 15),
              _GameSelectionButton(
                label: l10n.homeGameStroop,
                icon: Icons.psychology,
                onPressed: () {
                  _handleGamePlayed(context, 'stroop');
                  _showStroopModeSelector(context);
                },
              ),

              const SizedBox(height: 30),
              Text(l10n.homeAdditionalTools, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
            
            // ADHD Support Tools
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _CompactButton(
                        label: l10n.homeToolBreathing,
                        icon: Icons.air,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.breathing);
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _CompactButton(
                        label: l10n.homeToolFocusTimer,
                        icon: Icons.timer_outlined,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.focusTimer);
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
                        label: l10n.homeToolProgress,
                        icon: Icons.dashboard,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.progress);
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
                    label: Text(l10n.homeButtonAchievements),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.achievements);
                    },
                  ),
                const SizedBox(width: 20),
                  TextButton.icon(
                    icon: const Icon(Icons.settings),
                    label: Text(l10n.homeButtonSettings),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.settings);
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

  String _resolveMoodLabel(Mood mood, AppLocalizations l10n) {
    switch (mood) {
      case Mood.happy:
        return l10n.moodHappy;
      case Mood.angry:
        return l10n.moodAngry;
      case Mood.sad:
        return l10n.moodSad;
      case Mood.anxious:
        return l10n.moodAnxious;
      case Mood.calm:
        return l10n.moodCalm;
      case Mood.excited:
        return l10n.moodExcited;
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 28, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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