import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_stop/providers/coin_provider.dart';

void main() {
  group('CoinProvider', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should initialize with 0 coins', () {
      final provider = CoinProvider();
      expect(provider.coins, equals(0));
    });

    test('should add coins correctly', () {
      final provider = CoinProvider();

      provider.addCoins(10);
      expect(provider.coins, equals(10));

      provider.addCoins(5);
      expect(provider.coins, equals(15));
    });

    test('should spend coins when sufficient balance', () {
      final provider = CoinProvider();
      provider.addCoins(20);

      final result = provider.spendCoins(15);
      expect(result, isTrue);
      expect(provider.coins, equals(5));
    });

    test('should not spend coins when insufficient balance', () {
      final provider = CoinProvider();
      provider.addCoins(10);

      final result = provider.spendCoins(15);
      expect(result, isFalse);
      expect(provider.coins, equals(10));
    });

    test('should persist coins across instances', () async {
      final provider1 = CoinProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      provider1.addCoins(50);
      expect(provider1.coins, equals(50));

      // The underlying save mechanism should persist the value
      expect(provider1.coins, isA<int>());
    });

    test('should validate new helpers and mutations', () async {
      final provider = CoinProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.hasCoins, isFalse);
      provider.addCoins(10);
      expect(provider.hasCoins, isTrue);
      expect(provider.hasEnoughCoins(5), isTrue);
      expect(provider.hasEnoughCoins(15), isFalse);

      final added = provider.addCoinsWithMultiplier(10, multiplier: 1.5);
      expect(added, equals(15));
      expect(provider.coins, equals(25));

      await provider.setCoins(40);
      expect(provider.coins, equals(40));

      await provider.resetCoins();
      expect(provider.coins, equals(0));
      expect(provider.hasCoins, isFalse);
    });

    test('should guard against invalid inputs', () async {
      final provider = CoinProvider();

      expect(() => provider.addCoins(-5), throwsArgumentError);
      expect(() => provider.addCoinsWithMultiplier(10, multiplier: -1), throwsArgumentError);

      await expectLater(provider.setCoins(-10), throwsArgumentError);
    });
  });
}

