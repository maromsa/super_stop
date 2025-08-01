import 'package:flutter/material.dart';
import 'impulse_control_game_screen.dart';
import 'reaction_time_screen.dart'; // <-- Import the new game screen
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showInstructionsDialog(BuildContext context) {
    // ... (The instruction dialog code remains the same)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('איך משחקים?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'משחק איפוק:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('חכה שהעיגול יתמלא וירוק, ואז לחץ מהר!'),
                SizedBox(height: 15),
                Text(
                  'מבחן תגובה:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('חכה שהמסך יהפוך לירוק, ואז לחץ מהר!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('הבנתי'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Stop'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'איך משחקים?',
            onPressed: () {
              _showInstructionsDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'בחר אתגר',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),

            // --- This section is new ---
            // Button for the Impulse Control game
            _GameSelectionButton(
              label: 'משחק איפוק',
              icon: Icons.timer,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ImpulseControlGameScreen()),
                );
              },
            ),
            const SizedBox(height: 20),

            // Button for the Reaction Time game
            _GameSelectionButton(
              label: 'מבחן תגובה',
              icon: Icons.bolt,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReactionTimeScreen()),
                );
              },
            ),
            // --- End of new section ---

            const SizedBox(height: 40),
            TextButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('הגדרות'),
              onPressed: () {
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

// Helper widget for consistent button styling
class _GameSelectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _GameSelectionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 70,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 32),
        label: Text(
          label,
          style: const TextStyle(fontSize: 24),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}