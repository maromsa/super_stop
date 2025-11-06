import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/calm_mode_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/virtual_companion_provider.dart';

class CalmModeScreen extends StatefulWidget {
  const CalmModeScreen({super.key});

  @override
  State<CalmModeScreen> createState() => _CalmModeScreenState();
}

class _CalmModeScreenState extends State<CalmModeScreen> with TickerProviderStateMixin {
  int _breathCycle = 0;
  bool _isBreathing = false;
  Timer? _breathTimer;
  double _breathProgress = 0;
  String _breathPrompt = 'הכינו נשימה עמוקה';

  final List<int> _pattern = <int>[];
  final List<int> _userPattern = <int>[];
  bool _isPlayingPattern = false;
  bool _patternComplete = false;
  Timer? _patternTimer;

  @override
  void dispose() {
    _breathTimer?.cancel();
    _patternTimer?.cancel();
    super.dispose();
  }

  void _startBreathingSequence() {
    if (_isBreathing) {
      return;
    }
    setState(() {
      _isBreathing = true;
      _breathCycle = 0;
      _breathProgress = 0;
      _breathPrompt = 'שאיפה...';
    });
    _runBreathingCycle();
  }

  void _runBreathingCycle() {
    const totalDuration = Duration(seconds: 6);
    const tick = Duration(milliseconds: 100);
    _breathTimer?.cancel();
    final stopwatch = Stopwatch()..start();
    _breathTimer = Timer.periodic(tick, (timer) {
      final elapsed = stopwatch.elapsed;
      final progress = (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
      setState(() {
        _breathProgress = progress;
        if (progress < 0.5) {
          _breathPrompt = 'שאיפה...';
        } else {
          _breathPrompt = 'נשיפה איטית';
        }
      });
      if (progress >= 1.0) {
        timer.cancel();
        stopwatch.stop();
        _breathCycle++;
        if (_breathCycle >= 4) {
          _completeBreathingSession();
        } else {
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            _runBreathingCycle();
          });
        }
      }
    });
  }

  Future<void> _completeBreathingSession() async {
    _breathTimer?.cancel();
    setState(() {
      _isBreathing = false;
      _breathPrompt = 'נשימה קסומה!';
      _breathProgress = 1;
    });
    final provider = context.read<CalmModeProvider>();
    final coins = context.read<CoinProvider>();
    final companion = context.read<VirtualCompanionProvider>();
    final powerUp = await provider.registerBreathingMiniGame(_breathCycle, coinProvider: coins, companion: companion);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('זכיתם בבונוס נשימות: ${powerUp.value} 🪙')),
    );
  }

  void _generatePattern() {
    if (_isPlayingPattern) {
      return;
    }
    _pattern
      ..clear()
      ..addAll(List<int>.generate(4, (_) => Random().nextInt(3)));
    _userPattern.clear();
    setState(() {
      _patternComplete = false;
    });
    _playPattern();
  }

  void _playPattern() {
    _patternTimer?.cancel();
    _isPlayingPattern = true;
    var index = 0;
    _patternTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (index >= _pattern.length) {
        timer.cancel();
        _isPlayingPattern = false;
        setState(() {});
        return;
      }
      setState(() {
        _userPattern.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 450),
          content: Text('קצב ${index + 1}: ${_pattern[index] + 1}'),
        ),
      );
      index++;
    });
  }

  Future<void> _registerRhythmTap(int beat) async {
    if (_isPlayingPattern || _patternComplete) {
      return;
    }
    _userPattern.add(beat);
    setState(() {});
    if (_userPattern.length == _pattern.length) {
      final success = List<int>.generate(_pattern.length, (index) => index)
          .every((i) => _pattern[i] == _userPattern[i]);
      if (success) {
        setState(() {
          _patternComplete = true;
        });
        final provider = context.read<CalmModeProvider>();
        final companion = context.read<VirtualCompanionProvider>();
        final powerUp = await provider.registerRhythmMiniGame(companion: companion);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('קפיצת קצב הופעלה! +${powerUp.value} להתקדמות באתגרים.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ננסה שוב את דפוס הקצב!')),
        );
        _userPattern.clear();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('מצב רגוע'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'נשימות'),
              Tab(text: 'קצב'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBreathingTab(),
            _buildRhythmTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: _isBreathing ? 220 : 180,
            height: _isBreathing ? 220 : 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.lightBlueAccent.withOpacity(0.7),
                  Colors.indigo.withOpacity(0.4),
                ],
              ),
            ),
            child: Center(
              child: Text(
                _breathPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: _breathProgress,
            minHeight: 12,
          ),
          const SizedBox(height: 8),
          Text('מחזור ${_breathCycle.clamp(0, 4)}/4'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startBreathingSequence,
            icon: const Icon(Icons.spa),
            label: Text(_isBreathing ? 'נושמים...' : 'התחל מחזור נשימות'),
          ),
        ],
      ),
    );
  }

  Widget _buildRhythmTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'משחק תיפוף לב שקט',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('עקבו אחרי רצף הקצב והקישו על הפלייליסט המתאים.'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('רמזים: ${_pattern.isEmpty ? '---' : _pattern.map((e) => e + 1).join('-')}'),
                      OutlinedButton(
                        onPressed: _generatePattern,
                        child: const Text('נגן דפוס'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              itemCount: 3,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final isActive = _userPattern.isNotEmpty && _userPattern.last == index;
                return GestureDetector(
                  onTap: () => _registerRhythmTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.orangeAccent : Colors.blueGrey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            blurRadius: 12,
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_patternComplete)
            const Text(
              'הקצב הושלם! נהנתם מכוח מיוחד.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
