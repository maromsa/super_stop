import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/social_treasure.dart';
import '../utils/prefs_keys.dart';
import 'collectible_provider.dart';
import 'coin_provider.dart';

class SocialTreasureProvider with ChangeNotifier {
  SocialTreasureProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;
  final Random _random = Random();
  List<TreasureHunt> _hunts = <TreasureHunt>[];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<TreasureHunt> get hunts => List<TreasureHunt>.unmodifiable(_hunts);

  TreasureHunt? resolveById(String id) {
    for (final hunt in _hunts) {
      if (hunt.id == id) {
        return hunt;
      }
    }
    return null;
  }

  Future<TreasureHunt> ensureDailyHunt() async {
    final todayKey = _buildTodayId();
    for (final hunt in _hunts) {
      if (hunt.id == todayKey) {
        return hunt;
      }
    }
    final newHunt = _generateHunt(todayKey);
    _hunts = <TreasureHunt>[newHunt, ..._hunts];
    await _persist();
    notifyListeners();
    return newHunt;
  }

  Future<TreasureHunt?> joinWithCode(String code) async {
    for (final hunt in _hunts) {
      if (hunt.code == code) {
        return hunt;
      }
    }
    return null;
  }

  Future<TreasureHunt?> markClueSolved(
    String huntId,
    String clueId,
    String contributorName, {
    CoinProvider? coinProvider,
    CollectibleProvider? collectibleProvider,
  }) async {
    final index = _hunts.indexWhere((hunt) => hunt.id == huntId);
    if (index == -1) {
      return null;
    }
    final contributor = TreasureContributor(
      name: contributorName,
      clueId: clueId,
      completedAt: _clock(),
    );
    final updated = _hunts[index].markClueSolved(clueId, contributor);
    _hunts[index] = updated;
    if (updated.isComplete) {
      coinProvider?.addCoins(12);
      if (collectibleProvider != null) {
        await collectibleProvider.unlockCollectible('companion_badge_firefly');
      }
    }
    await _persist();
    notifyListeners();
    return updated;
  }

  Future<void> resetForTesting() async {
    _hunts = <TreasureHunt>[];
    await _persist();
    notifyListeners();
  }

  String _buildTodayId() {
    final today = _clock();
    return 'treasure_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
  }

  TreasureHunt _generateHunt(String id) {
    final themes = <String>['מחנה הקשב', 'גחליליות הפוקוס', 'מעבדת העלים', 'מגדל הגיבורים'];
    final prompts = <String>[
      'מצאו בבית שלוש חפצים בצבעים שונים וציירו מהם סמל צוות.',
      'כתבו ביחד צמד חרוזים שמעודד מישהו להתמיד.',
      'אספו שלוש פעולות קטנות שיכולות לעזור למישהו להירגע.',
      'בנו לוח משימות קטן וצלמו אותו כדי להזמין חבר להצטרף.',
    ];
    final themeIndex = _random.nextInt(themes.length);
    final clueCount = 3;
    final clues = List<TreasureClue>.generate(clueCount, (index) {
      final promptIndex = (themeIndex + index) % prompts.length;
      return TreasureClue(
        id: '$id-$index',
        prompt: prompts[promptIndex],
      );
    });
    final joinCode = '${_random.nextInt(9999).toString().padLeft(4, '0')}';
    return TreasureHunt(
      id: id,
      title: 'מרדף ${themes[themeIndex]}',
      theme: themes[themeIndex],
      clues: clues,
      code: joinCode,
    );
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.socialTreasureState);
    if (serialized != null && serialized.isNotEmpty) {
      try {
        _hunts = TreasureHunt.decodeList(serialized);
      } catch (_) {
        _hunts = <TreasureHunt>[];
      }
    }
    await ensureDailyHunt();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.socialTreasureState, TreasureHunt.encodeList(_hunts));
  }
}
