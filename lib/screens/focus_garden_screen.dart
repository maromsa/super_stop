import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/coin_provider.dart';
import '../providers/focus_garden_provider.dart';
import '../utils/focus_garden_strings.dart';

class FocusGardenScreen extends StatefulWidget {
  const FocusGardenScreen({super.key});

  @override
  State<FocusGardenScreen> createState() => _FocusGardenScreenState();
}

class _FocusGardenScreenState extends State<FocusGardenScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.focusGardenTitle),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1D3557),
              Color(0xFF457B9D),
              Color(0xFFA8DADC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Consumer<FocusGardenProvider>(
            builder: (context, garden, _) {
              if (!garden.isLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              final stageId = garden.currentStage.id;
              final stageName = FocusGardenStrings.stageName(l10n, stageId);
              final stageDescription = FocusGardenStrings.stageDescription(l10n, stageId);
              final gradientColors = _stageGradientColors(stageId);
              final progressLabel = garden.stageProgressTarget > 0
                  ? l10n.focusGardenProgressLabel(garden.stageProgressValue, garden.stageProgressTarget)
                  : l10n.focusGardenMaxStageReached;
              final nextGoalText = garden.sunlightToNextStage > 0
                  ? l10n.focusGardenNextGoal(garden.sunlightToNextStage)
                  : l10n.focusGardenMaxStageReached;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.last.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stageEmoji(stageId),
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            stageName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stageDescription,
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: garden.stageProgressTarget == 0 ? 1 : garden.stageProgressRatio.clamp(0.0, 1.0),
                              minHeight: 14,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(_stageAccent(stageId)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            progressLabel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextGoalText,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.wb_sunny_outlined,
                            label: l10n.focusGardenSunlightStat,
                            value: '${garden.growthPoints}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.access_time,
                            label: l10n.focusGardenFocusMinutesStat,
                            value: '${garden.totalFocusMinutes}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.grain,
                            label: l10n.focusGardenDewStat,
                            value: '${garden.dewDrops}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.focusGardenWaterCardTitle,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.focusGardenWaterCardSubtitle(FocusGardenProvider.growthPerDew),
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: garden.canUseDew ? () => _handleWaterAction(context, l10n) : null,
                              icon: const Icon(Icons.auto_awesome),
                              label: Text(l10n.focusGardenWaterButton),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.focusGardenDailyLimitLabel(
                                garden.wateringsToday,
                                FocusGardenProvider.maxDailyWaterings,
                              ),
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.focusGardenCurrentDew(garden.dewDrops),
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.deepPurple.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.focusGardenTipTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tipOfTheDay(l10n),
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleWaterAction(BuildContext context, AppLocalizations l10n) async {
    final garden = context.read<FocusGardenProvider>();
    final update = await garden.applyDewBoost();
    if (!mounted) return;

    if (update.dewSpent == 0 || update.sunlightEarned == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.focusGardenWaterUnavailable)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.focusGardenWaterSuccess(update.sunlightEarned))),
    );

    if (update.stageLeveledUp && update.newStageId != null) {
      final stageName = FocusGardenStrings.stageName(l10n, update.newStageId!);
      if (update.rewardCoins > 0) {
        context.read<CoinProvider>().addCoins(update.rewardCoins);
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.focusGardenStageUnlocked(stageName)),
            content: Text(l10n.focusGardenStageCelebration(update.rewardCoins)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.focusGardenCelebrateOkay),
              ),
            ],
          );
        },
      );
    }
  }

  String _tipOfTheDay(AppLocalizations l10n) {
    final tips = <String>[
      l10n.focusGardenTipFocus,
      l10n.focusGardenTipBreath,
      l10n.focusGardenTipKindness,
    ];
    final index = DateTime.now().day % tips.length;
    return tips[index];
  }

  List<Color> _stageGradientColors(FocusGardenStageId id) {
    switch (id) {
      case FocusGardenStageId.seed:
        return const [Color(0xFF355C7D), Color(0xFF6C5B7B)];
      case FocusGardenStageId.sprout:
        return const [Color(0xFF0BAB64), Color(0xFF3BB78F)];
      case FocusGardenStageId.bloom:
        return const [Color(0xFFFF758C), Color(0xFFFF7EB3)];
      case FocusGardenStageId.tree:
        return const [Color(0xFF11998E), Color(0xFF38EF7D)];
      case FocusGardenStageId.nova:
        return const [Color(0xFF7F00FF), Color(0xFFE100FF)];
    }
  }

  Color _stageAccent(FocusGardenStageId id) {
    switch (id) {
      case FocusGardenStageId.seed:
        return const Color(0xFFB8E986);
      case FocusGardenStageId.sprout:
        return const Color(0xFF9BE15D);
      case FocusGardenStageId.bloom:
        return const Color(0xFFFFB3C1);
      case FocusGardenStageId.tree:
        return const Color(0xFF56AB2F);
      case FocusGardenStageId.nova:
        return const Color(0xFFB993D6);
    }
  }

  String _stageEmoji(FocusGardenStageId id) {
    switch (id) {
      case FocusGardenStageId.seed:
        return '🌱';
      case FocusGardenStageId.sprout:
        return '🌿';
      case FocusGardenStageId.bloom:
        return '🌸';
      case FocusGardenStageId.tree:
        return '🌳';
      case FocusGardenStageId.nova:
        return '🌟';
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

