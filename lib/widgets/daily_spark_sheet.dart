import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/coin_provider.dart';
import '../router/app_routes.dart';

class DailySparkSheet extends StatefulWidget {
  const DailySparkSheet({super.key, required this.hostContext});

  final BuildContext hostContext;

  @override
  State<DailySparkSheet> createState() => _DailySparkSheetState();
}

class _DailySparkSheetState extends State<DailySparkSheet> {
  late _DailySpark _current;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _current = _nextSpark();
  }

  _DailySpark _nextSpark({_DailySpark? exclude}) {
    if (_sparks.length == 1) {
      return _sparks.first;
    }
    _DailySpark candidate;
    do {
      candidate = _sparks[_random.nextInt(_sparks.length)];
    } while (candidate == exclude);
    return candidate;
  }

  Future<void> _handlePrimaryAction() async {
    final l10n = AppLocalizations.of(context)!;
    final coinProvider = context.read<CoinProvider>();
    final hostMessenger = ScaffoldMessenger.of(widget.hostContext);
    final hostNavigator = Navigator.of(widget.hostContext);

    switch (_current.action) {
      case _SparkAction.coins:
        final reward = _current.coinReward ?? 5;
        coinProvider.addCoins(reward);
        Navigator.of(context).pop();
        hostMessenger.showSnackBar(
          SnackBar(content: Text(l10n.dailySparkCoinMessage(reward))),
        );
        break;
      case _SparkAction.focus:
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 180));
        hostNavigator.pushNamed(AppRoutes.focusTimer);
        break;
      case _SparkAction.breathing:
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 180));
        hostNavigator.pushNamed(AppRoutes.breathing);
        break;
    }
  }

  void _showAnother() {
    setState(() {
      _current = _nextSpark(exclude: _current);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32 + 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dailySparkSheetTitle,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _SparkCard(
                key: ValueKey<String>(_current.id),
                spark: _current,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.bolt),
              onPressed: _handlePrimaryAction,
              label: Text(l10n.dailySparkPrimary),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.casino),
              onPressed: _showAnother,
              label: Text(l10n.dailySparkAnother),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SparkAction { coins, focus, breathing }

class _DailySpark {
  const _DailySpark({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.gradient,
    this.coinReward,
  });

  final String id;
  final IconData icon;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;
  final _SparkAction action;
  final List<Color> gradient;
  final int? coinReward;
}

class _SparkCard extends StatelessWidget {
  const _SparkCard({required this.spark, super.key});

  final _DailySpark spark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: spark.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: spark.gradient.last.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(spark.icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            spark.title(l10n),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spark.body(l10n),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }
}

final List<_DailySpark> _sparks = [
  _DailySpark(
    id: 'move-party',
    icon: Icons.music_note,
    title: (l10n) => l10n.dailySparkMoveTitle,
    body: (l10n) => l10n.dailySparkMoveBody,
    action: _SparkAction.coins,
    coinReward: 5,
    gradient: const [Color(0xFF7C4DFF), Color(0xFF512DA8)],
  ),
  _DailySpark(
    id: 'compliment',
    icon: Icons.favorite_border,
    title: (l10n) => l10n.dailySparkComplimentTitle,
    body: (l10n) => l10n.dailySparkComplimentBody,
    action: _SparkAction.coins,
    coinReward: 4,
    gradient: const [Color(0xFFFF6F91), Color(0xFFFF8E53)],
  ),
  _DailySpark(
    id: 'focus-flash',
    icon: Icons.timer,
    title: (l10n) => l10n.dailySparkFocusTitle,
    body: (l10n) => l10n.dailySparkFocusBody,
    action: _SparkAction.focus,
    gradient: const [Color(0xFF29B6F6), Color(0xFF0288D1)],
  ),
  _DailySpark(
    id: 'breathing-boost',
    icon: Icons.self_improvement,
    title: (l10n) => l10n.dailySparkBreathTitle,
    body: (l10n) => l10n.dailySparkBreathBody,
    action: _SparkAction.breathing,
    gradient: const [Color(0xFF66BB6A), Color(0xFF43A047)],
  ),
];
