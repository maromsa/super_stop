// lib/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/mood_entry.dart';
import 'utils/prefs_keys.dart';

class MoodThemeDetails {
  const MoodThemeDetails({
    required this.mood,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundGradient,
    this.backgroundAsset,
    this.soundAsset,
  });

  final Mood mood;
  final Color primaryColor;
  final Color secondaryColor;
  final LinearGradient backgroundGradient;
  final String? backgroundAsset;
  final String? soundAsset;
}

class _MoodPalette {
  const _MoodPalette({
    required this.primary,
    required this.secondary,
    required this.gradient,
    this.asset,
    this.sound,
  });

  final Color primary;
  final Color secondary;
  final List<Color> gradient;
  final String? asset;
  final String? sound;
}

class ThemeProvider with ChangeNotifier {
  static const String kThemeMode = 'theme_mode';

  ThemeProvider() {
    final initialDetails = _resolveDetailsForMood(_activeMood);
    _moodDetails = initialDetails;
    _lightTheme = _buildTheme(Brightness.light, initialDetails);
    _darkTheme = _buildTheme(Brightness.dark, initialDetails);
    _loadPreferences();
  }

  ThemeMode _themeMode = ThemeMode.system;
  Mood _activeMood = Mood.calm;
  final Set<Mood> _unlockedMoods = <Mood>{Mood.calm};
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;
  MoodThemeDetails? _moodDetails;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  Mood get activeMood => _activeMood;
  Set<Mood> get unlockedMoods => Set<Mood>.unmodifiable(_unlockedMoods);
  MoodThemeDetails get moodDetails => _moodDetails ?? _resolveDetailsForMood(_activeMood);
  bool get isLoaded => _isLoaded;
  MoodThemeDetails detailsForMood(Mood mood) => _resolveDetailsForMood(mood);

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> applyMoodTheme(Mood mood) async {
    if (_activeMood == mood && _unlockedMoods.contains(mood)) {
      return;
    }
    _activeMood = mood;
    _unlockedMoods.add(mood);
    _refreshThemes();
    await _persistMoodPreferences();
    notifyListeners();
  }

  Future<void> unlockMood(Mood mood) async {
    if (_unlockedMoods.contains(mood)) return;
    _unlockedMoods.add(mood);
    await _persistMoodPreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(kThemeMode);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    final storedMood = prefs.getString(PrefsKeys.moodThemeCurrent);
    if (storedMood != null) {
      _activeMood = Mood.values.firstWhere(
        (mood) => mood.name == storedMood,
        orElse: () => Mood.calm,
      );
    }

    final unlocked = prefs.getStringList(PrefsKeys.moodThemeUnlocks);
    if (unlocked != null && unlocked.isNotEmpty) {
      _unlockedMoods
        ..clear()
        ..addAll(unlocked.map((name) {
          return Mood.values.firstWhere(
            (mood) => mood.name == name,
            orElse: () => Mood.calm,
          );
        }));
    }

    _refreshThemes();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persistMoodPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.moodThemeCurrent, _activeMood.name);
    await prefs.setStringList(
      PrefsKeys.moodThemeUnlocks,
      _unlockedMoods.map((mood) => mood.name).toList(growable: false),
    );
  }

  void _refreshThemes() {
    final details = _resolveDetailsForMood(_activeMood);
    _moodDetails = details;
    _lightTheme = _buildTheme(Brightness.light, details);
    _darkTheme = _buildTheme(Brightness.dark, details);
  }

  ThemeData _buildTheme(Brightness brightness, MoodThemeDetails details) {
    final base = ThemeData(
      brightness: brightness,
      fontFamily: 'Alef',
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: details.primaryColor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(backgroundColor: details.primaryColor),
      chipTheme: base.chipTheme.copyWith(backgroundColor: details.secondaryColor.withOpacity(0.2)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: details.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  MoodThemeDetails _resolveDetailsForMood(Mood mood) {
    final palette = _palettes[mood] ?? _palettes[Mood.calm]!;
    return MoodThemeDetails(
      mood: mood,
      primaryColor: palette.primary,
      secondaryColor: palette.secondary,
      backgroundGradient: LinearGradient(
        colors: palette.gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      backgroundAsset: palette.asset,
      soundAsset: palette.sound,
    );
  }

  static final Map<Mood, _MoodPalette> _palettes = <Mood, _MoodPalette>{
    Mood.happy: const _MoodPalette(
      primary: Color(0xFFFFC107),
      secondary: Color(0xFFFFF59D),
      gradient: [Color(0xFFFFF59D), Color(0xFFFFD54F), Color(0xFFFFA000)],
      asset: 'assets/images/magic_hat.jpg',
      sound: 'sounds/success.mp3',
    ),
    Mood.calm: const _MoodPalette(
      primary: Color(0xFF4FC3F7),
      secondary: Color(0xFFAEDFF7),
      gradient: [Color(0xFFAEDFF7), Color(0xFF81D4FA), Color(0xFF29B6F6)],
      asset: 'assets/images/super_shoes.jpg',
      sound: 'sounds/whistle.mp3',
    ),
    Mood.excited: const _MoodPalette(
      primary: Color(0xFFAB47BC),
      secondary: Color(0xFFCE93D8),
      gradient: [Color(0xFFCE93D8), Color(0xFFAB47BC), Color(0xFF8E24AA)],
      sound: 'sounds/tick.mp3',
    ),
    Mood.angry: const _MoodPalette(
      primary: Color(0xFFE53935),
      secondary: Color(0xFFFF867C),
      gradient: [Color(0xFFFF867C), Color(0xFFEF5350), Color(0xFFD32F2F)],
      sound: 'sounds/failure.mp3',
    ),
    Mood.sad: const _MoodPalette(
      primary: Color(0xFF5C6BC0),
      secondary: Color(0xFF9FA8DA),
      gradient: [Color(0xFF9FA8DA), Color(0xFF7986CB), Color(0xFF3F51B5)],
      sound: 'sounds/whistle.mp3',
    ),
    Mood.anxious: const _MoodPalette(
      primary: Color(0xFF26A69A),
      secondary: Color(0xFF80CBC4),
      gradient: [Color(0xFFB2DFDB), Color(0xFF4DB6AC), Color(0xFF00897B)],
      sound: 'sounds/tick.mp3',
    ),
  };
}