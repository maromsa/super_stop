import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Enum to manage the different states of the reaction game
enum ReactionState {
  waitingToStart,
  waitingForGreen,
  readyToTap,
  finished,
  tooEarly
}

class ReactionTimeScreen extends StatefulWidget {
  const ReactionTimeScreen({super.key});

  @override
  State<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

class _ReactionTimeScreenState extends State<ReactionTimeScreen> {
  ReactionState _state = ReactionState.waitingToStart;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _resultMilliseconds = 0;

  // Handles all tap events on the screen
  void _onTapScreen() {
    setState(() {
      switch (_state) {
        case ReactionState.waitingToStart:
        // Start the waiting process
          _state = ReactionState.waitingForGreen;
          _startWaitTimer();
          break;
        case ReactionState.waitingForGreen:
        // User tapped before the screen turned green
          _timer?.cancel();
          _state = ReactionState.tooEarly;
          break;
        case ReactionState.readyToTap:
        // User tapped successfully
          _stopwatch.stop();
          _resultMilliseconds = _stopwatch.elapsedMilliseconds;
          _state = ReactionState.finished;
          break;
        case ReactionState.finished:
        case ReactionState.tooEarly:
        // Tap to reset the game
          _state = ReactionState.waitingToStart;
          break;
      }
    });
  }

  // Starts a timer for a random duration
  void _startWaitTimer() {
    // Generate a random wait time between 2 and 6 seconds
    final randomWaitTime = Random().nextInt(4000) + 2000; // 2000ms to 6000ms
    _timer = Timer(Duration(milliseconds: randomWaitTime), () {
      // When the timer fires, change the state and start the stopwatch
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
    super.dispose();
  }

  // Helper to get the screen color based on the state
  Color _getBackgroundColor() {
    switch (_state) {
      case ReactionState.readyToTap:
        return Colors.green;
      case ReactionState.tooEarly:
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  // Helper to get the content (icon and text) for the screen
  Widget _buildContent() {
    switch (_state) {
      case ReactionState.waitingToStart:
        return const _GameMessage(
          icon: Icons.touch_app,
          title: 'מבחן זמן תגובה',
          subtitle: 'לחץ כדי להתחיל',
        );
      case ReactionState.waitingForGreen:
        return const _GameMessage(
          icon: Icons.hourglass_bottom,
          title: 'המתן לירוק',
          subtitle: 'אל תלחץ עדיין...',
        );
      case ReactionState.readyToTap:
        return const _GameMessage(
          icon: Icons.touch_app,
          title: 'לחץ עכשיו!',
          subtitle: '',
        );
      case ReactionState.tooEarly:
        return const _GameMessage(
          icon: Icons.warning,
          title: 'מוקדם מדי!',
          subtitle: 'לחץ כדי לנסות שוב',
        );
      case ReactionState.finished:
        return _GameMessage(
          icon: Icons.bolt,
          title: '$_resultMilliseconds ms',
          subtitle: 'לחץ כדי לשחק שוב',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTapScreen,
      child: Scaffold(
        backgroundColor: _getBackgroundColor(),
        body: Center(
          child: _buildContent(),
        ),
      ),
    );
  }
}

// A simple helper widget for displaying the game messages
class _GameMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GameMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.white),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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