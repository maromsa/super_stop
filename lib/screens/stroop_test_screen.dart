import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as developer;
import 'settings_screen.dart';
import '../services/achievement_service.dart';
import 'package:confetti/confetti.dart'; // <-- New import

enum StroopState { notStarted, playing, finished }
enum StroopMode { sprint, accuracy }

class StroopTestScreen extends StatefulWidget {
  final StroopMode mode;
  const StroopTestScreen({super.key, required this.mode});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends State<StroopTestScreen> {
  StroopState _gameState = StroopState.notStarted;
  Timer? _timer;
  int _timeRemaining = 60;
  int _score = 0;
  late ConfettiController _confettiController;

  int _highScore = 0;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isNewHighScore = false;
  late AchievementService _achievementService;

  final Map<String, Color> _colors = {
    'אדום': Colors.red,
    'ירוק': Colors.green,
    'כחול': Colors.blue,
    'צהוב': Colors.yellow,
  };

  late String _currentWord;
  late Color _currentColor;
  late String _correctAnswerName;

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
    _generateNewRound();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _achievementService.markGamePlayed('stroop');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sfxPlayer.dispose();
    _confettiController.dispose();

    super.dispose();
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
    if (mounted) {
      setState(() {
        _highScore = prefs.getInt('stroop_high_score') ?? 0;
      });
    }
  }

  void _checkAndSaveHighScore() async {
    if (_score > _highScore) {
      _achievementService.unlockAchievement('new_high_score');
      _isNewHighScore = true;
      _confettiController.play();

      setState(() => _highScore = _score);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stroop_high_score', _highScore);
    } else {
      _isNewHighScore = false;
    }
  }

  void _playSound(String soundFile) {
    if (!_soundEnabled) return;
    AudioPlayer().play(AssetSource('sounds/$soundFile'));
  }

  void _startGame() {
    _isNewHighScore = false;
    setState(() {
      _score = 0;
      _timeRemaining = 60;
      _gameState = StroopState.playing;
      _generateNewRound();
    });

    if (widget.mode == StroopMode.sprint) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (_timeRemaining > 0) {
          setState(() => _timeRemaining--);
        } else {
          timer.cancel();
          _endGame();
        }
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _checkAndSaveHighScore();
        setState(() => _gameState = StroopState.finished);
      }
    });
  }

  void _generateNewRound() {
    final colorNames = _colors.keys.toList();
    final random = Random();

    String word;
    String colorName;

    do {
      word = colorNames[random.nextInt(colorNames.length)];
      colorName = colorNames[random.nextInt(colorNames.length)];
    } while (word == colorName);

    setState(() {
      _currentWord = word;
      _currentColor = _colors[colorName]!;
      _correctAnswerName = colorName;
    });
  }

  void _handleAnswer(String chosenColorName) {
    if (_gameState != StroopState.playing) return;

    if (chosenColorName == _correctAnswerName) {
      _playSound('success.mp3');
      if (_hapticsEnabled) HapticFeedback.lightImpact();
      setState(() => _score++);

      if (_score == 20) {
        _achievementService.unlockAchievement('stroop_score_20');
      }
    } else {
      _playSound('failure.mp3');
      if (_hapticsEnabled) HapticFeedback.heavyImpact();
    }

    if (widget.mode == StroopMode.accuracy) {
      _endGame();
    } else {
      _generateNewRound();
    }
  }

  Widget _buildButton(String colorName) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _colors[colorName],
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          onPressed: () => _handleAnswer(colorName),
          child: Text(
            colorName,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)]
            ),
          ),
        ),
      ),
    );
  }

  void _endGame() {
    _checkAndSaveHighScore();
    setState(() => _gameState = StroopState.finished);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מבחן סטרופ'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'זמן: $_timeRemaining',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack( // <-- New: Use a Stack to layer confetti on top
        alignment: Alignment.topCenter,
        children: [
          // This is our original game content
          Center(
            child: _buildGameContent(),
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
    );
  }

  Widget _buildGameContent() {
    switch (_gameState) {
      case StroopState.notStarted:
        return _buildStartView();
      case StroopState.playing:
        return _buildPlayingView();
      case StroopState.finished:
        return _buildFinishedView();
    }
  }

  Widget _buildStartView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.psychology, size: 80, color: Colors.blueGrey),
        const SizedBox(height: 20),
        const Text(
          'לחץ על הצבע, לא על המילה',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text('שיא אישי: $_highScore'),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)
          ),
          child: const Text('התחל', style: TextStyle(fontSize: 24)),
        ),
      ],
    );
  }

  Widget _buildPlayingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          'ניקוד: $_score',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          _currentWord,
          style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _currentColor,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2))]
          ),
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildButton('אדום'), _buildButton('ירוק')],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildButton('כחול'), _buildButton('צהוב')],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildFinishedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isNewHighScore) ...[
          const Icon(Icons.star, size: 80, color: Colors.amber),
          const SizedBox(height: 10),
          const Text(
            'שיא חדש!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
        ] else ...[
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 10),
          const Text(
            'הזמן נגמר!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'ניקוד סופי: $_score',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        Text(
          'שיא אישי: $_highScore',
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)
          ),
          child: const Text('שחק שוב', style: TextStyle(fontSize: 24)),
        ),
      ],
    );
  }
}