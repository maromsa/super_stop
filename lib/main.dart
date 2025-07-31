import 'package:flutter/material.dart';
import 'screens/emotion_selection_screen.dart';

void main() {
  runApp(SuperStopApp());
}

class SuperStopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'סופרסטופ',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Alef',
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: EmotionSelectionScreen(),
      ),
      debugShowCheckedModeBanner: false,
      locale: const Locale('he'),
      supportedLocales: const [
        Locale('he'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
