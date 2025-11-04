import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/daily_goals_provider.dart';
import '../providers/coin_provider.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  List<int> _weeklyGames = [];
  List<int> _weeklyFocus = [];

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesList = prefs.getStringList('weekly_games') ?? [];
    final focusList = prefs.getStringList('weekly_focus') ?? [];
    
    setState(() {
      _weeklyGames = gamesList.map((e) => int.tryParse(e) ?? 0).toList();
      _weeklyFocus = focusList.map((e) => int.tryParse(e) ?? 0).toList();
      
      // Ensure we have 7 days of data
      while (_weeklyGames.length < 7) {
        _weeklyGames.insert(0, 0);
      }
      while (_weeklyFocus.length < 7) {
        _weeklyFocus.insert(0, 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalsProvider = Provider.of<DailyGoalsProvider>(context);
    final coinProvider = Provider.of<CoinProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('לוח התקדמות'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStreakCard(goalsProvider),
            const SizedBox(height: 16),
            _buildDailyGoalCard(goalsProvider),
            const SizedBox(height: 16),
            _buildStatsCard(goalsProvider, coinProvider),
            const SizedBox(height: 16),
            _buildWeeklyChart(),
            const SizedBox(height: 16),
            _buildAchievementsPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(DailyGoalsProvider provider) {
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
            const Text(
              'ימים ברצף',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard(DailyGoalsProvider provider) {
    final progress = provider.gamesPlayedToday / provider.dailyGoal;
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
                const Text(
                  'מטרה יומית',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              '${provider.gamesPlayedToday} / ${provider.dailyGoal} משחקים',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.focusMinutesToday} דקות ריכוז היום',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(DailyGoalsProvider goalsProvider, CoinProvider coinProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.monetization_on, '${coinProvider.coins}', 'מטבעות'),
                _buildStatItem(Icons.games, '${goalsProvider.gamesPlayedToday}', 'משחקים היום'),
                _buildStatItem(Icons.timer, '${goalsProvider.focusMinutesToday}', 'דקות ריכוז'),
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

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'משחקים השבוע',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _weeklyGames.isEmpty ? 10 : (_weeklyGames.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble(),
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
                  barGroups: _weeklyGames.asMap().entries.map((entry) {
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

  Widget _buildAchievementsPreview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'הישגים',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to achievements screen - will be handled by parent
              },
              icon: const Icon(Icons.emoji_events),
              label: const Text('צפה בכל ההישגים'),
            ),
          ],
        ),
      ),
    );
  }
}

