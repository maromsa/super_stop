import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/coin_provider.dart';

// Enum for the game modes, including the new 'versus' mode
enum StroopMode { sprint, accuracy, versus }

// New, more detailed enum for the multiplayer game flow
enum StroopState { notStarted, p1Playing, p1Finished, p2Playing, results }

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

  // Score variables for both players
  int _p1Score = 0;
  int _p2Score = 0;
  int _currentPlayerScore = 0;

  final Map<String, Color> _colors = {
    'אדום': Colors.red, 'ירוק': Colors.green, 'כחול': Colors.blue, 'צהוב': Colors.yellow,
  };
  late String _currentWord;
  late Color _currentColor;
  late String _correctAnswerName;

  @override
  void initState() {
    super.initState();
    _generateNewRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame(int player) {
    setState(() {
      _currentPlayerScore = 0;
      _timeRemaining = 60;
      _gameState = (player == 1) ? StroopState.p1Playing : StroopState.p2Playing;
      _generateNewRound();
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _endRound();
      }
    });
  }

  void _endRound() {
    setState(() {
      if (_gameState == StroopState.p1Playing) {
        _p1Score = _currentPlayerScore;
        _gameState = StroopState.p1Finished;
      } else if (_gameState == StroopState.p2Playing) {
        _p2Score = _currentPlayerScore;
        _gameState = StroopState.results;
      }
    });
  }

  void _handleAnswer(String chosenColorName) {
    if (_gameState != StroopState.p1Playing && _gameState != StroopState.p2Playing) return;

    // Access the CoinProvider from the context
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    if (chosenColorName == _correctAnswerName) {
      // --- This is the new logic ---
      coinProvider.addCoins(1); // Award 1 coin for a correct answer

      setState(() => _currentPlayerScore++);
    }
    _generateNewRound();
  }

  void _onMainButtonPressed() {
    switch (_gameState) {
      case StroopState.notStarted:
        _startGame(1);
        break;
      case StroopState.p1Finished:
        _startGame(2);
        break;
      case StroopState.results:
        setState(() {
          _p1Score = 0;
          _p2Score = 0;
          _gameState = StroopState.notStarted;
        });
        break;
      default:
        break;
    }
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

    if (mounted) {
      setState(() {
        _currentWord = word;
        _currentColor = _colors[colorName]!;
        _correctAnswerName = colorName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מבחן סטרופ: ראש בראש'),
        actions: (_gameState == StroopState.p1Playing || _gameState == StroopState.p2Playing)
            ? [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text('זמן: $_timeRemaining', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ]
            : null,
      ),
      body: Center(
        child: _buildGameContent(),
      ),
    );
  }

  Widget _buildGameContent() {
    switch (_gameState) {
      case StroopState.notStarted:
        return _buildStartView();
      case StroopState.p1Playing:
        return _buildPlayingView(player: 1);
      case StroopState.p1Finished:
        return _buildTransitionView();
      case StroopState.p2Playing:
        return _buildPlayingView(player: 2);
      case StroopState.results:
        return _buildResultsView();
    }
  }

  Widget _buildStartView() {
    return _buildMessageView(
      icon: Icons.people,
      title: 'מצב ראש בראש',
      buttonText: 'התחל משחק',
    );
  }

  Widget _buildTransitionView() {
    return _buildMessageView(
      icon: Icons.switch_account, // <-- This is the corrected icon
      title: 'תורו של שחקן 2',
      subtitle: 'שחקן 1 השיג: $_p1Score נקודות',
      buttonText: 'התחל סיבוב',
    );
  }

  Widget _buildResultsView() {
    String resultText;
    IconData resultIcon;
    Color resultColor;

    if (_p1Score > _p2Score) {
      resultText = 'שחקן 1 מנצח!';
      resultIcon = Icons.looks_one;
      resultColor = Colors.amber;
    } else if (_p2Score > _p1Score) {
      resultText = 'שחקן 2 מנצח!';
      resultIcon = Icons.looks_two;
      resultColor = Colors.lightBlue;
    } else {
      resultText = 'תיקו!';
      resultIcon = Icons.handshake;
      resultColor = Colors.green;
    }

    return _buildMessageView(
      icon: resultIcon,
      iconColor: resultColor,
      title: resultText,
      subtitle: 'שחקן 1: $_p1Score\nשחקן 2: $_p2Score',
      buttonText: 'שחק שוב',
    );
  }

  Widget _buildPlayingView({required int player}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          'שחקן $player | ניקוד: $_currentPlayerScore',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(
          _currentWord,
          style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: _currentColor, shadows: const [Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2))]),
        ),
        Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildButton('אדום'), _buildButton('ירוק')]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildButton('כחול'), _buildButton('צהוב')]),
          ],
        )
      ],
    );
  }

  Widget _buildMessageView({required IconData icon, Color? iconColor, required String title, String? subtitle, required String buttonText}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: iconColor ?? Colors.blueGrey),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _onMainButtonPressed,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
          child: Text(buttonText, style: const TextStyle(fontSize: 24)),
        ),
      ],
    );
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
}