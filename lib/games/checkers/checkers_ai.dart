import 'dart:math';

import 'checkers_logic.dart';

class CheckersAi {
  CheckersAi({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Prefers capturing moves (especially multi-jumps); otherwise random legal.
  CheckersMove? chooseMove(CheckersGame game) {
    final moves = game.legalMovesFor(Side.light);
    if (moves.isEmpty) return null;

    final captures = moves.where((m) => m.isCapture).toList();
    final pool = captures.isNotEmpty ? captures : moves;

    pool.sort((a, b) {
      final byCaptures = b.captured.length.compareTo(a.captured.length);
      if (byCaptures != 0) return byCaptures;
      // Prefer promoting into kings when possible.
      final aKing = _endsAsKing(game, a);
      final bKing = _endsAsKing(game, b);
      return (bKing ? 1 : 0).compareTo(aKing ? 1 : 0);
    });

    final bestScore = pool.first.captured.length;
    final top = pool.where((m) => m.captured.length == bestScore).toList();
    return top[_random.nextInt(top.length)];
  }

  bool _endsAsKing(CheckersGame game, CheckersMove move) {
    final piece = game.pieceAt(move.from);
    if (piece.isKing) return true;
    return move.to.row == 7;
  }
}
