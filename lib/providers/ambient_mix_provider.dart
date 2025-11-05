import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/prefs_keys.dart';

class AmbientMixPreset {
  const AmbientMixPreset({
    required this.name,
    required this.focusTrack,
    required this.breakTrack,
    required this.completeTrack,
  });

  final String name;
  final String focusTrack;
  final String breakTrack;
  final String completeTrack;

  Map<String, dynamic> toJson() => {
        'name': name,
        'focusTrack': focusTrack,
        'breakTrack': breakTrack,
        'completeTrack': completeTrack,
      };

  factory AmbientMixPreset.fromJson(Map<String, dynamic> json) {
    return AmbientMixPreset(
      name: json['name'] as String,
      focusTrack: json['focusTrack'] as String,
      breakTrack: json['breakTrack'] as String,
      completeTrack: json['completeTrack'] as String,
    );
  }
}

class AmbientMixProvider with ChangeNotifier {
  AmbientMixProvider() {
    _hydrate();
  }

  static const String _defaultFocus = 'tick.mp3';
  static const String _defaultBreak = 'success.mp3';
  static const String _defaultComplete = 'whistle.mp3';

  final List<String> _availableTracks = List<String>.unmodifiable([
    'tick.mp3',
    'success.mp3',
    'whistle.mp3',
    'failure.mp3',
  ]);

  String _focusTrack = _defaultFocus;
  String _breakTrack = _defaultBreak;
  String _completeTrack = _defaultComplete;
  String? _selectedPreset;
  final Map<String, AmbientMixPreset> _presets = <String, AmbientMixPreset>{};
  bool _isLoaded = false;

  List<String> get availableTracks => _availableTracks;
  String get focusTrack => _focusTrack;
  String get breakTrack => _breakTrack;
  String get completeTrack => _completeTrack;
  bool get isLoaded => _isLoaded;
  String? get selectedPreset => _selectedPreset;
  List<AmbientMixPreset> get presets {
    final list = _presets.values.toList(growable: true)
      ..sort((a, b) => a.name.compareTo(b.name));
    return List<AmbientMixPreset>.unmodifiable(list);
  }

  Future<void> updateFocusTrack(String track) async {
    if (!_availableTracks.contains(track) || _focusTrack == track) return;
    _focusTrack = track;
    _selectedPreset = null;
    await _persist();
    notifyListeners();
  }

  Future<void> updateBreakTrack(String track) async {
    if (!_availableTracks.contains(track) || _breakTrack == track) return;
    _breakTrack = track;
    _selectedPreset = null;
    await _persist();
    notifyListeners();
  }

  Future<void> updateCompleteTrack(String track) async {
    if (!_availableTracks.contains(track) || _completeTrack == track) return;
    _completeTrack = track;
    _selectedPreset = null;
    await _persist();
    notifyListeners();
  }

  Future<void> savePreset(String name) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Preset name cannot be empty');
    }
    final preset = AmbientMixPreset(
      name: name.trim(),
      focusTrack: _focusTrack,
      breakTrack: _breakTrack,
      completeTrack: _completeTrack,
    );
    _presets[preset.name] = preset;
    _selectedPreset = preset.name;
    await _persist();
    notifyListeners();
  }

  Future<void> loadPreset(String name) async {
    final preset = _presets[name];
    if (preset == null) return;
    _focusTrack = preset.focusTrack;
    _breakTrack = preset.breakTrack;
    _completeTrack = preset.completeTrack;
    _selectedPreset = preset.name;
    await _persist();
    notifyListeners();
  }

  Future<void> deletePreset(String name) async {
    if (_presets.remove(name) != null) {
      if (_selectedPreset == name) {
        _selectedPreset = null;
      }
      await _persist();
      notifyListeners();
    }
  }

  String resolveTrackForEvent(String event) {
    switch (event) {
      case 'focus':
        return _focusTrack;
      case 'break':
        return _breakTrack;
      case 'complete':
        return _completeTrack;
      default:
        return _defaultFocus;
    }
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _focusTrack = prefs.getString(PrefsKeys.ambientMixFocusTrack) ?? _defaultFocus;
    _breakTrack = prefs.getString(PrefsKeys.ambientMixBreakTrack) ?? _defaultBreak;
    _completeTrack = prefs.getString(PrefsKeys.ambientMixCompleteTrack) ?? _defaultComplete;
    _selectedPreset = prefs.getString(PrefsKeys.ambientMixSelectedPreset);

    final serializedPresets = prefs.getString(PrefsKeys.ambientMixPresets);
    if (serializedPresets != null && serializedPresets.isNotEmpty) {
      try {
        final decoded = jsonDecode(serializedPresets) as List<dynamic>;
        _presets
          ..clear()
          ..addEntries(decoded.map((entry) {
            final preset = AmbientMixPreset.fromJson(entry as Map<String, dynamic>);
            return MapEntry(preset.name, preset);
          }));
      } catch (_) {
        _presets.clear();
      }
    }

    if (_selectedPreset != null && !_presets.containsKey(_selectedPreset)) {
      _selectedPreset = null;
    }

    // Seed a default preset if nothing exists.
    if (_presets.isEmpty) {
      const calmPreset = AmbientMixPreset(
        name: 'Calm Breeze',
        focusTrack: _defaultFocus,
        breakTrack: 'success.mp3',
        completeTrack: 'whistle.mp3',
      );
      _presets[calmPreset.name] = calmPreset;
      _selectedPreset ??= calmPreset.name;
    }

    _selectedPreset ??= _presets.keys.isEmpty ? null : _presets.keys.first;
    if (_selectedPreset != null) {
      final preset = _presets[_selectedPreset!];
      if (preset != null) {
        _focusTrack = preset.focusTrack;
        _breakTrack = preset.breakTrack;
        _completeTrack = preset.completeTrack;
      }
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.ambientMixFocusTrack, _focusTrack);
    await prefs.setString(PrefsKeys.ambientMixBreakTrack, _breakTrack);
    await prefs.setString(PrefsKeys.ambientMixCompleteTrack, _completeTrack);
    if (_selectedPreset != null) {
      await prefs.setString(PrefsKeys.ambientMixSelectedPreset, _selectedPreset!);
    } else {
      await prefs.remove(PrefsKeys.ambientMixSelectedPreset);
    }
    final encodedPresets = jsonEncode(
      _presets.values.map((preset) => preset.toJson()).toList(growable: false),
    );
    await prefs.setString(PrefsKeys.ambientMixPresets, encodedPresets);
  }
}
