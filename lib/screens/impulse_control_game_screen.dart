import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// Enum to manage the game's state clearly
enum GameState { notStarted, waiting, finishedSuccess, finishedEarly }

class ImpulseControlGameScreen extends StatefulWidget {
  const ImpulseControlGameScreen({super.key});

  @override
  State<ImpulseControlGameScreen> createState() => _ImpulseControlGameScreenState();
}

class _ImpulseControlGameScreenState extends State<ImpulseControlGameScreen> {
  // Use the enum for state management
  GameState _gameState = GameState.notStarted;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Starts the game logic
  void _startGame() {
    // Play sound
    _audioPlayer.play(AssetSource('sounds/whistle.mp3'));

    // Set the state to waiting
    setState(() {
      _gameState = GameState.waiting;
    });

    // Start a 5-second timer
    _timer = Timer(const Duration(seconds: 5), () {
      // This block runs ONLY after 5 seconds
      // If the user hasn't clicked early, the state will still be 'waiting'
      if (_gameState == GameState.waiting) {
        setState(() {
          _gameState = GameState.finishedSuccess;
        });
      }
    });
  }

  /// Resets the game to its initial state
  void _resetGame() {
    _timer?.cancel(); // Stop any active timer
    setState(() {
      _gameState = GameState.notStarted;
    });
  }

  /// Handles the main button press based on the current game state
  void _onButtonPressed() {
    switch (_gameState) {
      case GameState.notStarted:
        _startGame();
        break;
      case GameState.waiting:
      // User clicked too early!
        _timer?.cancel(); // Stop the timer
        setState(() {
          _gameState = GameState.finishedEarly;
        });
        break;
      case GameState.finishedSuccess:
      case GameState.finishedEarly:
      // If the game is over, the button resets it
        _resetGame();
        break;
    }
  }

  // Helper to get the button text based on state
  String _getButtonText() {
    switch (_gameState) {
      case GameState.notStarted:
        return 'התחל';
      case GameState.waiting:
        return '...המתן...';
      case GameState.finishedSuccess:
      case GameState.finishedEarly:
        return 'שחק שוב';
    }
  }

  // Helper to get the message text based on state
  String _getMessageText() {
    switch (_gameState) {
      case GameState.finishedEarly:
        return 'עצור! לחצת מוקדם מדי, נסה שוב';
      case GameState.finishedSuccess:
        return 'כל הכבוד! הצלחת לעצור בזמן!';
      default:
        return 'לחץ על "התחל" והמתן לסיום הצליל';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('משחק שליטה באימפולסים'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display the message based on game state
            Text(
              _getMessageText(),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // The main game button
            SizedBox(
              width: 200,
              height: 200,
              child: ElevatedButton(
                onPressed: _onButtonPressed,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: _gameState == GameState.waiting ? Colors.grey : Colors.blue,
                ),
                child: Text(
                  _getButtonText(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}