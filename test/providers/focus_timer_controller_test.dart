import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/focus_timer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusTimerController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<FocusTimerController> createController({Duration? tick}) async {
      final controller = FocusTimerController(
        tickDuration: tick ?? const Duration(milliseconds: 10),
      );
      await Future.delayed(Duration.zero);
      expect(controller.isLoaded, isTrue);
      addTearDown(controller.dispose);
      return controller;
    }

    test('loads defaults from shared preferences', () async {
      final controller = await createController();

      expect(controller.phase, equals(FocusTimerPhase.idle));
      expect(controller.timeRemainingSeconds, equals(0));
      expect(controller.selectedFocusMinutes, equals(5));
      expect(controller.selectedBreakMinutes, equals(2));
      expect(controller.completedSessions, equals(0));
      expect(controller.soundEnabled, isTrue);
      expect(controller.autoStartBreak, isFalse);
    });

    test('startFocus transitions to focus phase and counts down', () async {
      final controller = await createController();

      await controller.updateFocusMinutes(0);
      await controller.startFocus();

      await Future.delayed(const Duration(milliseconds: 40));

      expect(controller.phase, equals(FocusTimerPhase.completed));
      expect(controller.completedSessions, equals(1));
      expect(controller.completionEvents, equals(1));
    });

    test('startBreak transitions to break phase', () async {
      final controller = await createController();

      await controller.updateBreakMinutes(0);
      await controller.startBreak();

      await Future.delayed(const Duration(milliseconds: 40));

      expect(controller.phase, equals(FocusTimerPhase.idle));
    });

    test('pause and resume control timer progression', () async {
      final controller = await createController();

      await controller.updateFocusMinutes(1);
      await controller.startFocus();

      await Future.delayed(const Duration(milliseconds: 30));
      controller.pause();
      final pausedTime = controller.timeRemainingSeconds;

      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.timeRemainingSeconds, equals(pausedTime));

      controller.resume();
      await Future.delayed(const Duration(milliseconds: 40));

      expect(controller.timeRemainingSeconds, lessThan(pausedTime));
      expect(controller.isRunning, isTrue);
    });

    test('reset clears timer state and stops running timer', () async {
      final controller = await createController();

      await controller.updateFocusMinutes(1);
      await controller.startFocus();
      await Future.delayed(const Duration(milliseconds: 20));

      controller.reset();

      expect(controller.phase, equals(FocusTimerPhase.idle));
      expect(controller.timeRemainingSeconds, equals(0));
      expect(controller.isRunning, isFalse);
    });

    test('setAutoStartBreak persists preference and triggers automatic break', () async {
      final controller = await createController();

      await controller.setAutoStartBreak(true);
      expect(controller.autoStartBreak, isTrue);

      await controller.updateFocusMinutes(0);
      await controller.updateBreakMinutes(1);
      await controller.startFocus();

      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.completionEvents, equals(1));
      expect(
        controller.phase,
        anyOf(equals(FocusTimerPhase.completed), equals(FocusTimerPhase.breakTime)),
      );

      await Future.delayed(const Duration(milliseconds: 40));
      expect(controller.phase, equals(FocusTimerPhase.breakTime));

      // Allow the break timer to run out.
      await Future.delayed(const Duration(milliseconds: 650));
      expect(controller.phase, equals(FocusTimerPhase.idle));

      // Preference should persist across instances.
      final second = await createController();
      expect(second.autoStartBreak, isTrue);
    });

    test('skipBreak cancels current break and returns to idle', () async {
      final controller = await createController();

      await controller.updateBreakMinutes(1);
      await controller.startBreak();
      await Future.delayed(const Duration(milliseconds: 30));
      expect(controller.phase, equals(FocusTimerPhase.breakTime));

      controller.skipBreak();
      expect(controller.phase, equals(FocusTimerPhase.idle));
      expect(controller.timeRemainingSeconds, equals(0));
      expect(controller.isRunning, isFalse);
    });

    test('updateDurations and reward configuration persist to new instances', () async {
      final controller = await createController();

      await controller.updateFocusMinutes(12);
      await controller.updateBreakMinutes(4);
      await controller.setRewards(coins: 8, experience: 3);
      await controller.setSoundEnabled(false);

      final reloaded = await createController();
      expect(reloaded.selectedFocusMinutes, equals(12));
      expect(reloaded.selectedBreakMinutes, equals(4));
      expect(reloaded.focusRewardCoins, equals(8));
      expect(reloaded.focusRewardExperience, equals(3));
      expect(reloaded.soundEnabled, isFalse);
    });
  });
}
