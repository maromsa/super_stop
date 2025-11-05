import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart'; // <-- New import
import 'package:super_stop/l10n/app_localizations.dart';

import 'settings_screen.dart';
import '../services/achievement_service.dart';

enum ReactionState { waitingToStart, waitingForGreen, readyToTap, finished, tooEarly, testFinished }
enum ReactionMode { classic, fiveRoundTest }

class ReactionTimeScreen extends StatefulWidget {
  final ReactionMode mode;
  const ReactionTimeScreen({super.key, required this.mode});
  static const String kHighScore = 'reaction_high_score';
  @override
  State<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

class _ReactionTimeScreenState extends State<ReactionTimeScreen> {
  ReactionState _state = ReactionState.waitingToStart;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _lastResult = 0;
  List<int> _recentScores = [];
  int _averageScore = 0;
  int _highScore = 0;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  late AchievementService _achievementService;
  late ConfettiController _confettiController;
  int _round = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _achievementService = Provider.of<AchievementService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadHighScore();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    // --- Mark game as played for "Trifecta" ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _achievementService.markGamePlayed('reaction');
    });
  }

  void _updateScores(int newScore) {
    _recentScores.add(newScore);
    if (_recentScores.length > 5) {
      _recentScores.removeAt(0);
    }
    if (_recentScores.isNotEmpty) {
      _averageScore = _recentScores.reduce((a, b) => a + b) ~/ _recentScores.length;
    }

    // --- New: Check for achievements ---
    if (newScore < 250) {
      _achievementService.unlockAchievement('reaction_time_250');
    }

    if (newScore < _highScore || _highScore == 0) {
      _achievementService.unlockAchievement('new_high_score');
      _highScore = newScore;
      _confettiController.play();
      _saveHighScore(newScore);
    }
  }

  void _onTapScreen() {
    setState(() {
      switch (_state) {
      // ... (other cases are mostly the same)
        case ReactionState.readyToTap:
          _playSound('success.mp3');
          if (_hapticsEnabled) HapticFeedback.lightImpact();
          _stopwatch.stop();
          _lastResult = _stopwatch.elapsedMilliseconds;
          _updateScores(_lastResult); // Logic is now in this method
          _state = ReactionState.finished;
          break;
        case ReactionState.waitingToStart:
          _startNewGameSession();
          break;
        case ReactionState.waitingForGreen:
          _playSound('failure.mp3');
          if (_hapticsEnabled) HapticFeedback.heavyImpact();
          _timer?.cancel();
          _state = ReactionState.tooEarly;
          break;
        case ReactionState.finished:
        // --- New: Logic for different modes ---
          if (widget.mode == ReactionMode.fiveRoundTest && _round >= 5) {
            _state = ReactionState.testFinished;
          } else {
            _round++;
            _playSound('tick.mp3');
            _state = ReactionState.waitingForGreen;
            _startWaitTimer();
          }
          break;
        case ReactionState.tooEarly:
          if (widget.mode == ReactionMode.fiveRoundTest) {
            // In test mode, an early tap resets the whole test
            _state = ReactionState.waitingToStart;
          } else {
            // In classic mode, it just starts the next round
            _playSound('tick.mp3');
            _state = ReactionState.waitingForGreen;
            _startWaitTimer();
          }
          break;
        case ReactionState.testFinished:
          _state = ReactionState.waitingToStart;
          break;
      }
    });
  }

  void _startNewGameSession() {
    _playSound('tick.mp3');
    _recentScores = [];
    _averageScore = 0;
    _round = 1;
    _state = ReactionState.waitingForGreen;
    _startWaitTimer();
  }


  void _playSound(String soundFile) {
    if (!_soundEnabled) return;
    AudioPlayer().play(AssetSource('sounds/$soundFile'));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _soundEnabled = prefs.getBool(SettingsScreen.kSoundEnabled) ?? true;
        _hapticsEnabled = prefs.getBool(SettingsScreen.kHapticsEnabled) ?? true;
      });
    }
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt(ReactionTimeScreen.kHighScore) ?? 0;
    });
  }

  Future<void> _saveHighScore(int newHighScore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(ReactionTimeScreen.kHighScore, newHighScore);
  }

  void _startWaitTimer() {
    final randomWaitTime = Random().nextInt(4000) + 2000;
    _timer = Timer(Duration(milliseconds: randomWaitTime), () {
      if (!mounted) return;
      setState(() {
        _state = ReactionState.readyToTap;
        _stopwatch.reset();
        _stopwatch.start();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _confettiController.dispose();

    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (_state) {
      case ReactionState.readyToTap: return Colors.green;
      case ReactionState.tooEarly: return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  Widget _buildContent() {
    switch (_state) {
      case ReactionState.waitingToStart:
        return const _GameMessage(icon: Icons.touch_app, title: 'מבחן זמן תגובה', subtitle: 'לחץ כדי להתחיל');
      case ReactionState.waitingForGreen:
        return const _GameMessage(icon: Icons.hourglass_bottom, title: 'המתן לירוק', subtitle: '');
      case ReactionState.readyToTap:
        return const _GameMessage(icon: Icons.touch_app, title: 'לחץ עכשיו!', subtitle: '');
      case ReactionState.tooEarly:
        return const _GameMessage(icon: Icons.warning, title: 'מוקדם מדי!', subtitle: 'לחץ כדי לנסות שוב');
      case ReactionState.finished:
        return _GameMessage(icon: Icons.bolt, title: '$_lastResult מילישניות', subtitle: 'לחץ לסיבוב הבא');
      case ReactionState.testFinished:
        return _buildTestFinishedView();
    }
  }

  Widget _buildTestFinishedView() {
    final best = _recentScores.reduce(min);
    final worst = _recentScores.reduce(max);
    final avg = _averageScore;
    final l10n = AppLocalizations.of(context)!;

    return _GameMessage(
      icon: Icons.checklist,
      title: l10n.reactionTestCompleteTitle,
      subtitle: l10n.reactionTestCompleteSummary(best, worst, avg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highScoreText = _highScore == 0 ? '--' : '$_highScore מילישניות';
    final averageScoreText = _averageScore == 0 && _recentScores.isEmpty ? '--' : '$_averageScore מילישניות';

    return GestureDetector(
      onTap: _onTapScreen,
      child: Scaffold(
        appBar: AppBar(
          title: Text('שיא: $highScoreText  |  ממוצע (5): $averageScoreText'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        backgroundColor: _getBackgroundColor(),
        body: Stack( // <-- New: Use a Stack to layer confetti on top
          alignment: Alignment.topCenter,
          children: [
            // This is our original game content
            Center(
              child: _buildContent(),
            ),
            // --- New: The confetti widget itself ---
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _GameMessage({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.white),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: const TextStyle(fontSize: 20, color: Colors.white70),
          ),
      ],
    );
  }
}