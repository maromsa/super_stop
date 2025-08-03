import 'package:flutter/material.dart';
import 'achievements_screen.dart'; // This is the crucial import
import 'impulse_control_game_screen.dart';
import 'reaction_time_screen.dart';
import 'stroop_test_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('איך משחקים?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('משחק איפוק:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('חכה שהעיגול יתמלא וירוק, ואז לחץ מהר!'),
                SizedBox(height: 15),
                Text('מבחן תגובה:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('חכה שהמסך יהפוך לירוק, ואז לחץ מהר!'),
                SizedBox(height: 15),
                Text('מבחן סטרופ:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('לחץ על הכפתור שצבעו תואם לצבע המילה, לא למילה עצמה.'),
              ],
            ),
          ),
          actions: <Widget>[ TextButton(child: const Text('הבנתי'), onPressed: () => Navigator.of(context).pop()) ],
        );
      },
    );
  }

  void _showReactionModeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('בחר מצב משחק'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReactionTimeScreen(mode: ReactionMode.classic)));
              },
              child: const Text('קלאסי (אינסופי)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReactionTimeScreen(mode: ReactionMode.fiveRoundTest)));
              },
              child: const Text('מבחן (5 סיבובים)'),
            ),
          ],
        );
      },
    );
  }

  // --- New: Method to show the mode selection dialog ---
  void _showImpulseModeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('בחר צורת משחק'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpulseControlGameScreen(mode: GameMode.classic)));
              },
              child: const Text('קלאסי'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ImpulseControlGameScreen(mode: GameMode.survival)));
              },
              child: const Text('הישרדות'),
            ),
          ],
        );
      },
    );
  }

  void _showStroopModeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('בחר מצב משחק'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StroopTestScreen(mode: StroopMode.sprint)));
              },
              child: const Text('ספרינט (60 שניות)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StroopTestScreen(mode: StroopMode.accuracy)));
              },
              child: const Text('דיוק (טעות אחת פוסלת)'),
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
            onPressed: () => _showInstructionsDialog(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('בחר אתגר', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _GameSelectionButton(
              label: 'משחק איפוק',
              icon: Icons.timer,
              // --- Changed: Call the selector instead of navigating directly ---
              onPressed: () => _showImpulseModeSelector(context),
            ),
            const SizedBox(height: 20),
            _GameSelectionButton(
              label: 'מבחן תגובה',
              icon: Icons.bolt,
              onPressed: () => _showReactionModeSelector(context),
            ),
            const SizedBox(height: 20),
            _GameSelectionButton(
              label: 'מבחן סטרופ',
              icon: Icons.psychology,
              onPressed: () => _showStroopModeSelector(context),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('הישגים'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()));
                  },
                ),
                const SizedBox(width: 20),
                TextButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('הגדרות'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _GameSelectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _GameSelectionButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 70,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 32),
        label: Text(label, style: const TextStyle(fontSize: 24)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}