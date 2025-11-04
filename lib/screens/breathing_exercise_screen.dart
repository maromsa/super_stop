import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/coin_provider.dart';
import 'package:provider/provider.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  Timer? _breathingTimer;
  int _cyclesCompleted = 0;
  bool _isActive = false;
  String _instruction = 'לחץ על הכפתור כדי להתחיל';
  int _currentPhase = 0; // 0: breathe in, 1: hold, 2: breathe out, 3: hold
  final List<String> _phases = ['נשום פנימה', 'החזק', 'נשום החוצה', 'המתן'];
  final List<Color> _phaseColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
  final int _phaseDuration = 4; // seconds for each phase

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingController.addListener(() => setState(() {}));
  }

  void _startBreathing() {
    if (_isActive) {
      _stopBreathing();
      return;
    }

    setState(() {
      _isActive = true;
      _cyclesCompleted = 0;
      _currentPhase = 0;
      _instruction = _phases[_currentPhase];
    });

    _breathingController.repeat(reverse: true);
    _startPhaseTimer();
  }

  void _startPhaseTimer() {
    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed = timer.tick % _phaseDuration;
      if (elapsed == 0 && timer.tick > 0) {
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    setState(() {
      _currentPhase = (_currentPhase + 1) % 4;
      _instruction = _phases[_currentPhase];

      if (_currentPhase == 0) {
        _cyclesCompleted++;
        // Award coins for completing cycles
        if (_cyclesCompleted > 0 && _cyclesCompleted % 3 == 0) {
          Provider.of<CoinProvider>(context, listen: false).addCoins(2);
        }
      }
    });
  }

  void _stopBreathing() {
    _breathingTimer?.cancel();
    _breathingController.stop();
    _breathingController.reset();
    setState(() {
      _isActive = false;
      _currentPhase = 0;
      _instruction = 'לחץ על הכפתור כדי להתחיל שוב';
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _breathingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('תרגיל נשימה'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _phaseColors[_currentPhase].withOpacity(0.3),
              _phaseColors[_currentPhase].withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'מחזורים הושלמו: $_cyclesCompleted',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _phaseColors[_currentPhase],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _instruction,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: _startBreathing,
                icon: Icon(_isActive ? Icons.stop : Icons.play_arrow),
                label: Text(_isActive ? 'עצור' : 'התחל'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'תרגיל נשימה זה עוזר להרגעה ולשמירה על ריכוז. נשום לפי הקצב של העיגול.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

