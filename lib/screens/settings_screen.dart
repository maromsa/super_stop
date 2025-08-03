import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart'; // Import our new ThemeProvider

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  // These keys are for the original settings
  static const String kSoundEnabled = 'sound_enabled';
  static const String kHapticsEnabled = 'haptics_enabled';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool(SettingsScreen.kSoundEnabled) ?? true;
      _hapticsEnabled = prefs.getBool(SettingsScreen.kHapticsEnabled) ?? true;
    });
  }

  Future<void> _updateSoundSetting(bool value) async {
    setState(() {
      _soundEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsScreen.kSoundEnabled, value);
  }

  Future<void> _updateHapticsSetting(bool value) async {
    setState(() {
      _hapticsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsScreen.kHapticsEnabled, value);
  }

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to get and set the current theme
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
      ),
      body: ListView(
        children: [
          // Sound and Haptics settings (no changes here)
          SwitchListTile(
            title: const Text('אפקטים קוליים'),
            secondary: const Icon(Icons.volume_up),
            value: _soundEnabled,
            onChanged: _updateSoundSetting,
          ),
          SwitchListTile(
            title: const Text('רטט'),
            secondary: const Icon(Icons.vibration),
            value: _hapticsEnabled,
            onChanged: _updateHapticsSetting,
          ),

          // --- This is the new section for Theme settings ---
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'ערכת נושא',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('בהיר'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (value) => themeProvider.setThemeMode(value!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('כהה'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (value) => themeProvider.setThemeMode(value!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('ברירת מחדל של המערכת'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (value) => themeProvider.setThemeMode(value!),
          ),
        ],
      ),
    );
  }
}