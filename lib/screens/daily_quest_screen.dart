import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/daily_quest.dart';
import '../providers/collectible_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_quest_provider.dart';

class DailyQuestScreen extends StatelessWidget {
  const DailyQuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('משימות יומיות'),
        centerTitle: true,
      ),
      body: Consumer3<DailyQuestProvider, CollectibleProvider, CoinProvider>(
        builder: (context, questsProvider, collectibles, coins, _) {
          if (!questsProvider.isLoaded || !collectibles.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final quests = questsProvider.quests;
          if (quests.isEmpty) {
            return const Center(child: Text('המשימות נטענות...'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: quests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final quest = quests[index];
                return _DailyQuestCard(
                  quest: quest,
                  collectibles: collectibles,
                  onCompleteCreative: () async {
                    final updated = await questsProvider.registerCreativeProgress(
                      quest.id,
                      coinProvider: coins,
                      collectibleProvider: collectibles,
                    );
                    if (context.mounted) {
                      final message = updated.isNotEmpty
                          ? 'כל הכבוד! השלמת את המשימה ופתחת פרס.'
                          : 'התקדמות נרשמה.';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard({
    required this.quest,
    required this.collectibles,
    this.onCompleteCreative,
  });

  final DailyQuest quest;
  final CollectibleProvider collectibles;
  final VoidCallback? onCompleteCreative;

  @override
  Widget build(BuildContext context) {
    final rewardCollectible = quest.rewardCollectibleId != null
        ? collectibles.resolveById(quest.rewardCollectibleId!)
        : null;
    final progress = quest.goal == 0 ? 1.0 : quest.progress / quest.goal;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  quest.isCreative ? Icons.palette : Icons.sports_esports,
                  color: quest.isCreative ? Colors.pinkAccent : Colors.blueAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quest.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (quest.isCompleted)
                  Chip(
                    label: Text(quest.isCreative ? 'יצירתי הושלם' : 'הושלם'),
                    backgroundColor: Colors.green.shade100,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(quest.description),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${quest.progress}/${quest.goal}'),
                if (quest.coinReward > 0)
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                      Text(' +${quest.coinReward}')
                    ],
                  ),
              ],
            ),
            if (rewardCollectible != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    rewardCollectible.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${rewardCollectible.name} • ${rewardCollectible.description}',
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            ],
            if (quest.isCreative && !quest.isCompleted) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onCompleteCreative,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('סימנתי את המשימה'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
