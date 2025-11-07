import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/prefs_keys.dart';

enum FocusGardenStageId { seed, sprout, bloom, tree, nova }

class FocusGardenStageData {
  const FocusGardenStageData({
    required this.id,
    required this.minGrowth,
    required this.rewardCoins,
  });

  final FocusGardenStageId id;
  final int minGrowth;
  final int rewardCoins;

  static const List<FocusGardenStageData> _stages = [
    FocusGardenStageData(id: FocusGardenStageId.seed, minGrowth: 0, rewardCoins: 0),
    FocusGardenStageData(id: FocusGardenStageId.sprout, minGrowth: 80, rewardCoins: 12),
    FocusGardenStageData(id: FocusGardenStageId.bloom, minGrowth: 180, rewardCoins: 18),
    FocusGardenStageData(id: FocusGardenStageId.tree, minGrowth: 320, rewardCoins: 25),
    FocusGardenStageData(id: FocusGardenStageId.nova, minGrowth: 500, rewardCoins: 40),
  ];

  static FocusGardenStageData resolveByGrowth(int growthPoints) {
    FocusGardenStageData result = _stages.first;
    for (final stage in _stages) {
      if (growthPoints >= stage.minGrowth) {
        result = stage;
      } else {
        break;
      }
    }
    return result;
  }

  FocusGardenStageData? get nextStage {
    final index = _stages.indexWhere((s) => s.id == id);
    if (index == -1 || index + 1 >= _stages.length) {
      return null;
    }
    return _stages[index + 1];
  }

  int progressValue(int growthPoints) {
    if (nextStage == null) {
      return growthPoints - minGrowth;
    }
    return (growthPoints - minGrowth).clamp(0, nextStage!.minGrowth - minGrowth);
  }

  int progressTarget() {
    final next = nextStage;
    if (next == null) {
      return 0;
    }
    return next.minGrowth - minGrowth;
  }

  double progressRatio(int growthPoints) {
    final target = progressTarget();
    if (target <= 0) {
      return 1;
    }
    return progressValue(growthPoints) / target;
  }
}

class FocusGardenState {
  const FocusGardenState({
    required this.growthPoints,
    required this.totalFocusMinutes,
    required this.dewDrops,
    required this.totalBreathingCycles,
    required this.wateringsToday,
    required this.lastDailyResetIso,
    required this.lastWateredIso,
  });

  factory FocusGardenState.initial() {
    return const FocusGardenState(
      growthPoints: 0,
      totalFocusMinutes: 0,
      dewDrops: 0,
      totalBreathingCycles: 0,
      wateringsToday: 0,
      lastDailyResetIso: null,
      lastWateredIso: null,
    );
  }

  final int growthPoints;
  final int totalFocusMinutes;
  final int dewDrops;
  final int totalBreathingCycles;
  final int wateringsToday;
  final String? lastDailyResetIso;
  final String? lastWateredIso;

  DateTime? get lastDailyReset => _parseDateTime(lastDailyResetIso);
  DateTime? get lastWatered => _parseDateTime(lastWateredIso);

  FocusGardenState copyWith({
    int? growthPoints,
    int? totalFocusMinutes,
    int? dewDrops,
    int? totalBreathingCycles,
    int? wateringsToday,
    String? lastDailyResetIso,
    String? lastWateredIso,
  }) {
    return FocusGardenState(
      growthPoints: growthPoints ?? this.growthPoints,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      dewDrops: dewDrops ?? this.dewDrops,
      totalBreathingCycles: totalBreathingCycles ?? this.totalBreathingCycles,
      wateringsToday: wateringsToday ?? this.wateringsToday,
      lastDailyResetIso: lastDailyResetIso ?? this.lastDailyResetIso,
      lastWateredIso: lastWateredIso ?? this.lastWateredIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'growthPoints': growthPoints,
      'totalFocusMinutes': totalFocusMinutes,
      'dewDrops': dewDrops,
      'totalBreathingCycles': totalBreathingCycles,
      'wateringsToday': wateringsToday,
      'lastDailyResetIso': lastDailyResetIso,
      'lastWateredIso': lastWateredIso,
    };
  }

  factory FocusGardenState.fromJson(Map<String, dynamic> json) {
    return FocusGardenState(
      growthPoints: _asInt(json['growthPoints']),
      totalFocusMinutes: _asInt(json['totalFocusMinutes']),
      dewDrops: _asInt(json['dewDrops']),
      totalBreathingCycles: _asInt(json['totalBreathingCycles']),
      wateringsToday: _asInt(json['wateringsToday']),
      lastDailyResetIso: json['lastDailyResetIso'] as String?,
      lastWateredIso: json['lastWateredIso'] as String?,
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static int _asInt(dynamic value, [int defaultValue = 0]) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }
}

class FocusGardenUpdate {
  const FocusGardenUpdate({
    this.sunlightEarned = 0,
    this.dewEarned = 0,
    this.dewSpent = 0,
    this.stageLeveledUp = false,
    this.newStageId,
    this.rewardCoins = 0,
  });

  final int sunlightEarned;
  final int dewEarned;
  final int dewSpent;
  final bool stageLeveledUp;
  final FocusGardenStageId? newStageId;
  final int rewardCoins;

  bool get hasChanges =>
      sunlightEarned > 0 || dewEarned > 0 || dewSpent > 0 || stageLeveledUp;
}

class FocusGardenProvider with ChangeNotifier {
  FocusGardenProvider() {
    _loadCompleter = Completer<void>();
    _loadState();
  }

  static const int sunlightPerFocusMinute = 5;
  static const int growthPerDew = 30;
  static const int breathingCyclesPerDew = 3;
  static const int dewPerReward = 1;
  static const int maxDailyWaterings = 3;

  FocusGardenState _state = FocusGardenState.initial();
  bool _isLoaded = false;
  Completer<void>? _loadCompleter;

  bool get isLoaded => _isLoaded;
  int get growthPoints => _state.growthPoints;
  int get dewDrops => _state.dewDrops;
  int get totalFocusMinutes => _state.totalFocusMinutes;
  int get totalBreathingCycles => _state.totalBreathingCycles;
  int get wateringsToday => _state.wateringsToday;
  DateTime? get lastWatered => _state.lastWatered;

  FocusGardenStageData get currentStage =>
      FocusGardenStageData.resolveByGrowth(_state.growthPoints);

  FocusGardenStageData? get nextStage => currentStage.nextStage;

  double get stageProgressRatio =>
      currentStage.progressRatio(_state.growthPoints).clamp(0.0, 1.0);

  int get stageProgressValue => currentStage.progressValue(_state.growthPoints);

  int get stageProgressTarget => currentStage.progressTarget();

  bool get canUseDew =>
      dewDrops > 0 && wateringsToday < FocusGardenProvider.maxDailyWaterings;

  int get sunlightToNextStage {
    final next = nextStage;
    if (next == null) {
      return 0;
    }
    return (next.minGrowth - _state.growthPoints).clamp(0, 1 << 31);
  }

  Future<FocusGardenUpdate> registerFocusSession(int minutes) async {
    if (minutes <= 0) {
      return const FocusGardenUpdate();
    }
    await _ensureInitialized();
    await _ensureDailyReset();

    final stageBefore = currentStage;
    final growthEarned = minutes * sunlightPerFocusMinute;

    _state = _state.copyWith(
      growthPoints: _state.growthPoints + growthEarned,
      totalFocusMinutes: _state.totalFocusMinutes + minutes,
    );

    final stageAfter = currentStage;
    final leveledUp = stageAfter.id != stageBefore.id;
    final update = FocusGardenUpdate(
      sunlightEarned: growthEarned,
      stageLeveledUp: leveledUp,
      newStageId: leveledUp ? stageAfter.id : null,
      rewardCoins: leveledUp ? stageAfter.rewardCoins : 0,
    );

    await _saveState();
    notifyListeners();
    return update;
  }

  Future<FocusGardenUpdate> registerBreathingPractice({int cycles = 1}) async {
    if (cycles <= 0) {
      return const FocusGardenUpdate();
    }
    await _ensureInitialized();

    final totalCycles = _state.totalBreathingCycles + cycles;
    final previousRewardUnits =
        _state.totalBreathingCycles ~/ breathingCyclesPerDew;
    final newRewardUnits = totalCycles ~/ breathingCyclesPerDew;
    final dewEarned = (newRewardUnits - previousRewardUnits) * dewPerReward;

    _state = _state.copyWith(
      totalBreathingCycles: totalCycles,
      dewDrops: _state.dewDrops + dewEarned,
    );

    final update = FocusGardenUpdate(dewEarned: dewEarned);
    await _saveState();
    notifyListeners();
    return update;
  }

  Future<FocusGardenUpdate> applyDewBoost({int dewToSpend = 1}) async {
    if (dewToSpend <= 0) {
      return const FocusGardenUpdate();
    }
    await _ensureInitialized();
    await _ensureDailyReset();

    if (_state.dewDrops < dewToSpend) {
      return const FocusGardenUpdate();
    }
    if (_state.wateringsToday >= FocusGardenProvider.maxDailyWaterings) {
      return const FocusGardenUpdate();
    }

    final stageBefore = currentStage;
    final growthEarned = dewToSpend * growthPerDew;

    _state = _state.copyWith(
      dewDrops: _state.dewDrops - dewToSpend,
      growthPoints: _state.growthPoints + growthEarned,
      wateringsToday: _state.wateringsToday + 1,
      lastWateredIso: DateTime.now().toIso8601String(),
    );

    final stageAfter = currentStage;
    final leveledUp = stageAfter.id != stageBefore.id;

    final update = FocusGardenUpdate(
      dewSpent: dewToSpend,
      sunlightEarned: growthEarned,
      stageLeveledUp: leveledUp,
      newStageId: leveledUp ? stageAfter.id : null,
      rewardCoins: leveledUp ? stageAfter.rewardCoins : 0,
    );

    await _saveState();
    notifyListeners();
    return update;
  }

  Future<void> resetForTesting() async {
    _state = FocusGardenState.initial();
    await _saveState();
    notifyListeners();
  }

  Future<void> _loadState() async {
    FocusGardenState loaded = FocusGardenState.initial();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(PrefsKeys.focusGardenState);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        loaded = FocusGardenState.fromJson(decoded);
      }
    } catch (error, stackTrace) {
      debugPrint('FocusGardenProvider: failed to load state: $error\n$stackTrace');
    }
    _state = loaded;
    await _ensureDailyReset();
    _isLoaded = true;
    _loadCompleter?.complete();
    notifyListeners();
  }

  Future<void> _ensureInitialized() async {
    if (_isLoaded) {
      return;
    }
    await (_loadCompleter?.future ?? _loadState());
  }

  Future<void> _ensureDailyReset() async {
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final lastReset = _state.lastDailyReset;
    if (lastReset != null &&
        lastReset.year == todayKey.year &&
        lastReset.month == todayKey.month &&
        lastReset.day == todayKey.day) {
      return;
    }

    _state = _state.copyWith(
      wateringsToday: 0,
      lastDailyResetIso: todayKey.toIso8601String(),
    );
    await _saveState();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PrefsKeys.focusGardenState,
        jsonEncode(_state.toJson()),
      );
    } catch (error, stackTrace) {
      debugPrint('FocusGardenProvider: failed to save state: $error\n$stackTrace');
    }
  }
}

