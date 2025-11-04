// lib/providers/coin_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/prefs_keys.dart';

class CoinProvider with ChangeNotifier {
  int _coins = 0;

  int get coins => _coins;
  bool get hasCoins => _coins > 0;

  CoinProvider() {
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(PrefsKeys.playerCoins) ?? 0;
    notifyListeners();
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefsKeys.playerCoins, _coins);
  }

  void addCoins(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Cannot add a negative amount of coins.');
    }
    _coins += amount;
    _saveCoins();
    notifyListeners();
  }

  int addCoinsWithMultiplier(int baseAmount, {double multiplier = 1.0}) {
    if (multiplier < 0) {
      throw ArgumentError.value(multiplier, 'multiplier', 'Multiplier must be positive.');
    }
    final coinsToAdd = (baseAmount * multiplier).round();
    addCoins(coinsToAdd);
    return coinsToAdd;
  }

  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      _saveCoins();
      notifyListeners();
      return true; // Purchase successful
    }
    return false; // Not enough coins
  }

  bool hasEnoughCoins(int amount) {
    if (amount < 0) return true;
    return _coins >= amount;
  }

  Future<void> setCoins(int amount) async {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Coins cannot be negative.');
    }
    _coins = amount;
    await _saveCoins();
    notifyListeners();
  }

  Future<void> resetCoins() async {
    _coins = 0;
    await _saveCoins();
    notifyListeners();
  }
}