import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:super_stop/l10n/app_localizations.dart';

import '../providers/coin_provider.dart';
import '../providers/daily_goals_provider.dart';
import '../providers/focus_timer_controller.dart';

class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FocusTimerController(),
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

    if (currentPhase == FocusTimerPhase.focus || currentPhase == FocusTimerPhase.breakTime) {
      _playSound(controller, 'tick.mp3');
    } else if (currentPhase == FocusTimerPhase.completed) {
      _playSound(controller, 'success.mp3');
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

    if (controller.focusRewardCoins > 0) {
      coinProvider.addCoins(controller.focusRewardCoins);
    }

    await goalsProvider.completeFocusSession(controller.selectedFocusMinutes);
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

  void _playSound(FocusTimerController controller, String asset) {
    if (!controller.soundEnabled) return;
    _audioPlayer.stop();
    _audioPlayer.play(AssetSource('sounds/$asset'));
  }
}

