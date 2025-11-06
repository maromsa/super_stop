import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';
import '../models/mood_mix.dart';
import '../utils/prefs_keys.dart';

class MoodMusicMixerProvider with ChangeNotifier {
  MoodMusicMixerProvider({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _hydrate();
  }

  final AudioPlayer _player;
  MoodMixState _state = MoodMixState(
    layers: Mood.values
        .map((mood) => MoodMixLayer(mood: mood, track: 'tick.mp3', volume: 0.4))
        .toList(growable: false),
  );
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  MoodMixState get state => _state;
  List<String> get availableTracks => const <String>['tick.mp3', 'success.mp3', 'whistle.mp3', 'failure.mp3'];

  MoodMixLayer layerForMood(Mood mood) =>
      _state.layers.firstWhere((layer) => layer.mood == mood, orElse: () => MoodMixLayer(mood: mood, track: 'tick.mp3', volume: 0.4));

  Future<void> updateLayer(Mood mood, {String? track, double? volume}) async {
    final updatedLayers = _state.layers.map((layer) {
      if (layer.mood != mood) {
        return layer;
      }
      return layer.copyWith(track: track, volume: volume);
    }).toList(growable: false);
    _state = _state.copyWith(layers: updatedLayers);
    await _persist();
    notifyListeners();
  }

  Future<void> setActiveMood(Mood mood) async {
    if (_state.activeMood == mood) {
      return;
    }
    _state = _state.copyWith(activeMood: mood);
    await _persist();
    notifyListeners();
    await previewMood(mood);
  }

  Future<void> previewMood(Mood mood) async {
    final layer = layerForMood(mood);
    await _player.stop();
    await _player.setVolume(layer.volume.clamp(0, 1).toDouble());
    await _player.play(AssetSource('sounds/${layer.track}'));
    _state = _state.copyWith(lastPreviewedTrack: layer.track);
    await _persist();
    notifyListeners();
  }

  Future<void> stopPreview() async {
    await _player.stop();
    _state = _state.copyWith(clearLastPreview: true);
    await _persist();
    notifyListeners();
  }

  Future<void> disposeMixer() async {
    await _player.dispose();
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _player.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.moodMusicMixerState);
    if (serialized != null && serialized.isNotEmpty) {
      try {
        _state = MoodMixState.decode(serialized);
      } catch (_) {
        // keep defaults
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.moodMusicMixerState, MoodMixState.encode(_state));
  }
}
