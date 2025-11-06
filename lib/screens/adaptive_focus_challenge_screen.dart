import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/focus_burst_plan.dart';
import '../providers/adaptive_focus_challenge_provider.dart';
import '../providers/collectible_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_quest_provider.dart';
import '../providers/mood_journal_provider.dart';
import '../providers/virtual_companion_provider.dart';

class AdaptiveFocusChallengeScreen extends StatefulWidget {
  const AdaptiveFocusChallengeScreen({super.key});

  @override
  State<AdaptiveFocusChallengeScreen> createState() => _AdaptiveFocusChallengeScreenState();
}

class _AdaptiveFocusChallengeScreenState extends State<AdaptiveFocusChallengeScreen>
    with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  int _currentCueIndex = -1;
  final List<double> _reactionTimes = <double>[];
  final List<bool> _hits = <bool>[];
  Timer? _cueTimer;
  Stopwatch? _stopwatch;
  Color? _activeColor;
  String? _statusMessage;

  @override
  void dispose() {
    _cueTimer?.cancel();
    _stopwatch?.stop();
    super.dispose();
  }

  void _startSession(FocusBurstPlan plan) {
    setState(() {
      _isRunning = true;
      _currentCueIndex = 0;
      _reactionTimes
        ..clear();
      _hits
        ..clear();
      _statusMessage = 'האתגר החל!';
    });
    _runCue(plan);
  }

  void _runCue(FocusBurstPlan plan) {
    _cueTimer?.cancel();
    _stopwatch?.stop();
    if (_currentCueIndex < 0 || _currentCueIndex >= plan.cues.length) {
      _finishSession(plan);
      return;
    }
    final cue = plan.cues[_currentCueIndex];
    setState(() {
      _activeColor = Color(cue.sensoryColor).withOpacity(0.8);
      _statusMessage = cue.prompt;
    });
    _stopwatch = Stopwatch()..start();
    _cueTimer = Timer(Duration(seconds: cue.durationSeconds), () {
      if (!mounted || !_isRunning) {
        return;
      }
      _registerReaction(plan, reacted: false);
    });
  }

  void _registerReaction(FocusBurstPlan plan, {required bool reacted}) {
    _cueTimer?.cancel();
    final stopwatch = _stopwatch;
    _stopwatch = null;
    if (stopwatch == null) {
      return;
    }
    final reactionMs = reacted ? stopwatch.elapsedMilliseconds.toDouble() : 2000.0;
    _reactionTimes.add(reactionMs);
    _hits.add(reacted);
    setState(() {
      _statusMessage = reacted
          ? 'תזמון נהדר!'
          : 'פספסת את הרמז – ממשיכים קדימה';
    });
    _currentCueIndex++;
    if (_currentCueIndex >= plan.cues.length) {
      _finishSession(plan);
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || !_isRunning) {
        return;
      }
      _runCue(plan);
    });
  }

  Future<void> _finishSession(FocusBurstPlan plan) async {
    _cueTimer?.cancel();
    _stopwatch?.stop();
    final provider = context.read<AdaptiveFocusChallengeProvider>();
    final average = _reactionTimes.isEmpty
        ? 0.0
        : _reactionTimes.reduce((value, element) => value + element) / _reactionTimes.length;
    final completed = _hits.every((hit) => hit);
    setState(() {
      _isRunning = false;
      _currentCueIndex = -1;
      _activeColor = null;
      _statusMessage = completed ? '✨ סשן מושלם!' : 'האתגר הסתיים - רוצים לנסות שוב?';
    });

    await provider.registerResult(
      FocusBurstResult(planId: plan.id, completed: completed, averageReactionMs: average),
      dailyQuest: context.read<DailyQuestProvider>(),
      coins: context.read<CoinProvider>(),
      collectibles: context.read<CollectibleProvider>(),
      companion: context.read<VirtualCompanionProvider>(),
    );

    if (!mounted) {
      return;
    }
    final snackbar = SnackBar(
      content: Text(
        completed
            ? 'השלמת את כל הרמזים בממוצע ${average.toStringAsFixed(0)} מ״ש!'
            : 'השלמת ${_hits.where((hit) => hit).length}/${plan.cues.length} רמזים. ממוצע ${average.toStringAsFixed(0)} מ״ש',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdaptiveFocusChallengeProvider>();
    final plan = provider.currentPlan;
    final difficultyColor = _resolveDifficultyColor(plan.difficulty);
    return Scaffold(
      appBar: AppBar(
        title: const Text('פרצי ריכוז אדפטיביים'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlanHeader(plan: plan, color: difficultyColor, provider: provider),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      (_activeColor ?? difficultyColor).withOpacity(0.15),
                      Colors.black.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRunning && _currentCueIndex >= 0)
                      _CueIndicator(
                        cueNumber: _currentCueIndex + 1,
                        total: plan.cues.length,
                        prompt: plan.cues[_currentCueIndex].prompt,
                      )
                    else
                      const Text(
                        'ליחצו על התחל כדי לצלול לפרץ ריכוז קצר ומותאם אישית.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 32),
                    if (_statusMessage != null)
                      Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 32),
                    if (_isRunning)
                      FilledButton(
                        onPressed: () => _registerReaction(plan, reacted: true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('לחיצה כשמרגישים מוכנים'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () => _startSession(plan),
                        icon: const Icon(Icons.bolt),
                        label: const Text('התחל פרץ ריכוז'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRunning
                          ? null
                          : () {
                              provider.requestNewPlan();
                              setState(() {
                                _statusMessage = 'תכנית חדשה הוכנה';
                              });
                            },
                      icon: const Icon(Icons.refresh),
                      label: const Text('תזמון אחר'),
                    ),
                  ),
                const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRunning
                          ? null
                          : () {
                              final journal = context.read<MoodJournalProvider>();
                              provider.updateFromMoodJournal(journal);
                              provider.requestNewPlan();
                              setState(() {
                                _statusMessage = 'כוונון על פי מצב הרוח בוצע';
                              });
                            },
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('התאם לפי מצב רוח'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveDifficultyColor(FocusBurstDifficulty difficulty) {
    switch (difficulty) {
      case FocusBurstDifficulty.mellow:
        return Colors.tealAccent.shade400;
      case FocusBurstDifficulty.balanced:
        return Colors.orangeAccent.shade200;
      case FocusBurstDifficulty.turbo:
        return Colors.deepPurpleAccent;
    }
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.plan, required this.color, required this.provider});

  final FocusBurstPlan plan;
  final Color color;
  final AdaptiveFocusChallengeProvider provider;

  @override
  Widget build(BuildContext context) {
    final average = provider.averageReactionMs;
    return Card(
      color: color.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Text(plan.difficulty.name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'מצב ${plan.difficulty.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('מספר רמזים: ${plan.cues.length}, נשימות רגועות: ${plan.breathCount}'),
                    ],
                  ),
                ),
              ],
            ),
            if (average > 0) ...[
              const SizedBox(height: 12),
              Text('ממוצע אחרון: ${average.toStringAsFixed(0)} מ״ש'),
              LinearProgressIndicator(
                value: max<double>(0, (1500 - average) / 1500).clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CueIndicator extends StatelessWidget {
  const _CueIndicator({
    required this.cueNumber,
    required this.total,
    required this.prompt,
  });

  final int cueNumber;
  final int total;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'רמז $cueNumber מתוך $total',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
