import 'package:flutter/material.dart';

import 'package:super_stop/l10n/app_localizations.dart';

import '../models/mood_entry.dart';
import '../utils/mood_utils.dart';

typedef MoodSelectedCallback = void Function(Mood mood);

class MoodSelector extends StatelessWidget {
  const MoodSelector({super.key, required this.onMoodSelected, this.isCompact = false});

  final MoodSelectedCallback onMoodSelected;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final moods = Mood.values;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: moods
          .map((mood) => _MoodChip(mood: mood, onMoodSelected: onMoodSelected, compact: isCompact))
          .toList(),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood, required this.onMoodSelected, required this.compact});

  final Mood mood;
  final MoodSelectedCallback onMoodSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gradient = MoodUtils.gradientOf(mood);
    final l10n = AppLocalizations.of(context)!;
    final label = _labelForMood(l10n);

    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () => onMoodSelected(mood),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: compact ? 140 : 160,
          padding: EdgeInsets.symmetric(vertical: compact ? 12 : 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: gradient.last.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                MoodUtils.emojiOf(mood),
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForMood(AppLocalizations l10n) {
    switch (mood) {
      case Mood.happy:
        return l10n.moodHappy;
      case Mood.angry:
        return l10n.moodAngry;
      case Mood.sad:
        return l10n.moodSad;
      case Mood.anxious:
        return l10n.moodAnxious;
      case Mood.calm:
        return l10n.moodCalm;
      case Mood.excited:
        return l10n.moodExcited;
    }
  }
}
