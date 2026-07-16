import 'dart:math';

import 'tic_tac_toe_config.dart';
import 'tic_tac_toe_logic.dart';

class TicTacToeAi {
  TicTacToeAi({
    this.difficulty = TicTacToeAiDifficulty.medium,
    Random? random,
  }) : _random = random ?? Random();

  final TicTacToeAiDifficulty difficulty;
  final Random _random;

  /// Human is always X; AI plays as O.
  static const aiMark = Mark.o;
  static const humanMark = Mark.x;

  int? chooseMove(TicTacToeGame game) {
    if (game.isOver || game.turn != aiMark) return null;
    final empties = game.emptyCells;
    if (empties.isEmpty) return null;

    return switch (difficulty) {
      TicTacToeAiDifficulty.easy => _easy(empties),
      TicTacToeAiDifficulty.medium => _medium(game, empties),
      TicTacToeAiDifficulty.hard => _hard(game, empties),
    };
  }

  int _easy(List<int> empties) => empties[_random.nextInt(empties.length)];

  int _medium(TicTacToeGame game, List<int> empties) {
    final win = _findingMove(game, aiMark);
    if (win != null) return win;

    final block = _findingMove(game, humanMark);
    if (block != null) return block;

    if (empties.contains(4)) return 4;

    const corners = [0, 2, 6, 8];
    final openCorners = corners.where(empties.contains).toList();
    if (openCorners.isNotEmpty) {
      return openCorners[_random.nextInt(openCorners.length)];
    }

    return empties[_random.nextInt(empties.length)];
  }

  int _hard(TicTacToeGame game, List<int> empties) {
    var bestScore = -1000;
    final bestMoves = <int>[];

    for (final index in empties) {
      final next = _clone(game);
      next.place(index);
      final score = _minimax(next, maximizing: false);
      if (score > bestScore) {
        bestScore = score;
        bestMoves
          ..clear()
          ..add(index);
      } else if (score == bestScore) {
        bestMoves.add(index);
      }
    }

    return bestMoves[_random.nextInt(bestMoves.length)];
  }

  int _minimax(TicTacToeGame game, {required bool maximizing}) {
    if (game.winner == aiMark) return 10;
    if (game.winner == humanMark) return -10;
    if (game.isDraw) return 0;

    final empties = game.emptyCells;
    if (maximizing) {
      var best = -1000;
      for (final index in empties) {
        final next = _clone(game);
        next.place(index);
        best = max(best, _minimax(next, maximizing: false));
      }
      return best;
    }

    var best = 1000;
    for (final index in empties) {
      final next = _clone(game);
      next.place(index);
      best = min(best, _minimax(next, maximizing: true));
    }
    return best;
  }

  int? _findingMove(TicTacToeGame game, Mark mark) {
    for (final index in game.emptyCells) {
      final next = _clone(game);
      next.setStateForTest(
        board: game.board,
        turn: mark,
        winner: null,
        winningLine: null,
      );
      next.place(index);
      if (next.winner == mark) return index;
    }
    return null;
  }

  TicTacToeGame _clone(TicTacToeGame game) {
    final copy = TicTacToeGame();
    copy.setStateForTest(
      board: game.board,
      turn: game.turn,
      winner: game.winner,
      winningLine: game.winningLine,
      isDraw: game.isDraw,
    );
    return copy;
  }
}
