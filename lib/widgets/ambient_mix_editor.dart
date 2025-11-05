import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ambient_mix_provider.dart';

class AmbientMixEditor extends StatefulWidget {
  const AmbientMixEditor({super.key});

  @override
  State<AmbientMixEditor> createState() => _AmbientMixEditorState();
}

class _AmbientMixEditorState extends State<AmbientMixEditor> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: Consumer<AmbientMixProvider>(
          builder: (context, mixProvider, _) {
            if (!mixProvider.isLoaded) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.library_music, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'התאם מיקס צלילים',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTrackDropdown(
                    context: context,
                    label: 'צליל בזמן ריכוז',
                    value: mixProvider.focusTrack,
                    tracks: mixProvider.availableTracks,
                    onChanged: (value) => mixProvider.updateFocusTrack(value ?? mixProvider.focusTrack),
                  ),
                  const SizedBox(height: 12),
                  _buildTrackDropdown(
                    context: context,
                    label: 'צליל בזמן הפסקה',
                    value: mixProvider.breakTrack,
                    tracks: mixProvider.availableTracks,
                    onChanged: (value) => mixProvider.updateBreakTrack(value ?? mixProvider.breakTrack),
                  ),
                  const SizedBox(height: 12),
                  _buildTrackDropdown(
                    context: context,
                    label: 'צליל בעת סיום',
                    value: mixProvider.completeTrack,
                    tracks: mixProvider.availableTracks,
                    onChanged: (value) => mixProvider.updateCompleteTrack(value ?? mixProvider.completeTrack),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'פריסטים שמורים',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mixProvider.presets.map((preset) {
                      final isSelected = mixProvider.selectedPreset == preset.name;
                      return InputChip(
                        label: Text(preset.name),
                        selected: isSelected,
                        onPressed: () => mixProvider.loadPreset(preset.name),
                        onDeleted: mixProvider.presets.length > 1
                            ? () => mixProvider.deletePreset(preset.name)
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'שם חדש לפריסט',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('בחר שם לפריסט החדש')), 
                        );
                        return;
                      }
                      await mixProvider.savePreset(name);
                      _nameController.clear();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('המיקס נשמר כ-$name')), 
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('שמור פריסט'),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('סגור'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrackDropdown({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> tracks,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: tracks
              .map((track) => DropdownMenuItem<String>(
                    value: track,
                    child: Text(_trackLabel(track)),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  String _trackLabel(String track) {
    switch (track) {
      case 'tick.mp3':
        return 'טיק טק מרגיע';
      case 'success.mp3':
        return 'פעמון הצלחה';
      case 'whistle.mp3':
        return 'שריקה שמחה';
      case 'failure.mp3':
        return 'צפצוף תזכורת';
      default:
        return track.replaceAll('.mp3', '');
    }
  }
}
