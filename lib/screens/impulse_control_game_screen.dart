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
import 'package:confetti/confetti.dart';

enum PowerUpType { shield }
class PowerUp {
  final PowerUpType type;
  final Alignment alignment;
  PowerUp({required this.type, required this.alignment});
}

enum GameState { notStarted, gettingReady, waiting, readyToPress, finishedSuccess, finishedEarly, finishedTooLate, gameOver }
enum GameMode { classic, survival }
class ImpulseControlGameScreen extends StatefulWidget {
  final GameMode mode;

  const ImpulseControlGameScreen({super.key, required this.mode});

  // --- New: Unique key for saving score history ---
  static const String kScoreHistory = 'impulse_score_history';

  @override
  State<ImpulseControlGameScreen> createState() => _ImpulseControlGameScreenState();
}

class _ImpulseControlGameScreenState extends State<ImpulseControlGameScreen> with SingleTickerProviderStateMixin {
  // ... (All existing state variables remain the same)
  GameState _gameState = GameState.notStarted;
  late AnimationController _animationController;
  Timer? _reactionTimer;
  Timer? _countdownTimer;
  int _score = 0;
  int _highScore = 0;
  int _countdown = 3;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  final AudioPlayer _sfxPlayer = AudioPlayer();
  late AchievementService _achievementService;
  late ConfettiController _confettiController;
  int _combo = 1;
  PowerUp? _powerUpOnScreen;
  bool _isShieldActive = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _achievementService.markGamePlayed('impulse');
    });

    AudioCache.instance.loadAll(['sounds/tick.mp3', 'sounds/success.mp3', 'sounds/failure.mp3']);
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _animationController.addListener(() => setState(() {}));
    _animationController.addStatusListener(_onAnimationStatusChanged);
  }

  void _spawnPowerUp() {
    // 25% chance to spawn a power-up if one isn't already on screen
    if (_powerUpOnScreen == null && Random().nextInt(4) == 0) {
      final random = Random();
      // Generate a random position on the screen
      final alignment = Alignment(
        random.nextDouble() * 1.6 - 0.8, // x from -0.8 to 0.8
        random.nextDouble() * 1.6 - 0.8, // y from -0.8 to 0.8
      );
      setState(() {
        _powerUpOnScreen = PowerUp(type: PowerUpType.shield, alignment: alignment);
      });
    }
  }

  // --- New: Logic to collect a power-up ---
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
      Timer(const Duration(milliseconds: 1200), _startCountdown);
    } else {
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

  // --- New: Method to save the score to a list ---
  Future<void> _saveScoreToHistory() async {
    if (_score == 0) return; // Don't save zero scores
    final prefs = await SharedPreferences.getInstance();

    // Fetch the existing list, or create a new one
    final history = prefs.getStringList(ImpulseControlGameScreen.kScoreHistory) ?? [];

    // Add the new score
    history.add(_score.toString());

    // Keep the list at a max of 20 entries
    if (history.length > 20) {
      history.removeAt(0);
    }

    // Save the updated list
    await prefs.setStringList(ImpulseControlGameScreen.kScoreHistory, history);
    developer.log('Impulse game score history saved: $history');
  }

  void _handleGameOver() {
    _checkAndSaveHighScore();
    _saveScoreToHistory(); // Save score to history on game over
    // --- New: Logic to handle different modes ---
    _combo = 1;
    if (widget.mode == GameMode.survival) {
      setState(() => _gameState = GameState.gameOver);
    }
  }

  void _onButtonPressed() {
    switch (_gameState) {
    // ... (success case is the same)
      case GameState.waiting:
        _handleFailure();
        if (!_isShieldActive) setState(() => _gameState = GameState.finishedEarly);
        break;
      case GameState.gameOver:
        Navigator.of(context).pop();
        break;

    // ... (other cases are the same)
      case GameState.readyToPress:
        _handleFailure();
        if (!_isShieldActive) {
          setState(() => _gameState = GameState.finishedTooLate);
        }
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

      case GameState.notStarted:
        _score = 0;
        _combo = 1;
        _isShieldActive = false;
        _powerUpOnScreen = null;
        _startCountdown();
        break;
      case GameState.finishedEarly:
      case GameState.finishedTooLate:
        _resetGame();
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
          _playSound('failure.mp3');
          if (_hapticsEnabled) HapticFeedback.heavyImpact();
          _handleGameOver(); // <-- Call the new game over handler
          setState(() => _gameState = GameState.finishedTooLate);
        }
      });
    }
  }

  // --- The rest of the file is unchanged ---
  void _checkAndSaveHighScore() async {
    if (_score > _highScore) {
      _achievementService.unlockAchievement('new_high_score');
      _confettiController.play();
      setState(() => _highScore = _score);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('impulse_high_score', _highScore);
    }
  }

  void _log(String message) {
    final time = DateTime.now();
    final logMessage = '[${time.hour}:${time.minute}:${time.second}.${time.millisecond}] $message';
    developer.log(logMessage, name: 'GameLog');
  }

  Future<void> _playSound(String soundFile) async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      _log('!!! ERROR playing sound "$soundFile": $e');
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

  @override
  void dispose() {
    _animationController.dispose();
    _reactionTimer?.cancel();
    _countdownTimer?.cancel();
    _sfxPlayer.dispose();
    _confettiController.dispose();

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
      body: Stack( // <-- New: Use a Stack to layer confetti on top
        alignment: Alignment.topCenter,
        children: [
          // This is our original game content
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
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, color: Colors.lightBlueAccent, size: 40),
                ),
              ),
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
    if (_gameState == GameState.gettingReady) {
      return Text('$_countdown', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold));
    }
    if (_gameState == GameState.gameOver) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: _combo > 1
                ? Text('x$_combo COMBO!', key: ValueKey<int>(_combo), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber))
                : SizedBox(key: const ValueKey<int>(0), height: 34), // Placeholder for alignment
          ),
          const SizedBox(height: 10),
          const Icon(Icons.gamepad, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          const Text('Game Over', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text('Final Score: $_score', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Return Home'),
          )
        ],
      );
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
      case GameState.gameOver: return 'Home';
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