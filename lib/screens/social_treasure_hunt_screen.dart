import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/social_treasure.dart';
import '../providers/collectible_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/social_treasure_provider.dart';

class SocialTreasureHuntScreen extends StatefulWidget {
  const SocialTreasureHuntScreen({super.key});

  @override
  State<SocialTreasureHuntScreen> createState() => _SocialTreasureHuntScreenState();
}

class _SocialTreasureHuntScreenState extends State<SocialTreasureHuntScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מצוד חברתי'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SocialTreasureProvider>().ensureDailyHunt(),
          ),
        ],
      ),
      body: Consumer3<SocialTreasureProvider, CoinProvider, CollectibleProvider>(
        builder: (context, provider, coins, collectibles, _) {
          if (!provider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final hunts = provider.hunts;
          if (hunts.isEmpty) {
            return const Center(child: Text('מחכים להרפתקה חדשה...'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hunts.length,
            itemBuilder: (context, index) {
              final hunt = hunts[index];
              return _TreasureCard(
                hunt: hunt,
                onSolve: (clueId) async {
                  final name = _nameController.text.trim().isEmpty
                      ? 'שחקן הבית'
                      : _nameController.text.trim();
                  final updated = await provider.markClueSolved(
                    hunt.id,
                    clueId,
                    name,
                    coinProvider: coins,
                    collectibleProvider: collectibles,
                  );
                  if (!context.mounted) return;
                  final message = updated?.isComplete == true
                      ? 'הצוות פיצח את כל הרמזים!'
                      : 'רמז סומן בשם $name';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'שם חבר/ה שמצטרפים לציד',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

class _TreasureCard extends StatelessWidget {
  const _TreasureCard({required this.hunt, required this.onSolve});

  final TreasureHunt hunt;
  final ValueChanged<String> onSolve;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hunt.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('קוד שיתוף: ${hunt.code}'),
                  ],
                ),
                Chip(
                  label: Text('${hunt.solvedCount}/${hunt.clues.length}'),
                  backgroundColor: hunt.isComplete ? Colors.green.shade100 : Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...hunt.clues.map((clue) {
              final solved = clue.isSolved;
              var contributorName = '';
              for (final contrib in hunt.contributors) {
                if (contrib.clueId == clue.id) {
                  contributorName = contrib.name;
                  break;
                }
              }
              return Card(
                color: solved ? Colors.green.shade50 : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(clue.prompt),
                  subtitle: solved && contributorName.isNotEmpty
                      ? Text('נפתר ע"י $contributorName')
                      : null,
                  trailing: solved
                      ? const Icon(Icons.emoji_events, color: Colors.green)
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => onSolve(clue.id),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
