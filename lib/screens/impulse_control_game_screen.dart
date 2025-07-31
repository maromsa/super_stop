import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ImpulseControlGameScreen extends StatefulWidget {
  const ImpulseControlGameScreen({Key? key}) : super(key: key);

  @override
  State<ImpulseControlGameScreen> createState() => _ImpulseControlGameScreenState();
}

class _ImpulseControlGameScreenState extends State<ImpulseControlGameScreen> {
  bool gameStarted = false;
  bool success = false;
  String message = "לחץ על 'התחל' כדי לשחק";

  Timer? timer;
  final AudioPlayer audioPlayer = AudioPlayer();

  void startGame() async {
    setState(() {
      gameStarted = true;
      success = false;
      message = "המתן עד שהצליל ייגמר...";
    });

    // השמעת השיריקה
    await audioPlayer.play(AssetSource('sounds/whistle.mp3'));

    timer = Timer(Duration(seconds: 5), () {
      setState(() {
        success = true;
        message = "כל הכבוד! הצלחת לעצור בזמן!";
        gameStarted = false;
      });
    });
  }

  void onButtonPressed() {
    if (!gameStarted) {
      startGame();
    } else {
      timer?.cancel();
      audioPlayer.stop();

      setState(() {
        message = "עצור! לחצת מוקדם מדי, נסה שוב.";
        gameStarted = false;
        success = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('משחק שליטה באימפולסיביות'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 200),
                  shape: CircleBorder(),
                  backgroundColor: success ? Colors.green : Colors.blue,
                ),
                child: Text(
                  gameStarted ? 'אל תלחץ!' : 'התחל',
                  style: TextStyle(fontSize: 32, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
