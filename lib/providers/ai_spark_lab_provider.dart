import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/ai_spark_plan.dart';
import '../models/mood_entry.dart';
import '../router/app_routes.dart';
import 'adaptive_focus_challenge_provider.dart';
import 'daily_goals_provider.dart';
import 'mood_journal_provider.dart';
import 'virtual_companion_provider.dart';

class AiSparkLabProvider with ChangeNotifier {
  AiSparkLabProvider({
    DateTime Function()? clock,
    Random? random,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? Random();

  final DateTime Function() _clock;
  final Random _random;

  MoodJournalProvider? _moodJournal;
  DailyGoalsProvider? _dailyGoals;
  AdaptiveFocusChallengeProvider? _focusChallenge;
  VirtualCompanionProvider? _companion;

  AiSparkPlan? _currentPlan;
  bool _isGenerating = false;
  String? _baseSignature;

  AiSparkPlan? get currentPlan => _currentPlan;
  bool get isGenerating => _isGenerating;
  bool get hasPlan => _currentPlan != null;

  void updateSources({
    required MoodJournalProvider moodJournal,
    required DailyGoalsProvider dailyGoals,
    required AdaptiveFocusChallengeProvider focusChallenge,
    required VirtualCompanionProvider companion,
  }) {
    _moodJournal = moodJournal;
    _dailyGoals = dailyGoals;
    _focusChallenge = focusChallenge;
    _companion = companion;

    if (!moodJournal.isReady || !companion.isLoaded || !focusChallenge.isLoaded) {
      return;
    }

    final newSignature = _buildSignature();
    if (_currentPlan == null || _baseSignature != newSignature) {
      _baseSignature = newSignature;
      _currentPlan = _buildPlan();
      notifyListeners();
    }
  }

  Future<void> regeneratePlan({Duration? delay}) async {
    if (_isGenerating) {
      return;
    }
    if (_moodJournal == null || _dailyGoals == null || _focusChallenge == null || _companion == null) {
      return;
    }
    _isGenerating = true;
    notifyListeners();

    if (delay != null && delay.inMilliseconds > 0) {
      await Future<void>.delayed(delay);
    } else {
      // Provide a lightweight sense of "thinking".
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }

    _currentPlan = _buildPlan(forceRandomness: true);
    _isGenerating = false;
    notifyListeners();
  }

  String _buildSignature() {
    final moodKey = _moodJournal?.latestEntry?.mood.name ?? 'none';
    final streak = _dailyGoals?.streak ?? 0;
    final remainingGames = _dailyGoals?.remainingGames ?? 0;
    final focusDifficulty = _focusChallenge?.currentDifficulty.name ?? 'mellow';
    final bondLevel = _safeBondLevel();
    final focusMinutes = _dailyGoals?.focusMinutesToday ?? 0;
    return [
      moodKey,
      streak,
      remainingGames,
      focusDifficulty,
      bondLevel,
      focusMinutes,
    ].join('|');
  }

  AiSparkPlan _buildPlan({bool forceRandomness = false}) {
    final now = _clock();
    final mood = _moodJournal?.latestEntry?.mood;
    final focusDifficulty = _focusChallenge?.currentDifficulty ?? FocusBurstDifficulty.mellow;
    final streak = _dailyGoals?.streak ?? 0;
    final remainingGames = _dailyGoals?.remainingGames ?? 0;
    final focusMinutesToday = _dailyGoals?.focusMinutesToday ?? 0;
    final bondLevel = _safeBondLevel();

    final energyScore = _computeEnergyScore(
      mood: mood,
      focusMinutesToday: focusMinutesToday,
      bondLevel: bondLevel,
      streak: streak,
    );
    final energyLabel = _resolveEnergyLabel(energyScore);

    final planSeed = forceRandomness ? _random.nextInt(100000) : null;
    final focusCard = _buildFocusCard(
      mood: mood,
      focusDifficulty: focusDifficulty,
      remainingGames: remainingGames,
      streak: streak,
      planSeed: planSeed,
    );
    final breakCard = _buildBreakCard(
      mood: mood,
      focusMinutesToday: focusMinutesToday,
      planSeed: planSeed,
    );
    final challengeCard = _buildChallengeCard(
      bondLevel: bondLevel,
      streak: streak,
      remainingGames: remainingGames,
      planSeed: planSeed,
    );
    final missions = _buildMissions(
      mood: mood,
      streak: streak,
      remainingGames: remainingGames,
      bondLevel: bondLevel,
      planSeed: planSeed,
    );

    return AiSparkPlan(
      generatedAt: now,
      focusCard: focusCard,
      breakCard: breakCard,
      challengeCard: challengeCard,
      missions: missions,
      energyLevelLabel: energyLabel,
      energyLevelScore: energyScore,
    );
  }

  AiSparkCard _buildFocusCard({
    required Mood? mood,
    required FocusBurstDifficulty focusDifficulty,
    required int remainingGames,
    required int streak,
    required int? planSeed,
  }) {
    final buffer = StringBuffer();
    var emoji = '⚡️';
    var title = 'AI Focus Launch';
    var route = AppRoutes.focusBurst;
    final tags = <String>['focus', focusDifficulty.name];

    if (mood == Mood.anxious || mood == Mood.sad) {
      emoji = '🛡️';
      title = 'Gentle Shield Session';
      route = AppRoutes.calmMode;
        buffer
          ..writeln("Start with Nova's breathing bubble to settle your mind.")
        ..writeln('Then glide into a mellow focus burst with softer cues.');
      tags
        ..clear()
        ..addAll(const ['calm', 'breathing', 'mellow']);
    } else if (mood == Mood.excited || focusDifficulty == FocusBurstDifficulty.turbo) {
      emoji = '🚀';
      title = 'Turbo Rocket Run';
      route = AppRoutes.focusBurst;
      buffer
        ..writeln('You are charged up! Try the turbo focus burst with double-tap cues.')
        ..writeln('Aim to beat your previous reaction streak.');
      tags
        ..clear()
        ..addAll(const ['turbo', 'speed', 'challenge']);
    } else if (mood == Mood.calm) {
      emoji = '🌱';
      title = 'Garden Glow Focus';
      route = AppRoutes.focusGarden;
      buffer
        ..writeln('Channel your calm energy into the Focus Garden.')
        ..writeln('A 5-minute focus session will shower the sprouts with light.');
      tags
        ..clear()
        ..addAll(const ['garden', 'mindful']);
    } else {
      buffer
        ..writeln('Nova suggests a balanced focus burst to keep your streak steady.')
        ..writeln('Mix in one Stroop sprint after to sharpen color switching.');
      tags
        ..addAll(const ['balanced', 'combo']);
    }

    if (remainingGames > 0) {
      buffer.writeln('Finish $remainingGames more game${remainingGames == 1 ? '' : 's'} to hit today\'s goal.');
    }
    if (streak >= 3) {
      buffer.writeln("🔥 You're on a $streak-day streak - keep the glow going!");
    }
    if (planSeed != null && planSeed.isEven) {
      buffer.writeln('🎯 Bonus idea: switch background music to match your vibe before you start.');
    }

    return AiSparkCard(
      id: 'focus-card',
      emoji: emoji,
      title: title,
      subtitle: buffer.toString().trim(),
      route: route,
      tags: tags,
    );
  }

  AiSparkCard _buildBreakCard({
    required Mood? mood,
    required int focusMinutesToday,
    required int? planSeed,
  }) {
    final buffer = StringBuffer();
    var emoji = '🎨';
    var title = 'Brain Break Remix';
    var route = AppRoutes.moodMixer;
    final tags = <String>['break', 'sensory'];

      if (focusMinutesToday >= 25) {
      emoji = '🧘';
      title = 'Deep Reset Break';
      route = AppRoutes.breathing;
      buffer
          ..writeln('You logged $focusMinutesToday focus minutes today - amazing!')
        ..writeln('Give your brain a calm breathing arc with the guided exercise.')
        ..writeln('Add a stretch between breaths to release extra energy.');
      tags
        ..clear()
        ..addAll(const ['calm', 'recovery']);
    } else if (mood == Mood.angry) {
      emoji = '🥊';
      title = 'Bounce-It-Out Break';
      route = AppRoutes.impulse;
      buffer
        ..writeln('Shake off the tough feelings with a power mini-game.')
        ..writeln('Play one round of impulse control, then jump back for a quick stretch.');
      tags
        ..clear()
        ..addAll(const ['movement', 'release']);
    } else if (mood == Mood.excited) {
        buffer
          ..writeln('Pair a fast color-switch dance with the Mood Mixer.')
          ..writeln('Bounce on beats you create and freeze when the sound pauses.');
      tags.add('music');
    } else {
      buffer
        ..writeln('Craft a cosy sensory break: choose calm colors in the mixer.')
        ..writeln('Try humming with the beat to keep attention floating.');
    }

      if (planSeed != null && planSeed % 3 == 0) {
        buffer.writeln('🪄 Extra: imagine where Nova is traveling during the break and draw it later.');
    }

    return AiSparkCard(
      id: 'break-card',
      emoji: emoji,
      title: title,
      subtitle: buffer.toString().trim(),
      route: route,
      tags: tags,
    );
  }

  AiSparkCard _buildChallengeCard({
    required int bondLevel,
    required int streak,
    required int remainingGames,
    required int? planSeed,
  }) {
    final buffer = StringBuffer();
    var emoji = '✨';
    final tags = <String>['nova-challenge'];
    var title = "Nova's Hero Quest";

    if (bondLevel >= 70) {
      emoji = '🌟';
      title = 'Legendary Link Mission';
        buffer
          ..writeln('Nova trusts you with an elite combo!')
          ..writeln('Link one calm break + one turbo burst + share a kind message.');
      tags.addAll(const ['legendary', 'combo']);
    } else if (bondLevel >= 40) {
        buffer
          ..writeln('Boost your bond: play a focus burst then claim a mystery quest reward.')
          ..writeln('Nova will cheer with a shiny badge when you do.');
      tags.add('bond-boost');
    } else {
      emoji = '🤝';
      title = 'Friendship Warm-Up';
        buffer
          ..writeln('Check in with Nova by finishing one micro-mission below.')
          ..writeln('Tell Nova how it felt afterwards for a surprise nudge.');
      tags.add('friendship');
    }

      if (streak >= 5) {
        buffer.writeln('🔥 Your streak unlocks a cosmic confetti animation - keep it alive!');
    } else if (remainingGames == 0) {
        buffer.writeln('✅ Daily goal smashed. Nova suggests gifting coins to your future self via savings.');
    }

      if (planSeed != null && planSeed % 5 == 0) {
        buffer.writeln('💡 Pro tip: record a 10-second voice note about today\'s win.');
    }

    return AiSparkCard(
      id: 'companion-card',
      emoji: emoji,
      title: title,
      subtitle: buffer.toString().trim(),
      route: AppRoutes.socialTreasure,
      tags: tags,
    );
  }

  List<AiSparkMission> _buildMissions({
    required Mood? mood,
    required int streak,
    required int remainingGames,
    required int bondLevel,
    required int? planSeed,
  }) {
    final missions = <AiSparkMission>[];
    final rewardBonus = (2 + streak ~/ 2).clamp(2, 10);
    missions.add(
      AiSparkMission(
        id: 'mission-daily-quest',
        emoji: '🗺️',
        label: 'Complete a creative daily quest for +$rewardBonus coins.',
        route: AppRoutes.dailyQuests,
        rewardHint: 'Creative quests boost Nova\'s inspiration meter.',
      ),
    );

    if (bondLevel >= 50) {
      missions.add(
        AiSparkMission(
          id: 'mission-focus-garden',
          emoji: '🌼',
          label: 'Add one glow-up to the Focus Garden.',
          route: AppRoutes.focusGarden,
          rewardHint: 'Each glow stores calm energy for tomorrow.',
        ),
      );
    } else {
      missions.add(
        AiSparkMission(
          id: 'mission-mood-check',
          emoji: '🧠',
          label: 'Log your current mood to teach Nova how you feel.',
          route: AppRoutes.moodCheckIn,
          rewardHint: 'Tracking feelings helps Nova tailor the plan.',
        ),
      );
    }

    if (remainingGames > 0 && (planSeed ?? _random.nextInt(9)) % 2 == 0) {
      missions.add(
        AiSparkMission(
          id: 'mission-reaction',
          emoji: '⚡',
          label: 'Play Reaction Test and beat your slowest round.',
          route: AppRoutes.reaction,
          rewardHint: 'Sharper reactions earn streak boosters.',
        ),
      );
    } else if (mood == Mood.calm || mood == Mood.sad) {
      missions.add(
        AiSparkMission(
          id: 'mission-habit-story',
          emoji: '📖',
          label: 'Add a panel to your Habit Story about today\'s big feeling.',
          route: AppRoutes.habitStory,
          rewardHint: 'Stories unlock new collectible frames.',
        ),
      );
    } else {
      missions.add(
        AiSparkMission(
          id: 'mission-mini-game',
          emoji: '🎯',
          label: 'Try a Stroop sprint and aim for +3 score.',
          route: AppRoutes.stroop,
          rewardHint: 'High scores feed the boss battle meter.',
        ),
      );
    }

    return missions;
  }

  int _computeEnergyScore({
    required Mood? mood,
    required int focusMinutesToday,
    required int bondLevel,
    required int streak,
  }) {
    var score = 50;
    switch (mood) {
      case Mood.excited:
        score += 18;
        break;
      case Mood.happy:
        score += 10;
        break;
      case Mood.calm:
        score += 6;
        break;
      case Mood.anxious:
        score -= 8;
        break;
      case Mood.sad:
        score -= 12;
        break;
      case Mood.angry:
        score -= 6;
        break;
      case null:
        break;
    }

    score += (bondLevel / 3).round();
    score += min(streak * 2, 14);
    score -= min(focusMinutesToday ~/ 6, 12);

    return score.clamp(0, 100);
  }

  String _resolveEnergyLabel(int score) {
    if (score >= 75) {
      return 'Hyper Rocket';
    } else if (score >= 50) {
      return 'Balanced Booster';
    } else if (score >= 25) {
      return 'Calm Orbit';
    }
    return 'Rest & Recharge';
  }

  int _safeBondLevel() {
    final companion = _companion;
    if (companion == null || !companion.isLoaded) {
      return 10;
    }
    return companion.presentation.bondLevel;
  }
}
