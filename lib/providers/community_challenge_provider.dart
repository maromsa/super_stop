import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/coin_provider.dart';
import '../utils/prefs_keys.dart';

class CommunityChallenge {
  CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.rewardCoins,
    int? progress,
    int? personalContribution,
    bool? claimed,
    this.boostCost = 5,
    int? baseline,
  })  : progress = progress ?? (baseline ?? 0),
        personalContribution = personalContribution ?? 0,
        claimed = claimed ?? false;

  final String id;
  final String title;
  final String description;
  final int target;
  final int rewardCoins;
  final int boostCost;
  int progress;
  int personalContribution;
  bool claimed;

  double get completion => (progress / target).clamp(0.0, 1.0);
  bool get isCompleted => progress >= target;
  bool get rewardAvailable => isCompleted && !claimed;

  void addProgress(int amount) {
    if (amount <= 0) return;
    progress += amount;
  }

  void addPersonalContribution(int amount) {
    if (amount <= 0) return;
    personalContribution += amount;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'target': target,
        'progress': progress,
        'rewardCoins': rewardCoins,
        'boostCost': boostCost,
        'personalContribution': personalContribution,
        'claimed': claimed,
      };

  factory CommunityChallenge.fromJson(Map<String, dynamic> json) {
    return CommunityChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      target: json['target'] as int,
      rewardCoins: json['rewardCoins'] as int,
      progress: json['progress'] as int? ?? 0,
      personalContribution: json['personalContribution'] as int? ?? 0,
      claimed: json['claimed'] as bool? ?? false,
      boostCost: json['boostCost'] as int? ?? 5,
    );
  }
}

class CommunityChallengeProvider with ChangeNotifier {
  CommunityChallengeProvider({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _hydrate();
  }

  final DateTime Function() _clock;

  final Map<String, CommunityChallenge> _challenges = <String, CommunityChallenge>{};
  bool _isLoaded = false;
  DateTime? _lastPassiveTick;

  List<CommunityChallenge> get challenges => _challenges.values.toList(growable: false)
    ..sort((a, b) => a.title.compareTo(b.title));
  bool get isLoaded => _isLoaded;

  CommunityChallenge? getChallenge(String id) => _challenges[id];

  void registerGameContribution({int games = 1}) {
    _ensureSeeded();
    final challenge = _challenges['challenge_arcade'];
    if (challenge == null) return;
    challenge.addProgress(games * 5);
    challenge.addPersonalContribution(games);
    _persist();
    notifyListeners();
  }

  void registerFocusContribution({required int minutes}) {
    _ensureSeeded();
    final challenge = _challenges['challenge_focus'];
    if (challenge == null) return;
    challenge.addProgress(minutes * 3 ~/ 2);
    challenge.addPersonalContribution(minutes);
    _persist();
    notifyListeners();
  }

  void registerMoodContribution() {
    _ensureSeeded();
    final challenge = _challenges['challenge_mood'];
    if (challenge == null) return;
    challenge.addProgress(7);
    challenge.addPersonalContribution(1);
    _persist();
    notifyListeners();
  }

  bool contributeCoins(String challengeId, CoinProvider coinProvider, {int coins = 5}) {
    _ensureSeeded();
    final challenge = _challenges[challengeId];
    if (challenge == null || coins <= 0) {
      return false;
    }
    if (!coinProvider.spendCoins(coins)) {
      return false;
    }
    final contribution = coins * 10;
    challenge.addProgress(contribution);
    challenge.addPersonalContribution(contribution);
    _persist();
    notifyListeners();
    return true;
  }

  bool claimReward(String challengeId, CoinProvider coinProvider) {
    final challenge = _challenges[challengeId];
    if (challenge == null || !challenge.rewardAvailable) {
      return false;
    }
    coinProvider.addCoins(challenge.rewardCoins);
    challenge.claimed = true;
    _persist();
    notifyListeners();
    return true;
  }

  void tickPassiveProgress() {
    _ensureSeeded();
    final now = _clock();
    if (_lastPassiveTick != null && now.difference(_lastPassiveTick!).inHours < 2) {
      return;
    }
    _lastPassiveTick = now;
    for (final entry in _challenges.entries) {
      final challenge = entry.value;
      final passive = max(1, challenge.target ~/ 200);
      challenge.addProgress(passive);
    }
    _persist();
    notifyListeners();
  }

  void resetForTesting() {
    _challenges.clear();
    _isLoaded = false;
    _persist();
  }

  void _ensureSeeded() {
    if (_challenges.isNotEmpty) return;
    final now = _clock();
    final baselineFactor = (now.day % 5) + 3;
    _challenges['challenge_arcade'] = CommunityChallenge(
      id: 'challenge_arcade',
      title: 'Arcade Alliance',
      description: 'Collectively play 500 mini rounds to unlock rainbow game skins.',
      target: 500,
      rewardCoins: 25,
      boostCost: 5,
      baseline: 120 * baselineFactor,
    );
    _challenges['challenge_focus'] = CommunityChallenge(
      id: 'challenge_focus',
      title: 'Focus Wave',
      description: 'Stack 1500 focus minutes as a community to unlock deep focus visuals.',
      target: 1500,
      rewardCoins: 30,
      boostCost: 8,
      baseline: 280 * baselineFactor,
    );
    _challenges['challenge_mood'] = CommunityChallenge(
      id: 'challenge_mood',
      title: 'Mood Mosaic',
      description: 'Share 250 mood reflections to unlock the aurora theme.',
      target: 250,
      rewardCoins: 20,
      boostCost: 6,
      baseline: 60 * baselineFactor,
    );
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getString(PrefsKeys.communityChallengeState);
    if (serialized != null && serialized.isNotEmpty) {
      try {
        final decoded = jsonDecode(serialized) as List<dynamic>;
        for (final entry in decoded) {
          final challenge = CommunityChallenge.fromJson(entry as Map<String, dynamic>);
          _challenges[challenge.id] = challenge;
        }
      } catch (_) {
        _challenges.clear();
      }
    }

    _ensureSeeded();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _challenges.values.map((challenge) => challenge.toJson()).toList(growable: false),
    );
    await prefs.setString(PrefsKeys.communityChallengeState, encoded);
  }
}
