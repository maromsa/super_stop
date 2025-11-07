// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get playButton => 'Play';

  @override
  String get settingsButton => 'Settings';

  @override
  String get achievementsButton => 'Achievements';

  @override
  String get authSignInTitle => 'Welcome to Super Stop';

  @override
  String get authSignInSubtitle => 'Connect with your Google account to sync your progress across devices.';

  @override
  String get authSignInButton => 'Continue with Google';

  @override
  String get authSignOutTooltip => 'Sign out';

  @override
  String get authSyncInProgress => 'Syncing your latest progress...';

  @override
  String get homeInstructionsTooltip => 'How to play?';

  @override
  String get homeInstructionsTitle => 'How to play?';

  @override
  String get homeInstructionsImpulseTitle => 'Impulse Challenge';

  @override
  String get homeInstructionsImpulseBody => 'Wait for the circle to fill and turn green, then tap quickly!';

  @override
  String get homeInstructionsReactionTitle => 'Reaction Test';

  @override
  String get homeInstructionsReactionBody => 'Wait for the screen to turn green and tap as quickly as you can!';

  @override
  String get homeInstructionsStroopTitle => 'Stroop Test';

  @override
  String get homeInstructionsStroopBody => 'Tap the button that matches the color of the word, not the word itself.';

  @override
  String get homeInstructionsClose => 'Got it!';

  @override
  String get homeStatStreak => 'Streak';

  @override
  String get homeStatGoal => 'Goal';

  @override
  String get homeStatCoins => 'Coins';

  @override
  String homeExperienceProgress(int current, int goal) => '$current / $goal XP';

  @override
  String get homeTitle => 'Super Stop';

  @override
  String get homeChooseChallenge => 'Choose a challenge';

  @override
  String get homeGameImpulse => 'Impulse Control Game';

  @override
  String get homeGameReaction => 'Reaction Test';

  @override
  String get homeGameStroop => 'Stroop Test';

  @override
  String get homeAdditionalTools => 'More tools';

  @override
  String get homeDailyQuestTitle => 'Daily quests';

  @override
  String get homeDailyQuestOpen => 'Open quest board';

  @override
  String get homeAdventureHubTitle => 'Adventure hub';

  @override
  String get homeAdventureFocus => 'Focus bursts';

  @override
  String get homeAdventureCalm => 'Calm mode';

  @override
  String get homeAdventureSocial => 'Social hunt';

  @override
  String get homeAdventureMixer => 'Mood music mixer';

  @override
  String get homeAdventureStory => 'Habit comic';

  @override
  String get homeAdventureBoss => 'Executive boss battles';

  @override
  String get homeAdventureCollectibles => 'Rewards gallery';

  @override
  String get homeMoodSelectorTitle => 'Choose your vibe';

  @override
  String get homeMoodLockedMessage => 'Keep playing to unlock this mood!';

  @override
  String get homeMoodActiveBadge => 'Active';

  @override
  String get dailySparkFabLabel => 'Daily surprise';

  @override
  String get dailySparkSheetTitle => "Nova's surprise spark";

  @override
  String get dailySparkPrimary => "Let's do it!";

  @override
  String get dailySparkAnother => 'Show me another';

  @override
  String dailySparkCoinMessage(int amount) => 'You earned $amount bonus coins!';

  @override
  String get dailySparkMoveTitle => 'Quick Move Party';

  @override
  String get dailySparkMoveBody => 'Turn up your favorite song and dance or jump in place for 20 seconds.';

  @override
  String get dailySparkComplimentTitle => 'Compliment Quest';

  @override
  String get dailySparkComplimentBody => 'Send a quick message to cheer someone up. A compliment counts!';

  @override
  String get dailySparkFocusTitle => 'Focus Flash Challenge';

  @override
  String get dailySparkFocusBody => 'Start a short focus timer and give it your best for 3 minutes.';

  @override
  String get dailySparkBreathTitle => 'Breathing Boost';

  @override
  String get dailySparkBreathBody => 'Take a calm breathing break using the guided exercise.';

  @override
  String get homeToolBreathing => 'Breathing Exercise';

  @override
  String get homeToolFocusTimer => 'Focus Timer';

  @override
  String get homeToolProgress => 'Progress Dashboard';

  @override
  String get homeButtonAchievements => 'Achievements';

  @override
  String get homeButtonSettings => 'Settings';

  @override
  String get homeReactionModeTitle => 'Choose game mode';

  @override
  String get homeReactionModeEndless => 'Classic (endless)';

  @override
  String get homeReactionModeTest => 'Test (5 rounds)';

  @override
  String get homeImpulseModeTitle => 'Select play style';

  @override
  String get homeImpulseModeClassic => 'Classic';

  @override
  String get homeImpulseModeSurvival => 'Survival';

  @override
  String get homeStroopModeTitle => 'Choose game mode';

  @override
  String get homeStroopModeSprint => 'Sprint (60 seconds)';

  @override
  String get homeStroopModeAccuracy => 'Accuracy (one mistake ends the run)';

  @override
  String get focusAppBarTitle => 'Focus Timer';

  @override
  String get focusSetupTitle => 'Choose focus time';

  @override
  String get focusFocusMinutesLabel => 'Focus time (minutes)';

  @override
  String get focusBreakMinutesLabel => 'Break time (minutes)';

  @override
  String get focusStartButton => 'Start focus';

  @override
  String focusSessionsCompleted(int count) => 'Completed: $count focus sessions';

  @override
  String focusMinutesChip(int minutes) => '$minutes min';

  @override
  String get focusPhaseFocus => 'Focus time';

  @override
  String get focusPhaseBreak => 'Break time';

  @override
  String get focusPhaseCompleted => 'Completed!';

  @override
  String get focusPause => 'Pause';

  @override
  String get focusResume => 'Resume';

  @override
  String get focusCompletionMessage => 'Great job! You finished a focus session!';

  @override
  String get focusTakeBreak => 'Take a break';

  @override
  String get focusBackToMenu => 'Back to menu';

  @override
  String get progressAppBarTitle => 'Progress Dashboard';

  @override
  String get progressStreakSubtitle => 'Days in a row';

  @override
  String get progressDailyGoalTitle => 'Daily goal';

  @override
  String progressDailyGoalLabel(int played, int goal) => '$played / $goal games';

  @override
  String progressDailyGoalFocus(int minutes) => '$minutes focus minutes today';

  @override
  String get progressStatsCoins => 'Coins';

  @override
  String get progressStatsGamesToday => 'Games today';

  @override
  String get progressStatsFocusToday => 'Focus minutes';

  @override
  String get progressStatsWeeklyGames => 'Total games this week';

  @override
  String get progressStatsWeeklyFocus => 'Total focus minutes this week';

  @override
  String get progressWeeklyGamesTitle => 'Games this week';

  @override
  String get progressAchievementsTitle => 'Achievements';

  @override
  String get progressAchievementsButton => 'View all achievements';

  @override
  String get achievementUnknown => 'New Achievement!';

  @override
  String get moodCheckInTitle => 'Mood Check-in';

  @override
  String get moodCheckInPrompt => 'Tap the mood that feels closest to you right now.';

  @override
  String get moodCheckInButton => 'Log mood';

  @override
  String get moodCheckInToday => 'Already logged today';

  @override
  String get moodCheckInThanks => 'Thanks! Your mood has been saved.';

  @override
  String get moodCheckInLastTitle => 'Last check-in';

  @override
  String moodCheckInLastTime(String time) => 'Last logged at $time';

  @override
  String get moodDistributionEmpty => 'Log your mood for a full weekly view.';

  @override
  String get moodDistributionTitle => 'Mood highlights this week';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodAngry => 'Frustrated';

  @override
  String get moodSad => 'Sad';

  @override
  String get moodAnxious => 'Anxious';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodExcited => 'Excited';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Super Stop!';

  @override
  String get onboardingWelcomeBody => 'Train focus, self-control, and emotional balance with games designed for kids with ADHD.';

  @override
  String get onboardingFeatureTitle => 'What will you discover?';

  @override
  String get onboardingFeatureGames => 'Fun impulse-control games to practice every day';

  @override
  String get onboardingFeatureFocus => 'Short focus sessions with guided breaks';

  @override
  String get onboardingFeatureRewards => 'Coins, streaks, and colorful achievements';

  @override
  String get onboardingFeatureProgress => 'Progress dashboard with weekly stats';

  @override
  String get onboardingMoodTitle => 'How are you feeling today?';

  @override
  String get onboardingMoodSubtitle => 'Pick an emoji to begin your adventure.';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingMoodPrompt => 'Choose a mood to get started';

  @override
  String get impulseGameOverTitle => 'Game Over';

  @override
  String impulseFinalScore(int score) => 'Final Score: $score';

  @override
  String get impulseReturnHome => 'Return Home';

  @override
  String impulseComboLabel(int combo) => 'x$combo COMBO!';

  @override
  String get reactionTestCompleteTitle => 'Test Complete!';

  @override
  String reactionTestCompleteSummary(int best, int worst, int average) => 'Best: $best ms\nWorst: $worst ms\nAverage: $average ms\n\nTap to play again';

  @override
  String get routerNotFound => 'Route not found';
}
