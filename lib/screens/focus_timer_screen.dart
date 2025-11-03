import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_goals_provider.dart';

enum TimerState { idle, focus, breakTime, completed }

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  Timer? _timer;
  int _timeRemaining = 0; // in seconds
  TimerState _state = TimerState.idle;
  int _selectedFocusMinutes = 5; // Default 5 minutes for ADHD kids
  int _selectedBreakMinutes = 2;
  bool _soundEnabled = true;
  int _completedSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPreferences();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFocusMinutes = prefs.getInt('focus_minutes') ?? 5;
      _selectedBreakMinutes = prefs.getInt('break_minutes') ?? 2;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focus_minutes', _selectedFocusMinutes);
    await prefs.setInt('break_minutes', _selectedBreakMinutes);
  }

  void _startFocus() {
    setState(() {
      _state = TimerState.focus;
      _timeRemaining = _selectedFocusMinutes * 60;
    });
    _playSound('tick.mp3');
    _startTimer();
  }

  void _startBreak() {
    setState(() {
      _state = TimerState.breakTime;
      _timeRemaining = _selectedBreakMinutes * 60;
    });
    _playSound('tick.mp3');
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          timer.cancel();
          _onTimerComplete();
        }
      });
    });
  }

  void _onTimerComplete() {
    if (_state == TimerState.focus) {
      _completedSessions++;
      // Award coins for completing focus session
      Provider.of<CoinProvider>(context, listen: false).addCoins(5);
      
      // Mark daily goal progress
      Provider.of<DailyGoalsProvider>(context, listen: false)
          .completeFocusSession(_selectedFocusMinutes);

      setState(() {
        _state = TimerState.completed;
      });
      _playSound('success.mp3');
    } else if (_state == TimerState.breakTime) {
      setState(() {
        _state = TimerState.idle;
      });
      _playSound('tick.mp3');
    }
  }

  void _pause() {
    _timer?.cancel();
  }

  void _resume() {
    _startTimer();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _state = TimerState.idle;
      _timeRemaining = 0;
    });
  }

  void _playSound(String soundFile) {
    if (!_soundEnabled) return;
    AudioPlayer().play(AssetSource('sounds/$soundFile'));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('טיימר ריכוז'),
        centerTitle: true,
      ),
      body: _state == TimerState.idle
          ? _buildSetupView()
          : _buildTimerView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'בחר זמן ריכוז',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          _buildTimeSelector(
            'זמן ריכוז (דקות)',
            _selectedFocusMinutes,
            [3, 5, 10, 15, 20],
            (value) {
              setState(() {
                _selectedFocusMinutes = value;
              });
              _savePreferences();
            },
          ),
          const SizedBox(height: 30),
          _buildTimeSelector(
            'זמן הפסקה (דקות)',
            _selectedBreakMinutes,
            [1, 2, 3, 5],
            (value) {
              setState(() {
                _selectedBreakMinutes = value;
              });
              _savePreferences();
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _startFocus,
            icon: const Icon(Icons.play_arrow),
            label: const Text('התחל ריכוז'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              textStyle: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'השלמת: $_completedSessions מפגשי ריכוז היום',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(String title, int currentValue, List<int> options, Function(int) onChanged) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          alignment: WrapAlignment.center,
          children: options.map((minutes) {
            final isSelected = minutes == currentValue;
            return ChoiceChip(
              label: Text('$minutes דק׳'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(minutes);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimerView() {
    final isFocus = _state == TimerState.focus;
    final isBreak = _state == TimerState.breakTime;
    final isCompleted = _state == TimerState.completed;

    Color backgroundColor;
    String title;
    IconData icon;

    if (isFocus) {
      backgroundColor = Colors.blue;
      title = 'זמן ריכוז';
      icon = Icons.school;
    } else if (isBreak) {
      backgroundColor = Colors.green;
      title = 'זמן הפסקה';
      icon = Icons.coffee;
    } else {
      backgroundColor = Colors.amber;
      title = 'הושלם!';
      icon = Icons.check_circle;
    }

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _formatTime(_timeRemaining),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 60),
            if (isFocus || isBreak)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('השהה'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: backgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _resume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('המשך'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: backgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              ),
            if (isCompleted) ...[
              const Text(
                'כל הכבוד! השלמת מפגש ריכוז!',
                style: TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  _reset();
                  _startBreak();
                },
                icon: const Icon(Icons.coffee),
                label: const Text('קח הפסקה'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  _reset();
                },
                child: const Text(
                  'חזור לתפריט',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

