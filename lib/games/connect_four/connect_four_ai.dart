import 'dart:math';

import 'connect_four_levels.dart';
import 'connect_four_logic.dart';

/// Shallow minimax with alpha-beta pruning. Always plays the side whose
/// turn it currently is in [ConnectFourGame].
class ConnectFourAi {
  ConnectFourAi({Random? random, this.depth = 5, this.randomMoveChance = 0})
      : _random = random ?? Random();

  /// AI tuned to a campaign level: weak levels blunder often and search
  /// shallow, strong levels never blunder and search deep.
  factory ConnectFourAi.forLevel(int level, {Random? random}) {
    return ConnectFourAi(
      random: random,
      depth: ConnectFourLevels.depthFor(level),
      randomMoveChance: ConnectFourLevels.randomnessFor(level),
    );
  }

  final Random _random;
  final int depth;

  /// Probability per move of playing a random column instead of thinking.
  final double randomMoveChance;

  static const _searchOrder = [3, 2, 4, 1, 5, 0, 6];

  // NOTE: must be a plain literal, not `-1 << 30`. On the web, shift
  // operators work on unsigned 32-bit values, so `-1 << 30` evaluates to a
  // large positive number and broke the score comparisons below.
  static const _inf = 1073741824;

  int? chooseColumn(ConnectFourGame game) {
    final legal = game.legalColumns;
    if (legal.isEmpty) return null;

    final me = game.turn;

    // Deliberate blunder: weak levels sometimes don't think at all, which
    // also makes them miss their own wins and the opponent's threats.
    if (randomMoveChance > 0 && _random.nextDouble() < randomMoveChance) {
      return legal[_random.nextInt(legal.length)];
    }

    // Immediate win.
    for (final col in legal) {
      game.drop(col);
      final wins = game.winner == me;
      game.undo(col);
      if (wins) return col;
    }

    var bestScore = -_inf;
    final bestCols = <int>[];
    for (final col in _searchOrder) {
      if (!legal.contains(col)) continue;
      game.drop(col);
      final score = -_negamax(game, depth - 1, -_inf, _inf, me.opposite);
      game.undo(col);
      if (score > bestScore) {
        bestScore = score;
        bestCols
          ..clear()
          ..add(col);
      } else if (score == bestScore) {
        bestCols.add(col);
      }
    }
    return bestCols[_random.nextInt(bestCols.length)];
  }

  int _negamax(ConnectFourGame game, int depth, int alpha, int beta, Disc me) {
    if (game.winner != null) {
      // Previous player just won; bad for `me`. Prefer faster wins.
      return game.winner == me ? 100000 + depth : -(100000 + depth);
    }
    if (game.isDraw) return 0;
    if (depth == 0) return _evaluate(game, me);

    var best = -_inf;
    for (final col in _searchOrder) {
      if (!game.canDrop(col)) continue;
      game.drop(col);
      final score = -_negamax(game, depth - 1, -beta, -alpha, me.opposite);
      game.undo(col);
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  /// Scores every 4-cell window: open threats are rewarded, opponent
  /// threats penalized, with a small bonus for center-column control.
  int _evaluate(ConnectFourGame game, Disc me) {
    var score = 0;
    final opp = me.opposite;

    for (var row = 0; row < ConnectFourGame.rows; row++) {
      if (game.discAt(row, 3) == me) score += 3;
      if (game.discAt(row, 3) == opp) score -= 3;
    }

    const directions = [(0, 1), (1, 0), (1, 1), (1, -1)];
    for (var row = 0; row < ConnectFourGame.rows; row++) {
      for (var col = 0; col < ConnectFourGame.cols; col++) {
        for (final (dr, dc) in directions) {
          final endRow = row + dr * 3;
          final endCol = col + dc * 3;
          if (endRow < 0 ||
              endRow >= ConnectFourGame.rows ||
              endCol < 0 ||
              endCol >= ConnectFourGame.cols) {
            continue;
          }
          var mine = 0;
          var theirs = 0;
          for (var i = 0; i < 4; i++) {
            final disc = game.discAt(row + dr * i, col + dc * i);
            if (disc == me) mine++;
            if (disc == opp) theirs++;
          }
          if (theirs == 0) {
            if (mine == 3) score += 40;
            if (mine == 2) score += 8;
          } else if (mine == 0) {
            if (theirs == 3) score -= 45;
            if (theirs == 2) score -= 8;
          }
        }
      }
    }
    return score;
  }
}
