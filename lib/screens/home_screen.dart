import 'package:flutter/material.dart';
import 'impulse_control_game_screen.dart'; // Make sure this import is correct
import 'settings_screen.dart';             // Make sure this import is correct

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Stop'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'שפרו את האיפוק שלכם',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),

            // --- כפתור "שחק" ---
            SizedBox(
              width: 200,
              height: 80,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 40),
                label: const Text(
                  'שחק',
                  style: TextStyle(fontSize: 32),
                ),
                onPressed: () {
                  // The "Play" button should navigate to the GAME screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImpulseControlGameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- כפתור "הגדרות" ---
            TextButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('הגדרות'),
              onPressed: () {
                // The "Settings" button should navigate to the SETTINGS screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}