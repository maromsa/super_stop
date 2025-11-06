import 'package:flutter/material.dart';
import 'package:super_stop/l10n/app_localizations.dart';

import '../screens/achievements_screen.dart';
import '../screens/adaptive_focus_challenge_screen.dart';
import '../screens/breathing_exercise_screen.dart';
import '../screens/calm_mode_screen.dart';
import '../screens/collectible_gallery_screen.dart';
import '../screens/daily_quest_screen.dart';
import '../screens/executive_boss_battle_screen.dart';
import '../screens/focus_timer_screen.dart';
import '../screens/habit_story_builder_screen.dart';
import '../screens/home_screen.dart';
import '../screens/impulse_control_game_screen.dart';
import '../screens/mood_check_in_screen.dart';
import '../screens/mood_music_mixer_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/progress_dashboard_screen.dart';
import '../screens/reaction_time_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/social_treasure_hunt_screen.dart';
import '../screens/stroop_test_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.moodCheckIn:
        return MaterialPageRoute(builder: (_) => const MoodCheckInScreen());
      case AppRoutes.achievements:
        return MaterialPageRoute(builder: (_) => const AchievementsScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case AppRoutes.breathing:
        return MaterialPageRoute(builder: (_) => const BreathingExerciseScreen());
      case AppRoutes.focusTimer:
        return MaterialPageRoute(builder: (_) => const FocusTimerScreen());
      case AppRoutes.progress:
        return MaterialPageRoute(builder: (_) => const ProgressDashboardScreen());
      case AppRoutes.impulse:
        final mode = settings.arguments as GameMode? ?? GameMode.classic;
        return MaterialPageRoute(builder: (_) => ImpulseControlGameScreen(mode: mode));
      case AppRoutes.reaction:
        final reactionMode = settings.arguments as ReactionMode? ?? ReactionMode.classic;
        return MaterialPageRoute(builder: (_) => ReactionTimeScreen(mode: reactionMode));
      case AppRoutes.stroop:
        final stroopMode = settings.arguments as StroopMode? ?? StroopMode.sprint;
        return MaterialPageRoute(builder: (_) => StroopTestScreen(mode: stroopMode));
      case AppRoutes.dailyQuests:
        return MaterialPageRoute(builder: (_) => const DailyQuestScreen());
      case AppRoutes.focusBurst:
        return MaterialPageRoute(builder: (_) => const AdaptiveFocusChallengeScreen());
      case AppRoutes.calmMode:
        return MaterialPageRoute(builder: (_) => const CalmModeScreen());
      case AppRoutes.socialTreasure:
        return MaterialPageRoute(builder: (_) => const SocialTreasureHuntScreen());
      case AppRoutes.moodMixer:
        return MaterialPageRoute(builder: (_) => const MoodMusicMixerScreen());
      case AppRoutes.habitStory:
        return MaterialPageRoute(builder: (_) => const HabitStoryBuilderScreen());
      case AppRoutes.bossBattles:
        return MaterialPageRoute(builder: (_) => const ExecutiveBossBattleScreen());
      case AppRoutes.collectibles:
        return MaterialPageRoute(builder: (_) => const CollectibleGalleryScreen());
      default:
        return MaterialPageRoute(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              body: Center(
                child: Text(l10n?.routerNotFound ?? 'העמוד לא נמצא'),
              ),
            );
          },
        );
    }
  }
}
