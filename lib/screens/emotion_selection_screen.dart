
import 'package:flutter/material.dart';

class EmotionSelectionScreen extends StatelessWidget {
  final emotions = [
    {'emoji': '😄', 'label': 'שמח'},
    {'emoji': '😡', 'label': 'כועס'},
    {'emoji': '😢', 'label': 'עצוב'},
    {'emoji': '😰', 'label': 'לחוץ'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('איך אתה מרגיש עכשיו?')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: emotions.map((e) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: () {
                // לכאן נוסיף ניווט למסך פעילות
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                textStyle: TextStyle(fontSize: 24),
              ),
              child: Text('${e['emoji']} ${e['label']}'),
            ),
          );
        }).toList(),
      ),
    );
  }
}
