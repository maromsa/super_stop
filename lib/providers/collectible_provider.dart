import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collectible.dart';
import '../utils/prefs_keys.dart';

class CollectibleProvider with ChangeNotifier {
  CollectibleProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;
  final Map<String, Collectible> _catalogue = <String, Collectible>{
    for (final collectible in _seedCollectibles()) collectible.id: collectible,
  };
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Collectible> get allCollectibles {
    final list = _catalogue.values.toList(growable: false)
      ..sort((a, b) {
        final rarityCompare = a.rarity.index.compareTo(b.rarity.index);
        if (rarityCompare != 0) {
          return rarityCompare;
        }
        return a.name.compareTo(b.name);
      });
    return list;
  }

  int get unlockedCount => _catalogue.values.where((item) => item.isUnlocked).length;

  Collectible? resolveById(String id) => _catalogue[id];

  Future<bool> unlockCollectible(String id) async {
    final existing = _catalogue[id];
    if (existing == null) {
      return false;
    }
    if (existing.isUnlocked) {
      return false;
    }
    _catalogue[id] = existing.copyWith(unlockedAt: _clock());
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> resetForTesting() async {
    for (final key in _catalogue.keys.toList(growable: false)) {
      final item = _catalogue[key];
      if (item != null) {
        _catalogue[key] = item.copyWith(unlockedAt: null);
      }
    }
    await _persist();
    notifyListeners();
  }

  static List<Collectible> _seedCollectibles() => <Collectible>[
        const Collectible(
          id: 'avatar_spark',
          name: 'אווטאר ניצוצי',
          description: 'לוחם אור שמתעורר כאשר נשמרת משימת ריכוז.',
          icon: '✨',
          rarity: CollectibleRarity.common,
        ),
        const Collectible(
          id: 'cape_of_focus',
          name: 'גלימת הריכוז',
          description: 'פריט קצת מגניב שמגדיל את הבונוס מהפסקות רגועות.',
          icon: '🦸',
          rarity: CollectibleRarity.rare,
        ),
        const Collectible(
          id: 'companion_badge_firefly',
          name: 'אות הגחליליות',
          description: 'תג נוצץ שניתן על שיתוף פעולה בהרפתקה חברתית.',
          icon: '🪄',
          rarity: CollectibleRarity.rare,
        ),
        const Collectible(
          id: 'rhythm_sneakers',
          name: 'נעלי הקצב',
          description: 'אוספות אנרגיה כאשר משלימים מיניגיים רגועים.',
          icon: '🥾',
          rarity: CollectibleRarity.epic,
        ),
        const Collectible(
          id: 'story_quill',
          name: 'נוצה מספרת',
          description: 'פותחת סצנת קומיקס חדשה לרצף המנהגים.',
          icon: '🪶',
          rarity: CollectibleRarity.common,
        ),
        const Collectible(
          id: 'boss_crown',
          name: 'כתר המאסטר',
          description: 'נסכה לאחר הבסת ראש ביצועי משימות.',
          icon: '👑',
          rarity: CollectibleRarity.legendary,
        ),
      ];

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.collectiblesState);
    if (serialized != null && serialized.isNotEmpty) {
      try {
        final decoded = Collectible.decodeList(serialized);
        for (final collectible in decoded) {
          if (_catalogue.containsKey(collectible.id)) {
            _catalogue[collectible.id] = collectible;
          } else {
            _catalogue[collectible.id] = collectible;
          }
        }
      } catch (_) {
        // ignore decoding errors and keep defaults
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = Collectible.encodeList(_catalogue.values);
    await prefs.setString(PrefsKeys.collectiblesState, encoded);
  }
}
