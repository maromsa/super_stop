import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mood_entry.dart';
import '../providers/mood_music_mixer_provider.dart';

class MoodMusicMixerScreen extends StatelessWidget {
  const MoodMusicMixerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מערבל מצב רוח ומוזיקה'),
      ),
      body: Consumer<MoodMusicMixerProvider>(
        builder: (context, provider, _) {
          if (!provider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final state = provider.state;
          final activeMood = state.activeMood ?? Mood.calm;
          final layers = state.layers;
          final activeLayer = provider.layerForMood(activeMood);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: Mood.values
                      .map(
                        (mood) => ChoiceChip(
                          label: Text(_resolveMoodLabel(mood)),
                          selected: activeMood == mood,
                          onSelected: (_) => provider.setActiveMood(mood),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'צליל מוביל', border: OutlineInputBorder()),
                  child: DropdownButton<String>(
                    value: activeLayer.track,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: provider.availableTracks
                        .map(
                          (track) => DropdownMenuItem(
                            value: track,
                            child: Text(track.replaceAll('.mp3', '')),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateLayer(activeMood, track: value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text('עוצמה: ${(activeLayer.volume * 100).round()}%'),
                Slider(
                  value: activeLayer.volume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: '${(activeLayer.volume * 100).round()}%',
                  onChanged: (value) => provider.updateLayer(activeMood, volume: value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => provider.previewMood(activeMood),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('השמעה'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: provider.stopPreview,
                      icon: const Icon(Icons.stop),
                      label: const Text('עצור'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: layers.length,
                    itemBuilder: (context, index) {
                      final layer = layers[index];
                      return ListTile(
                        leading: Text(_resolveMoodEmoji(layer.mood), style: const TextStyle(fontSize: 24)),
                        title: Text(_resolveMoodLabel(layer.mood)),
                        subtitle: Text('רצועה: ${layer.track} • עוצמה ${(layer.volume * 100).round()}%'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _resolveMoodLabel(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return 'שמחה';
      case Mood.angry:
        return 'עצבים';
      case Mood.sad:
        return 'עצבות';
      case Mood.anxious:
        return 'דריכות';
      case Mood.calm:
        return 'רוגע';
      case Mood.excited:
        return 'התרגשות';
    }
  }

  String _resolveMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return '😊';
      case Mood.angry:
        return '😠';
      case Mood.sad:
        return '😔';
      case Mood.anxious:
        return '😬';
      case Mood.calm:
        return '😌';
      case Mood.excited:
        return '🤩';
    }
  }
}
