import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // <--- הוסף את הייבוא הזה

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Stop',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // --- השינוי המרכזי נמצא כאן ---
      home: const HomeScreen(), // במקום ImpulseControlGameScreen()
    );
  }
}