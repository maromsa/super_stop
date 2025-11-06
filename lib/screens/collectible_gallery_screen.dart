import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/collectible.dart';
import '../providers/collectible_provider.dart';

class CollectibleGalleryScreen extends StatelessWidget {
  const CollectibleGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('אוסף הפרסים'),
      ),
      body: Consumer<CollectibleProvider>(
        builder: (context, provider, _) {
          if (!provider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final collectibles = provider.allCollectibles;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 4 / 5,
            ),
            itemCount: collectibles.length,
            itemBuilder: (context, index) {
              final item = collectibles[index];
              return _CollectibleCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class _CollectibleCard extends StatelessWidget {
  const _CollectibleCard({required this.item});

  final Collectible item;

  Color _rarityColor(CollectibleRarity rarity) {
    switch (rarity) {
      case CollectibleRarity.common:
        return Colors.blueGrey.shade100;
      case CollectibleRarity.rare:
        return Colors.lightBlueAccent.shade100;
      case CollectibleRarity.epic:
        return Colors.purpleAccent.shade100;
      case CollectibleRarity.legendary:
        return Colors.amber.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = item.isUnlocked;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: unlocked ? _rarityColor(item.rarity) : Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unlocked ? item.icon : '❓',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              unlocked ? item.description : 'פתחו משימות יומיות ואתגרי בוס כדי לחשוף פריט.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                unlocked ? 'נפתח!' : 'נעול',
                style: TextStyle(color: unlocked ? Colors.black87 : Colors.black54),
              ),
              backgroundColor: unlocked ? Colors.white : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
