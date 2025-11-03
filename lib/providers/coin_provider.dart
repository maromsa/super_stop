// lib/providers/coin_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinProvider with ChangeNotifier {
  static const String _kCoinsKey = 'player_coins';
  int _coins = 0;

  int get coins => _coins;

  CoinProvider() {
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(_kCoinsKey) ?? 0;
    notifyListeners();
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCoinsKey, _coins);
  }

  void addCoins(int amount) {
    _coins += amount;
    _saveCoins();
    notifyListeners();
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
}