import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as developer;

// ... (enum and Widget definition remain the same) ...
enum GameState { notStarted, gettingReady, waiting, readyToPress, finishedSuccess, finishedEarly, finishedTooLate }

class ImpulseControlGameScreen extends StatefulWidget {
  const ImpulseControlGameScreen({super.key});
  @override
  State<ImpulseControlGameScreen> createState() => _ImpulseControlGameScreenState();
}

class _ImpulseControlGameScreenState extends State<ImpulseControlGameScreen> with SingleTickerProviderStateMixin {
  GameState _gameState = GameState.notStarted;
  late AnimationController _animationController;
  Timer? _reactionTimer;
  Timer? _countdownTimer;
  int _score = 0;
  int _highScore = 0;
  int _countdown = 3;

  final AudioPlayer _sfxPlayer = AudioPlayer();

  void _log(String message) {
    final time = DateTime.now();
    final logMessage = '[${time.hour}:${time.minute}:${time.second}.${time.millisecond}] $message';
    developer.log(logMessage, name: 'GameLog');
  }

  // --- פונקציה משודרגת עם לכידת שגיאות ---
  Future<void> _playSound(String soundFile) async {
    _log('Attempting to play sound: $soundFile');
    try {
      // ReleaseMode.stop is good for short sound effects
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.play(AssetSource('sounds/$soundFile'));
      _log('Successfully initiated playing $soundFile');
    } catch (e) {
      _log('!!! ERROR playing sound "$soundFile": $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _log('--- initState: Screen Initialized ---');
    _loadHighScore();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _animationController.addListener(() => setState(() {}));
    _animationController.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _gameState == GameState.waiting) {
      setState(() => _gameState = GameState.readyToPress);
      final reactionMillis = max(500, 2000 - ((_score ~/ 3) * 150));
      _reactionTimer = Timer(Duration(milliseconds: reactionMillis), () {
        if (_gameState == GameState.readyToPress) {
          _playSound('failure.mp3');
          HapticFeedback.heavyImpact();
          _checkAndSaveHighScore();
          setState(() => _gameState = GameState.finishedTooLate);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reactionTimer?.cancel();
    _countdownTimer?.cancel();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdown = 3;
      _gameState = GameState.gettingReady;
    });
    _playSound('tick.mp3');

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
        _playSound('tick.mp3');
      } else {
        timer.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    final waitSeconds = max(1.5, 5.0 - (_score * 0.15));
    _animationController.duration = Duration(milliseconds: (waitSeconds * 1000).toInt());
    setState(() => _gameState = GameState.waiting);
    _animationController.reset();
    _animationController.forward();
  }

  void _resetGame() {
    _animationController.stop();
    _reactionTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() => _gameState = GameState.notStarted);
  }

  void _onButtonPressed() {
    switch (_gameState) {
      case GameState.notStarted:
        _score = 0;
        _startCountdown();
        break;
      case GameState.waiting:
        _playSound('failure.mp3');
        HapticFeedback.heavyImpact();
        _animationController.stop();
        _checkAndSaveHighScore();
        setState(() => _gameState = GameState.finishedEarly);
        break;
      case GameState.readyToPress:
        _playSound('success.mp3');
        HapticFeedback.lightImpact();
        _reactionTimer?.cancel();
        setState(() {
          _score++;
          _gameState = GameState.finishedSuccess;
        });
        Timer(const Duration(milliseconds: 1200), _startCountdown);
        break;
      case GameState.finishedEarly:
      case GameState.finishedTooLate:
        _resetGame();
        break;
      default:
        break;
    }
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _highScore = prefs.getInt('highScore') ?? 0);
  }

  void _checkAndSaveHighScore() async {
    if (_score > _highScore) {
      setState(() => _highScore = _score);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('שלב: ${_score + 1}  |  ניקוד: $_score  |  שיא: $_highScore'),
        centerTitle: true,
      ),
      body: Center(
        child: _buildGameContent(),
      ),
    );
  }

  Widget _buildGameContent() {
    if (_gameState == GameState.gettingReady) {
      return Text('$_countdown', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold));
    }
    final isWaiting = _gameState == GameState.waiting;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: _getMessageText(),
        ),
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: isWaiting ? _animationController.value : 1.0,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(_getCircleColor()),
              ),
            ),
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: _onButtonPressed,
                style: ButtonStyle(
                  shape: WidgetStateProperty.all<OutlinedBorder>(const CircleBorder()),
                  backgroundColor: WidgetStateProperty.all<Color>(isWaiting ? Colors.grey.shade700 : _getCircleColor()),
                ),
                child: Text(_getButtonText(), style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getCircleColor() {
    switch(_gameState) {
      case GameState.readyToPress: return Colors.green;
      case GameState.finishedTooLate:
      case GameState.finishedEarly: return Colors.red;
      case GameState.finishedSuccess: return Colors.amber;
      default: return Colors.blue;
    }
  }

  String _getButtonText() {
    switch (_gameState) {
      case GameState.notStarted: return 'שחק';
      case GameState.waiting: return '...';
      case GameState.readyToPress: return 'לחץ!';
      case GameState.finishedSuccess: return '✔';
      case GameState.finishedEarly:
      case GameState.finishedTooLate: return 'שוב?';
      case GameState.gettingReady: return '';
    }
  }

  Widget _getMessageText() {
    String text;
    TextStyle? style = Theme.of(context).textTheme.displaySmall;
    switch (_gameState) {
      case GameState.finishedSuccess: text = '+1'; break;
      case GameState.finishedEarly: text = 'מוקדם מדי!'; style = style?.copyWith(fontSize: 32); break;
      case GameState.finishedTooLate: text = 'מאוחר מדי!'; style = style?.copyWith(fontSize: 32); break;
      default: return const SizedBox.shrink();
    }
    return Text(text, key: ValueKey<String>(text), style: style?.copyWith(color: _getCircleColor()), textAlign: TextAlign.center);
  }
}