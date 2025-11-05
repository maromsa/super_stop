import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'dart:developer' as developer;
import 'package:super_stop/l10n/app_localizations.dart';

import 'settings_screen.dart';
import '../services/achievement_service.dart';

// Data structures for Power-Ups
enum PowerUpType { shield }

class PowerUp {
  final PowerUpType type;
  final Alignment alignment;
  PowerUp({required this.type, required this.alignment});
}

enum GameMode { classic, survival }
enum GameState { notStarted, gettingReady, waiting, readyToPress, finishedSuccess, finishedEarly, finishedTooLate, gameOver }

class ImpulseControlGameScreen extends StatefulWidget {
  final GameMode mode;
  const ImpulseControlGameScreen({super.key, required this.mode});
  static const String kScoreHistory = 'impulse_score_history';
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
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  late ConfettiController _confettiController;
  late AchievementService _achievementService;
  int _combo = 1;

  // State variables for Power-Ups
  PowerUp? _powerUpOnScreen;
  bool _isShieldActive = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _loadSettings();
    _loadHighScore();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _achievementService.markGamePlayed('impulse');
    });

    AudioCache.instance.loadAll(['sounds/tick.mp3', 'sounds/success.mp3', 'sounds/failure.mp3']);
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _animationController.addListener(() => setState(() {}));
    _animationController.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _achievementService = Provider.of<AchievementService>(context, listen: false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reactionTimer?.cancel();
    _countdownTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  // --- All Logic Methods ---

  void _spawnPowerUp() {
    if (_powerUpOnScreen == null && Random().nextInt(4) == 0) { // 25% chance
      final random = Random();
      final alignment = Alignment(
        random.nextDouble() * 1.6 - 0.8, // x from -0.8 to 0.8
        random.nextDouble() * 1.6 - 0.8, // y from -0.8 to 0.8
      );
      setState(() {
        _powerUpOnScreen = PowerUp(type: PowerUpType.shield, alignment: alignment);
      });
    }
  }

  void _collectPowerUp() {
    if (_powerUpOnScreen?.type == PowerUpType.shield) {
      setState(() {
        _isShieldActive = true;
      });
    }
    setState(() {
      _powerUpOnScreen = null;
    });
  }

  void _handleFailure() {
    if (_isShieldActive) {
      setState(() {
        _isShieldActive = false;
        _combo = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המגן הגן עליך!'), duration: Duration(seconds: 1), backgroundColor: Colors.blue)
      );
      // Restart the round after a short delay
      Timer(const Duration(milliseconds: 1200), _startCountdown);
    } else {
      // Original failure logic
      _playSound('failure.mp3');
      if (_hapticsEnabled) HapticFeedback.heavyImpact();
      _animationController.stop();
      _checkAndSaveHighScore();
      _saveScoreToHistory();
      setState(() {
        _combo = 1;
        if (widget.mode == GameMode.survival) {
          _gameState = GameState.gameOver;
        }
      });
    }
  }

  void _onButtonPressed() {
    switch (_gameState) {
      case GameState.notStarted:
        _score = 0;
        _combo = 1;
        _isShieldActive = false;
        _powerUpOnScreen = null;
        _startCountdown();
        break;
      case GameState.waiting:
        _handleFailure(); // Call the unified failure handler
        if (!_isShieldActive) setState(() => _gameState = GameState.finishedEarly);
        break;
      case GameState.readyToPress:
        _playSound('success.mp3');
        if (_hapticsEnabled) HapticFeedback.lightImpact();
        _reactionTimer?.cancel();

        setState(() {
          _score += _combo;
          _combo++;
          _gameState = GameState.finishedSuccess;
        });

        if (_score >= 10) _achievementService.unlockAchievement('impulse_score_10');

        _spawnPowerUp();

        Timer(const Duration(milliseconds: 1200), _startCountdown);
        break;
      case GameState.finishedEarly:
      case GameState.finishedTooLate:
        _resetGame();
        break;
      case GameState.gameOver:
        Navigator.of(context).pop();
        break;
      default:
        break;
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _gameState == GameState.waiting) {
      setState(() => _gameState = GameState.readyToPress);
      final reactionMillis = max(500, 2000 - ((_score ~/ 3) * 150));
      _reactionTimer = Timer(Duration(milliseconds: reactionMillis), () {
        if (_gameState == GameState.readyToPress) {
          _handleFailure(); // Call the unified failure handler
          if (!_isShieldActive) {
            setState(() => _gameState = GameState.finishedTooLate);
          }
        }
      });
    }
  }

  Future<void> _saveScoreToHistory() async {
    if (_score == 0) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(ImpulseControlGameScreen.kScoreHistory) ?? [];
    history.add(_score.toString());
    if (history.length > 20) {
      history.removeAt(0);
    }
    await prefs.setStringList(ImpulseControlGameScreen.kScoreHistory, history);
  }

  void _checkAndSaveHighScore() async {
    if (_score > _highScore) {
      _achievementService.unlockAchievement('new_high_score');
      _confettiController.play();
      setState(() => _highScore = _score);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('impulse_high_score', _highScore);
    }
  }

  Future<void> _playSound(String soundFile) async {
    if (!_soundEnabled) return;
    try {
      // Create a new player for each sound to avoid conflicts
      await AudioPlayer().play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      developer.log('שגיאה בהשמעת הצליל "$soundFile": $e', name: 'GameLog');
    }
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

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _highScore = prefs.getInt('impulse_high_score') ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('שלב: ${_score + 1}  |  ניקוד: $_score  |  שיא: $_highScore'),
        centerTitle: true,
        actions: [
          if (_isShieldActive)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.shield, color: Colors.blue, size: 30),
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _buildGameContent(),
          ),
          if (_powerUpOnScreen != null)
            Align(
              alignment: _powerUpOnScreen!.alignment,
              child: GestureDetector(
                onTap: _collectPowerUp,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.lightBlueAccent, width: 2),
                  ),
                  child: const Icon(Icons.shield, color: Colors.lightBlueAccent, size: 40),
                ),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    final l10n = AppLocalizations.of(context)!;
    if (_gameState == GameState.gettingReady) {
      return Text('$_countdown', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold));
    }
    if (_gameState == GameState.gameOver) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gamepad, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          Text(l10n.impulseGameOverTitle, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text(l10n.impulseFinalScore(_score), style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.impulseReturnHome),
          )
        ],
      );
    }
    final isWaiting = _gameState == GameState.waiting;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: _combo > 1
              ? Text(
                  l10n.impulseComboLabel(_combo),
                  key: ValueKey<int>(_combo),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber),
                )
              : SizedBox(key: const ValueKey<int>(0), height: 34), // Placeholder for alignment
        ),
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
                  shape: MaterialStateProperty.all<OutlinedBorder>(const CircleBorder()),
                  backgroundColor: MaterialStateProperty.all<Color>(isWaiting ? Colors.grey.shade700 : _getCircleColor()),
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
      case GameState.gameOver: return 'חזרה';
    }
  }

  Widget _getMessageText() {
    String text;
    TextStyle? style = Theme.of(context).textTheme.displaySmall;
    switch (_gameState) {
      case GameState.finishedSuccess: text = '+${_combo -1}'; break; // Show combo bonus
      case GameState.finishedEarly: text = widget.mode == GameMode.survival ? 'המשחק נגמר!' : 'מוקדם מדי!'; style = style?.copyWith(fontSize: 32); break;
      case GameState.finishedTooLate: text = widget.mode == GameMode.survival ? 'המשחק נגמר!' : 'מאוחר מדי!'; style = style?.copyWith(fontSize: 32); break;
      default: return const SizedBox(key: ValueKey<String>('empty'), height: 34); // Placeholder
    }
    return Text(text, key: ValueKey<String>(text), style: style?.copyWith(color: _getCircleColor()), textAlign: TextAlign.center);
  }
}