import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/focus_timer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusTimerController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<FocusTimerController> createController() async {
      final controller = FocusTimerController(tickDuration: const Duration(milliseconds: 10));
      await Future.delayed(Duration.zero);
      expect(controller.isLoaded, isTrue);
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

      controller.dispose();
    });

    test('startFocus transitions to focus phase and counts down', () async {
      final controller = await createController();

      await controller.updateFocusMinutes(0);
      await controller.startFocus();

      await Future.delayed(const Duration(milliseconds: 40));

      expect(controller.phase, equals(FocusTimerPhase.completed));
      expect(controller.completedSessions, equals(1));
      expect(controller.completionTicker, equals(1));

      controller.dispose();
    });

    test('startBreak transitions to break phase', () async {
      final controller = await createController();

      await controller.updateBreakMinutes(0);
      await controller.startBreak();

      await Future.delayed(const Duration(milliseconds: 40));

      expect(controller.phase, equals(FocusTimerPhase.idle));

      controller.dispose();
    });
  });
}
