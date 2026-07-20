import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'sudoku_shape.dart';
import 'sudoku_tutorial.dart';

/// Difficulty curve for the 365-level campaign.
///
/// Boards grow over the campaign: 4×4 → 6×6 → 9×9. Within each band,
/// given-clue count drops so later levels of that size are harder.
abstract final class SudokuLevels {
  static const int maxLevel = 365;

  /// Inclusive end of each size band.
  static const int fourEnd = 80;
  static const int sixEnd = 180;

  /// Target board shape for [level] (1-based).
  static SudokuShape shapeFor(int level) {
    if (level <= fourEnd) return SudokuShape.four;
    if (level <= sixEnd) return SudokuShape.six;
    return SudokuShape.nine;
  }

  /// Inclusive level range for the size band containing [level].
  static ({int start, int end}) bandFor(int level) {
    if (level <= fourEnd) return (start: 1, end: fourEnd);
    if (level <= sixEnd) return (start: fourEnd + 1, end: sixEnd);
    return (start: sixEnd + 1, end: maxLevel);
  }

  /// Easy / hard clue targets for a shape (more givens = easier).
  static ({int maxClues, int minClues}) clueRangeFor(SudokuShape shape) {
    return switch (shape.size) {
      4 => (maxClues: 12, minClues: 6),
      6 => (maxClues: 26, minClues: 14),
      _ => (maxClues: 46, minClues: 22),
    };
  }

  /// Target given-cell count for [level] (1-based).
  static int cluesFor(int level) {
    final shape = shapeFor(level);
    final band = bandFor(level);
    final range = clueRangeFor(shape);
    final span = band.end - band.start;
    final t = span == 0 ? 0.0 : (level - band.start) / span;
    return (range.maxClues - t * (range.maxClues - range.minClues)).round();
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
    if (SudokuTutorial.isTutorialLevel(level)) return 'Tutorial';
    var name = _tiers.first.$2;
    for (final (start, tier) in _tiers) {
      if (level >= start) name = tier;
    }
    return name;
  }

  /// Short status like `4×4 · Rookie`.
  static String progressLabel(int level) {
    final shape = shapeFor(level).label;
    return '$shape · ${tierName(level)}';
  }
}

/// Campaign progress saved on-device. Level N is playable when every level
/// below it has been beaten; beating level N unlocks N + 1.
abstract final class SudokuProgress {
  static const _unlockedKey = 'sudoku_highest_unlocked';

  static Future<int> highestUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_unlockedKey) ?? 1;
    return value.clamp(1, SudokuLevels.maxLevel);
  }

  static Future<void> completeLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_unlockedKey) ?? 1;
    final next = min(level + 1, SudokuLevels.maxLevel);
    if (next > current) {
      await prefs.setInt(_unlockedKey, next);
    }
  }
}
