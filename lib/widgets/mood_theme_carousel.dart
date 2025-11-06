import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/mood_entry.dart';
import '../theme_provider.dart';

class MoodThemeCarousel extends StatelessWidget {
  const MoodThemeCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final moods = Mood.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.homeMoodSelectorTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            reverse: isRtl,
            itemCount: moods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final mood = moods[index];
              final details = themeProvider.detailsForMood(mood);
              final label = _resolveMoodLabel(mood, l10n);
              final emoji = _resolveMoodEmoji(mood);
              final isUnlocked = themeProvider.unlockedMoods.contains(mood);
              final isActive = themeProvider.activeMood == mood;

              return _MoodCard(
                label: label,
                emoji: emoji,
                colors: details.backgroundGradient.colors,
                isUnlocked: isUnlocked,
                isActive: isActive,
                activeBadgeLabel: l10n.homeMoodActiveBadge,
                onTap: () {
                  if (!isUnlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.homeMoodLockedMessage)),
                    );
                    return;
                  }
                  context.read<ThemeProvider>().applyMoodTheme(mood);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _resolveMoodLabel(Mood mood, AppLocalizations l10n) {
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

  String _resolveMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return '😄';
      case Mood.angry:
        return '😤';
      case Mood.sad:
        return '😢';
      case Mood.anxious:
        return '😬';
      case Mood.calm:
        return '😌';
      case Mood.excited:
        return '🤩';
    }
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.label,
    required this.emoji,
    required this.colors,
    required this.isUnlocked,
    required this.isActive,
    required this.activeBadgeLabel,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final List<Color> colors;
  final bool isUnlocked;
  final bool isActive;
  final String activeBadgeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors
          .map((color) => color.withOpacity(isUnlocked ? 0.85 : 0.55))
          .toList(growable: false),
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      scale: isActive ? 1.05 : 0.96,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isCompact = constraints.maxHeight < 120;
                final double emojiSize = isCompact ? 28 : 34;
                final double labelSize = isCompact ? 14 : 16;
                final double badgeFont = isCompact ? 11 : 12;
                final EdgeInsets padding = EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: isCompact ? 12 : 16,
                );

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  width: 150,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(isActive ? 28 : 24),
                    border: Border.all(
                      color: Colors.white.withOpacity(isActive ? 0.7 : 0.25),
                      width: isActive ? 1.8 : 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withOpacity(isActive ? 0.32 : 0.18),
                        blurRadius: isActive ? 22 : 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: padding,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            emoji,
                            style: TextStyle(fontSize: emojiSize),
                          ),
                          SizedBox(height: isCompact ? 4 : 8),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: labelSize,
                            ),
                          ),
                          SizedBox(height: isCompact ? 2 : 6),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: isActive ? 1 : 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 10,
                                vertical: isCompact ? 2 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    activeBadgeLabel,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: badgeFont,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_outline, color: Colors.white70, size: 30),
                  ),
                ),
              ),
            if (isActive)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.star, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
