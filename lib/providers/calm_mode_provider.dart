import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calm_power_up.dart';
import '../utils/prefs_keys.dart';
import 'coin_provider.dart';
import 'virtual_companion_provider.dart';

class CalmModeProvider with ChangeNotifier {
  CalmModeProvider({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;
  final Random _random = Random();
  final List<CalmPowerUp> _powerUps = <CalmPowerUp>[];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<CalmPowerUp> get activePowerUps =>
      _powerUps.where((powerUp) => powerUp.isActive).toList(growable: false);
  List<CalmPowerUp> get history => List<CalmPowerUp>.unmodifiable(_powerUps);

  Future<CalmPowerUp> registerBreathingMiniGame(
    int completedLoops, {
    CoinProvider? coinProvider,
    VirtualCompanionProvider? companion,
  }) async {
    final value = 2 + (completedLoops ~/ 2);
    final powerUp = CalmPowerUp(
      id: 'calm_${_clock().millisecondsSinceEpoch}_${_random.nextInt(9999)}',
      type: CalmPowerUpType.bonusCoins,
      label: 'בונוס נשימות',
      description: 'מטבעות כפולים למשחק הבא',
      value: value,
      earnedAt: _clock(),
    );
    if (coinProvider != null) {
      coinProvider.addCoins(value);
    }
    _powerUps.add(powerUp);
    if (companion != null) {
      companion.registerCalmCelebration();
    }
    await _persist();
    notifyListeners();
    return powerUp;
  }

  Future<CalmPowerUp> registerRhythmMiniGame({VirtualCompanionProvider? companion}) async {
    final powerUp = CalmPowerUp(
      id: 'rhythm_${_clock().millisecondsSinceEpoch}_${_random.nextInt(9999)}',
      type: CalmPowerUpType.mysteryBoost,
      label: 'קפיצת קצב',
      description: 'מעלה את התקדמות אחת ממשימות המסתורין הבאות.',
      value: 1,
      earnedAt: _clock(),
    );
    _powerUps.add(powerUp);
    if (companion != null) {
      companion.registerCalmCelebration();
    }
    await _persist();
    notifyListeners();
    return powerUp;
  }

  Future<CalmPowerUp?> consumePowerUp(CalmPowerUpType type) async {
    final index = _powerUps.indexWhere((powerUp) => powerUp.type == type && powerUp.isActive);
    if (index == -1) {
      return null;
    }
    final updated = _powerUps[index].markConsumed(_clock());
    _powerUps[index] = updated;
    await _persist();
    notifyListeners();
    return updated;
  }

  Future<void> resetForTesting() async {
    _powerUps.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.calmPowerUpsState);
    if (serialized != null && serialized.isNotEmpty) {
      try {
        _powerUps
          ..clear()
          ..addAll(CalmPowerUp.decodeList(serialized));
      } catch (_) {
        _powerUps.clear();
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.calmPowerUpsState, CalmPowerUp.encodeList(_powerUps));
  }
}
