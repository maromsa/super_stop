import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:super_stop/l10n/app_localizations.dart';

import '../models/mood_entry.dart';
import '../providers/mood_journal_provider.dart';
import '../widgets/mood_selector.dart';

class MoodCheckInScreen extends StatelessWidget {
  const MoodCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moodCheckInTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<MoodJournalProvider>(
          builder: (context, journal, _) {
            final latest = journal.latestEntry;
            final distribution = journal.recentMoodDistribution();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.moodCheckInPrompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  MoodSelector(
                    onMoodSelected: (Mood mood) async {
                      await journal.recordMood(mood);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.moodCheckInThanks)),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  if (latest != null) ...[
                    _MoodSummaryCard(entry: latest, l10n: l10n),
                    const SizedBox(height: 24),
                  ],
                  _MoodDistribution(distribution: distribution, l10n: l10n),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MoodSummaryCard extends StatelessWidget {
  const _MoodSummaryCard({required this.entry, required this.l10n});

  final MoodEntry entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = TimeOfDay.fromDateTime(entry.timestamp);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.moodCheckInLastTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _emojiFor(entry.mood),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_labelFor(entry.mood, l10n), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        l10n.moodCheckInLastTime(timestamp.format(context)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodDistribution extends StatelessWidget {
  const _MoodDistribution({required this.distribution, required this.l10n});

  final Map<Mood, int> distribution;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = distribution.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (items.isEmpty) {
      return Text(
        l10n.moodDistributionEmpty,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.moodDistributionTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(_emojiFor(entry.key), style: theme.textTheme.titleLarge),
                const SizedBox(width: 12),
                Expanded(child: Text(_labelFor(entry.key, l10n))),
                const SizedBox(width: 12),
                Text('${entry.value}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _emojiFor(Mood mood) {
  switch (mood) {
    case Mood.happy:
      return '😄';
    case Mood.angry:
      return '😡';
    case Mood.sad:
      return '😢';
    case Mood.anxious:
      return '😰';
    case Mood.calm:
      return '😌';
    case Mood.excited:
      return '🤩';
  }
}

String _labelFor(Mood mood, AppLocalizations l10n) {
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
