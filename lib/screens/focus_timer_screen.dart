import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:super_stop/l10n/app_localizations.dart';

import '../providers/ambient_mix_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/community_challenge_provider.dart';
import '../providers/daily_goals_provider.dart';
import '../providers/focus_garden_provider.dart';
import '../providers/focus_timer_controller.dart';
import '../providers/mini_game_provider.dart';
import '../providers/mystery_quest_provider.dart';
import '../providers/virtual_companion_provider.dart';
import '../services/achievement_service.dart';
import '../utils/focus_garden_strings.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/ambient_mix_editor.dart';

class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FocusTimerController()),
        ChangeNotifierProvider(create: (_) => MiniGameProvider()),
        ChangeNotifierProvider(create: (_) => AmbientMixProvider()),
      ],
      child: const _FocusTimerContent(),
    );
  }
}

class _FocusTimerContent extends StatefulWidget {
  const _FocusTimerContent();

  @override
  State<_FocusTimerContent> createState() => _FocusTimerContentState();
}

class _FocusTimerContentState extends State<_FocusTimerContent> {
  late final AudioPlayer _audioPlayer;
  FocusTimerPhase? _previousPhase;
  int _lastCompletionEventCount = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FocusTimerController>();
    final l10n = AppLocalizations.of(context)!;

    if (!controller.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _handlePhaseChange(controller);
    _listenForCompletion(controller);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.focusAppBarTitle),
        centerTitle: true,
      ),
      body: controller.phase == FocusTimerPhase.idle
          ? _buildSetupView(controller, l10n)
          : _buildTimerView(controller, l10n),
    );
  }

  void _handlePhaseChange(FocusTimerController controller) {
    final currentPhase = controller.phase;
    if (_previousPhase == currentPhase) {
      return;
    }

    final ambientMix = context.read<AmbientMixProvider>();
    switch (currentPhase) {
      case FocusTimerPhase.focus:
        _playSoundEvent(controller, ambientMix, 'focus');
        break;
      case FocusTimerPhase.breakTime:
        _playSoundEvent(controller, ambientMix, 'break');
        context.read<MiniGameProvider>().prepareForBreak();
        break;
      case FocusTimerPhase.completed:
        _playSoundEvent(controller, ambientMix, 'complete');
        break;
      case FocusTimerPhase.idle:
        break;
    }

    _previousPhase = currentPhase;
  }

  void _listenForCompletion(FocusTimerController controller) {
    if (_lastCompletionEventCount == controller.completionEvents) {
      return;
    }
    _lastCompletionEventCount = controller.completionEvents;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleFocusCompletion(controller);
    });
  }

  Future<void> _handleFocusCompletion(FocusTimerController controller) async {
    final coinProvider = context.read<CoinProvider>();
    final goalsProvider = context.read<DailyGoalsProvider>();
    final communityProvider = context.read<CommunityChallengeProvider>();
    final questProvider = context.read<MysteryQuestProvider>();
    final companion = context.read<VirtualCompanionProvider>();
    final gardenProvider = context.read<FocusGardenProvider>();

    if (controller.focusRewardCoins > 0) {
      coinProvider.addCoins(controller.focusRewardCoins);
    }

    await goalsProvider.completeFocusSession(controller.selectedFocusMinutes);
    communityProvider.registerFocusContribution(minutes: controller.selectedFocusMinutes);
    final completedQuests = questProvider.registerFocusMinutes(controller.selectedFocusMinutes);
    companion.registerQuestCelebration('סשן ריכוז');
    final gardenUpdate = await gardenProvider.registerFocusSession(controller.selectedFocusMinutes);

    if (!mounted) return;
    _handleQuestRewards(completedQuests);
    _handleGardenUpdate(gardenUpdate, coinProvider);
  }

  Widget _buildSetupView(FocusTimerController controller, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.focusSetupTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          _buildTimeSelector(
            title: l10n.focusFocusMinutesLabel,
            currentValue: controller.selectedFocusMinutes,
            options: const [3, 5, 10, 15, 20],
            onChanged: controller.updateFocusMinutes,
            formatLabel: (minutes) => l10n.focusMinutesChip(minutes),
          ),
          const SizedBox(height: 30),
          _buildTimeSelector(
            title: l10n.focusBreakMinutesLabel,
            currentValue: controller.selectedBreakMinutes,
            options: const [1, 2, 3, 5],
            onChanged: controller.updateBreakMinutes,
            formatLabel: (minutes) => l10n.focusMinutesChip(minutes),
          ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: controller.startFocus,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.focusStartButton),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.focusSessionsCompleted(controller.completedSessions),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Consumer<AmbientMixProvider>(
              builder: (context, mixProvider, _) {
                final presetName = mixProvider.isLoaded
                    ? (mixProvider.selectedPreset ?? 'מותאם אישית')
                    : 'טוען...';
                return OutlinedButton.icon(
                  onPressed: () => _openAmbientMixEditor(context),
                  icon: const Icon(Icons.library_music),
                  label: Text('מיקס צלילים: $presetName'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String title,
    required int currentValue,
    required List<int> options,
    required ValueChanged<int> onChanged,
    String Function(int)? formatLabel,
  }) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          alignment: WrapAlignment.center,
          children: options.map((minutes) {
            final isSelected = minutes == currentValue;
            return ChoiceChip(
              label: Text(formatLabel != null ? formatLabel(minutes) : '$minutes'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(minutes);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimerView(FocusTimerController controller, AppLocalizations l10n) {
    final isFocus = controller.phase == FocusTimerPhase.focus;
    final isBreak = controller.phase == FocusTimerPhase.breakTime;
    final isCompleted = controller.phase == FocusTimerPhase.completed;

    Color backgroundColor;
    String title;
    IconData icon;

    if (isFocus) {
      backgroundColor = Colors.blue;
      title = l10n.focusPhaseFocus;
      icon = Icons.school;
    } else if (isBreak) {
      backgroundColor = Colors.green;
      title = l10n.focusPhaseBreak;
      icon = Icons.coffee;
    } else {
      backgroundColor = Colors.amber;
      title = l10n.focusPhaseCompleted;
      icon = Icons.check_circle;
    }

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _formatTime(controller.timeRemainingSeconds),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 60),
            if (isFocus || isBreak)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: controller.pause,
                    icon: const Icon(Icons.pause),
                    label: Text(l10n.focusPause),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: backgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: controller.resume,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.focusResume),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: backgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              ),
              if (isBreak) ...[
                const SizedBox(height: 24),
                _buildMiniGameCard(context),
              ],
            if (isCompleted) ...[
              Text(
                l10n.focusCompletionMessage,
                style: const TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  controller.startBreak();
                },
                icon: const Icon(Icons.coffee),
                label: Text(l10n.focusTakeBreak),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: controller.reset,
                child: Text(
                  l10n.focusBackToMenu,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildMiniGameCard(BuildContext context) {
    return Consumer<MiniGameProvider>(
      builder: (context, miniGameProvider, _) {
        if (!miniGameProvider.isLoaded) {
          return const SizedBox.shrink();
        }
        final game = miniGameProvider.currentMiniGame;
        final completedToday = miniGameProvider.completedToday;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            color: Colors.white.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    game.description,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                        label: Text('רצף ${miniGameProvider.streak}'),
                        backgroundColor: Colors.orange.shade50,
                      ),
                      Chip(
                        avatar: const Icon(Icons.monetization_on, size: 18, color: Colors.amber),
                        label: Text('+${game.rewardCoins} 🪙'),
                        backgroundColor: Colors.amber.shade50,
                      ),
                      if (completedToday)
                        Chip(
                          label: const Text('הושלם להיום'),
                          backgroundColor: Colors.green.shade50,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: completedToday ? null : () => _completeMiniGame(context),
                      icon: const Icon(Icons.celebration),
                      label: Text(completedToday ? 'נתראה מחר!' : 'סיימתי את האתגר'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _playSoundEvent(
    FocusTimerController controller,
    AmbientMixProvider ambientMix,
    String event,
  ) {
    if (!controller.soundEnabled) return;
    final asset = ambientMix.resolveTrackForEvent(event);
    _audioPlayer.stop();
    _audioPlayer.play(AssetSource('sounds/$asset'));
  }

  void _handleQuestRewards(List<MysteryQuest> quests) {
    if (quests.isEmpty || !mounted) {
      return;
    }
    final questProvider = context.read<MysteryQuestProvider>();
    final coinProvider = context.read<CoinProvider>();
    for (final quest in quests) {
      if (quest.isClaimable) {
        final claimed = questProvider.claimReward(quest.id, coinProvider);
        if (claimed != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${quest.title} +${quest.rewardCoins} 🪙')),
          );
        }
      }
    }
  }

  void _handleGardenUpdate(FocusGardenUpdate update, CoinProvider coinProvider) {
    if (!mounted || !update.hasChanges) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final messages = <String>[];

    if (update.sunlightEarned > 0) {
      messages.add(l10n.focusGardenSunlightEarned(update.sunlightEarned));
    }

    if (update.stageLeveledUp && update.newStageId != null) {
      final stageName = FocusGardenStrings.stageName(l10n, update.newStageId!);
      if (update.rewardCoins > 0) {
        coinProvider.addCoins(update.rewardCoins);
      }
      messages.add(l10n.focusGardenStageUnlocked(stageName));
    }

    if (messages.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messages.join('\n'))),
    );
  }

  void _openAmbientMixEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const AmbientMixEditor(),
    );
  }

  Future<void> _completeMiniGame(BuildContext context) async {
    final miniGameProvider = context.read<MiniGameProvider>();
    final coinProvider = context.read<CoinProvider>();
    final achievementService = context.read<AchievementService>();
    final result = await miniGameProvider.completeCurrentMiniGame();

    if (!mounted) return;

    if (!result.wasFirstCompletionToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('כבר אספת את הפרס היום')),
      );
      return;
    }

    if (result.rewardCoins > 0) {
      coinProvider.addCoins(result.rewardCoins);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${result.rewardCoins} 🪙')),
      );
    }

    final badgeId = result.unlockedBadgeId;
    if (badgeId != null) {
      final unlocked = await achievementService.unlockAchievement(badgeId);
      if (unlocked != null && mounted) {
        _showMiniGameBadge(badgeId);
      }
    }
  }

  void _showMiniGameBadge(String badgeId) {
    final service = context.read<AchievementService>();
    final achievement = service.getAchievement(badgeId);
    if (achievement == null) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AchievementPopup(
        title: _miniBadgeTitle(badgeId),
        description: _miniBadgeDescription(badgeId),
        icon: achievement.icon ?? Icons.auto_awesome,
        color: achievement.color ?? Colors.deepPurple,
        badgeLabel: 'תג קוסמטי',
        onDismiss: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  String _miniBadgeTitle(String id) {
    switch (id) {
      case 'mini_badge_bronze':
        return 'קוסם ההפסקות - ארד';
      case 'mini_badge_silver':
        return 'קוסם ההפסקות - כסף';
      case 'mini_badge_gold':
        return 'קוסם ההפסקות - זהב';
      default:
        return 'תג הפסקה חדש';
    }
  }

  String _miniBadgeDescription(String id) {
    switch (id) {
      case 'mini_badge_bronze':
        return 'השלמת שלושה אתגרי הפסקה ברצף ושדרגת את הפופאפ שלך.';
      case 'mini_badge_silver':
        return 'שבעה ימים של מיני-משחקים מושלמים—העיצוב שלך השתדרג.';
      case 'mini_badge_gold':
        return 'שבועיים של רצף קסום! נפתח לך הבזק נוצץ בחגיגות.';
      default:
        return 'עוד תג צבעוני לאוסף שלך.';
    }
  }
}

