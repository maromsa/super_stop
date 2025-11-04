import 'package:flutter/material.dart';

import '../screens/achievements_screen.dart';
import '../screens/breathing_exercise_screen.dart';
import '../screens/focus_timer_screen.dart';
import '../screens/home_screen.dart';
import '../screens/impulse_control_game_screen.dart';
import '../screens/mood_check_in_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/progress_dashboard_screen.dart';
import '../screens/reaction_time_screen.dart';
import '../screens/settings_screen.dart';
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
          return MaterialPageRoute(
            builder: (_) => ImpulseControlGameScreen(mode: mode),
          );
        case AppRoutes.reaction:
          final mode = settings.arguments as ReactionMode? ?? ReactionMode.classic;
          return MaterialPageRoute(
            builder: (_) => ReactionTimeScreen(mode: mode),
          );
        case AppRoutes.stroop:
          final mode = settings.arguments as StroopMode? ?? StroopMode.sprint;
          return MaterialPageRoute(
            builder: (_) => StroopTestScreen(mode: mode),
          );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
