import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'connect_four_tutorial.dart';

/// Difficulty curve for the 365-level campaign.
///
/// Strength scales on two axes: how often the AI plays a completely random
/// column (blunders) and how deep it searches when it does think. Early
/// levels blunder most of the time at depth 1; level 365 never blunders and
/// searches 7 plies.
abstract final class ConnectFourLevels {
  static const int maxLevel = 365;

  /// Negamax depth: 1 at level 1 rising in steps to 7 at level 365.
  static int depthFor(int level) {
    final t = (level - 1) / (maxLevel - 1);
    return 1 + (t * 6).floor();
  }

  /// Chance per move that the AI ignores strategy and plays randomly.
  /// 0.85 at level 1, fading to 0 at level 300 and above.
  static double randomnessFor(int level) {
    if (level >= 300) return 0;
    final t = (level - 1) / 299;
    return 0.85 * pow(1 - t, 1.2).toDouble();
  }

  static const _tiers = [
    (1, 'Rookie'),
    (50, 'Easy'),
    (100, 'Casual'),
    (150, 'Clever'),
    (200, 'Skilled'),
    (250, 'Expert'),
    (300, 'Master'),
    (350, 'Grandmaster'),
  ];

  /// Tier bands with inclusive level ranges, in ascending order.
  static final List<({int start, int end, String name})> tiers = [
    for (var i = 0; i < _tiers.length; i++)
      (
        start: _tiers[i].$1,
        end: i + 1 < _tiers.length ? _tiers[i + 1].$1 - 1 : maxLevel,
        name: _tiers[i].$2,
      ),
  ];

  static String tierName(int level) {
    if (ConnectFourTutorial.isTutorialLevel(level)) return 'Tutorial';
    var name = _tiers.first.$2;
    for (final (start, tier) in _tiers) {
      if (level >= start) name = tier;
    }
    return name;
  }
}

/// Campaign progress saved on-device. Level N is playable when every level
/// below it has been beaten; beating level N unlocks N + 1.
abstract final class ConnectFourProgress {
  static const _unlockedKey = 'connect_four_highest_unlocked';

  static Future<int> highestUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_unlockedKey) ?? 1;
    return value.clamp(1, ConnectFourLevels.maxLevel);
  }

  static Future<void> completeLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_unlockedKey) ?? 1;
    final next = min(level + 1, ConnectFourLevels.maxLevel);
    if (next > current) {
      await prefs.setInt(_unlockedKey, next);
    }
  }
}
