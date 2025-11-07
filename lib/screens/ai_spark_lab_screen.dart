import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/ai_spark_plan.dart';
import '../providers/ai_spark_lab_provider.dart';

class AiSparkLabScreen extends StatelessWidget {
  const AiSparkLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiLabTitle),
        actions: [
          Consumer<AiSparkLabProvider>(
            builder: (context, provider, _) {
              final isThinking = provider.isGenerating;
              return IconButton(
                onPressed: isThinking ? null : () => provider.regeneratePlan(),
                tooltip: l10n.aiLabRefreshTooltip,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isThinking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.casino),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AiSparkLabProvider>(
        builder: (context, provider, _) {
          final plan = provider.currentPlan;
          if (!provider.hasPlan || plan == null) {
            return _AiLabEmptyState(
              message: l10n.aiLabEmptyState,
              onGenerate: provider.isGenerating ? null : () => provider.regeneratePlan(),
              isGenerating: provider.isGenerating,
              generateLabel: l10n.aiLabGenerateButton,
              loadingLabel: l10n.aiLabLoadingLabel,
            );
          }

          final generatedLabel = TimeOfDay.fromDateTime(plan.generatedAt).format(context);

          return RefreshIndicator(
            onRefresh: () => provider.regeneratePlan(delay: const Duration(milliseconds: 260)),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text(
                  l10n.aiLabSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _EnergyPanel(plan: plan, label: l10n.aiLabEnergyLabel(plan.energyLevelLabel)),
                const SizedBox(height: 20),
                _SparkCardSection(
                  title: l10n.aiLabFocusSection,
                  description: l10n.aiLabFocusDescription,
                  card: plan.focusCard,
                ),
                const SizedBox(height: 16),
                _SparkCardSection(
                  title: l10n.aiLabBreakSection,
                  description: l10n.aiLabBreakDescription,
                  card: plan.breakCard,
                ),
                const SizedBox(height: 16),
                _SparkCardSection(
                  title: l10n.aiLabChallengeSection,
                  description: l10n.aiLabChallengeDescription,
                  card: plan.challengeCard,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.aiLabMissionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...plan.missions.map(
                  (mission) => _MissionTile(mission: mission),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.aiLabGeneratedAt(generatedLabel),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EnergyPanel extends StatelessWidget {
  const _EnergyPanel({required this.plan, required this.label});

  final AiSparkPlan plan;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = plan.energyLevelScore / 100;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${plan.energyLevelScore}/100',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkCardSection extends StatelessWidget {
  const _SparkCardSection({
    required this.title,
    required this.description,
    required this.card,
  });

  final String title;
  final String description;
  final AiSparkCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(description, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        _SparkCardTile(card: card),
      ],
    );
  }
}

class _SparkCardTile extends StatelessWidget {
  const _SparkCardTile({required this.card});

  final AiSparkCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasRoute = card.route != null && card.route!.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.subtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (card.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: card.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (hasRoute) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => Navigator.of(context).pushNamed(card.route!),
                    label: Text(l10n.aiLabGoButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});

  final AiSparkMission mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRoute = mission.route != null && mission.route!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Text(mission.emoji, style: const TextStyle(fontSize: 26)),
        title: Text(
          mission.label,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: mission.rewardHint != null ? Text(mission.rewardHint!) : null,
        trailing: hasRoute ? const Icon(Icons.chevron_right) : null,
        onTap: hasRoute ? () => Navigator.of(context).pushNamed(mission.route!) : null,
      ),
    );
  }
}

class _AiLabEmptyState extends StatelessWidget {
  const _AiLabEmptyState({
    required this.message,
    required this.onGenerate,
    required this.isGenerating,
    required this.generateLabel,
    required this.loadingLabel,
  });

  final String message;
  final VoidCallback? onGenerate;
  final bool isGenerating;
  final String generateLabel;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onGenerate,
              icon: isGenerating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(isGenerating ? loadingLabel : generateLabel),
            ),
          ],
        ),
      ),
    );
  }
}
