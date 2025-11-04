import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:super_stop/l10n/app_localizations.dart';

import '../providers/coin_provider.dart';
import '../providers/daily_goals_provider.dart';
import '../router/app_routes.dart';

class ProgressDashboardScreen extends StatelessWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalsProvider = context.watch<DailyGoalsProvider>();
    final coinProvider = context.watch<CoinProvider>();
    final weeklyGames = goalsProvider.weeklyGames;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progressAppBarTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStreakCard(goalsProvider, l10n),
            const SizedBox(height: 16),
            _buildDailyGoalCard(goalsProvider, l10n),
            const SizedBox(height: 16),
            _buildStatsCard(goalsProvider, coinProvider, l10n),
            const SizedBox(height: 16),
            _buildWeeklyChart(weeklyGames, l10n),
            const SizedBox(height: 16),
            _buildAchievementsPreview(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(DailyGoalsProvider provider, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.local_fire_department, size: 50, color: Colors.orange),
            const SizedBox(height: 10),
            Text(
              '${provider.streak}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(
              l10n.progressStreakSubtitle,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard(DailyGoalsProvider provider, AppLocalizations l10n) {
    final progress = provider.dailyGoal > 0 ? provider.gamesPlayedToday / provider.dailyGoal : 0.0;
    final isCompleted = provider.isGoalCompleted;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.progressDailyGoalTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 30),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 20,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.progressDailyGoalLabel(provider.gamesPlayedToday, provider.dailyGoal),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.progressDailyGoalFocus(provider.focusMinutesToday),
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    DailyGoalsProvider goalsProvider,
    CoinProvider coinProvider,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.monetization_on, '${coinProvider.coins}', l10n.progressStatsCoins),
                _buildStatItem(Icons.games, '${goalsProvider.gamesPlayedToday}', l10n.progressStatsGamesToday),
                _buildStatItem(Icons.timer, '${goalsProvider.focusMinutesToday}', l10n.progressStatsFocusToday),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.calendar_today, '${goalsProvider.totalWeeklyGames}', l10n.progressStatsWeeklyGames),
                _buildStatItem(Icons.self_improvement, '${goalsProvider.totalWeeklyFocusMinutes}', l10n.progressStatsWeeklyFocus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<int> weeklyGames, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.progressWeeklyGamesTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: weeklyGames.isEmpty
                        ? 10
                        : (weeklyGames.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Text(days[index]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                    barGroups: weeklyGames.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.blue,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsPreview(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.progressAchievementsTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.achievements);
              },
              icon: const Icon(Icons.emoji_events),
              label: Text(l10n.progressAchievementsButton),
            ),
          ],
        ),
      ),
    );
  }
}

