import 'package:flutter/material.dart';
import 'impulse_control_game_screen.dart';

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
            // כותרת ראשית של המסך
            const Text(
              'שפרו את האיפוק שלכם',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),

            // כפתור "שחק" גדול
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
                  // ניווט למסך המשחק כאשר לוחצים
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

            // כפתור "הגדרות" קטן יותר
            TextButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('הגדרות'),
              onPressed: () {
                // TODO: בעתיד נוביל למסך הגדרות אמיתי
                // כרגע, אפשר להציג הודעה זמנית
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('מסך הגדרות יבנה בקרוב!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}