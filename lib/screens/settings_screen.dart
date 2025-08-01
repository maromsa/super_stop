import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  // These keys will be used to save and load the settings
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

  // Load the saved settings from the device's storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool(SettingsScreen.kSoundEnabled) ?? true;
      _hapticsEnabled = prefs.getBool(SettingsScreen.kHapticsEnabled) ?? true;
    });
  }

  // Update the sound setting and save it
  Future<void> _updateSoundSetting(bool value) async {
    setState(() {
      _soundEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsScreen.kSoundEnabled, value);
  }

  // Update the haptics setting and save it
  Future<void> _updateHapticsSetting(bool value) async {
    setState(() {
      _hapticsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsScreen.kHapticsEnabled, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('הגדרות'),
      ),
      body: ListView(
        children: [
          // A tile with a switch for sound effects
          SwitchListTile(
            title: const Text('אפקטים קוליים'),
            secondary: const Icon(Icons.volume_up),
            value: _soundEnabled,
            onChanged: _updateSoundSetting,
          ),
          // A tile with a switch for haptic feedback
          SwitchListTile(
            title: const Text('רטט'),
            secondary: const Icon(Icons.vibration),
            value: _hapticsEnabled,
            onChanged: _updateHapticsSetting,
          ),
        ],
      ),
    );
  }
}