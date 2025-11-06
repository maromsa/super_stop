import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/boss_battle.dart';
import '../providers/boss_battle_provider.dart';
import '../providers/collectible_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_quest_provider.dart';

class ExecutiveBossBattleScreen extends StatefulWidget {
  const ExecutiveBossBattleScreen({super.key});

  @override
  State<ExecutiveBossBattleScreen> createState() => _ExecutiveBossBattleScreenState();
}

class _ExecutiveBossBattleScreenState extends State<ExecutiveBossBattleScreen> {
  final Map<String, List<int?>> _answers = <String, List<int?>>{};
  final Map<String, bool> _expanded = <String, bool>{};
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('בוסי הפונקציות הניהוליות'),
      ),
      body: Consumer3<BossBattleProvider, CoinProvider, CollectibleProvider>(
        builder: (context, provider, coins, collectibles, _) {
          if (!provider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final battles = provider.battles;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: battles.length,
            itemBuilder: (context, index) {
              final battle = battles[index];
              _answers.putIfAbsent(battle.id, () => List<int?>.filled(battle.tasks.length, null));
              final isExpanded = _expanded[battle.id] ?? false;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ExpansionTile(
                  key: PageStorageKey(battle.id),
                  title: Text(battle.name),
                  subtitle: Text('תחום: ${_resolveDomainLabel(battle.domain)} • מומלץ מרמה ${battle.recommendedLevel}'),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (value) => setState(() => _expanded[battle.id] = value),
                  children: [
                    ...battle.tasks.asMap().entries.map(
                      (entry) {
                        final taskIndex = entry.key;
                        final task = entry.value;
                        final selected = _answers[battle.id]?[taskIndex];
                        return ListTile(
                          title: Text(task.prompt),
                          subtitle: Column(
                            children: task.choices
                                .asMap()
                                .entries
                                .map(
                                  (choiceEntry) => RadioListTile<int>(
                                    value: choiceEntry.key,
                                    groupValue: selected,
                                    onChanged: battle.completed
                                        ? null
                                        : (value) => setState(() {
                                              _answers[battle.id]?[taskIndex] = value;
                                            }),
                                    title: Text(choiceEntry.value),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: FilledButton.icon(
                        onPressed: battle.completed || _submitting
                            ? null
                            : () => _submitBattle(context, battle, coins, collectibles, provider),
                        icon: const Icon(Icons.bolt),
                        label: Text(battle.completed ? 'הבוס הובס!' : 'צא לקרב'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submitBattle(
    BuildContext context,
    BossBattle battle,
    CoinProvider coins,
    CollectibleProvider collectibles,
    BossBattleProvider provider,
  ) async {
    final responses = _answers[battle.id];
    if (responses == null || responses.any((answer) => answer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('בחרו תשובה לכל שלב לפני הקרב.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await provider.attemptBattle(
      battle.id,
      responses.cast<int>(),
      coinProvider: coins,
      collectibleProvider: collectibles,
      dailyQuestProvider: context.read<DailyQuestProvider>(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    final message = result.completed
        ? 'ניצחתם את ${battle.name}! כל הכבוד!'
        : 'עניתם נכון על ${result.correctAnswers}/${result.totalTasks} משימות.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolveDomainLabel(BossBattleDomain domain) {
    switch (domain) {
      case BossBattleDomain.planning:
        return 'תכנון';
      case BossBattleDomain.workingMemory:
        return 'זיכרון עבודה';
      case BossBattleDomain.sequencing:
        return 'רצף צעדים';
    }
  }
}
