import 'dart:math';

import 'ludo_logic.dart';

class LudoAi {
  LudoAi({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Prefer enter → capture → finish → advance toward home.
  LudoMove? chooseMove(LudoGame game) {
    final moves = game.legalMovesForCurrentRoll();
    if (moves.isEmpty) return null;

    int score(LudoMove m) {
      var s = 0;
      if (m.entersBoard) s += 100;
      if (m.isCapture) s += 80;
      if (m.finishes) s += 60;
      s += m.toProgress;
      final destGlobal = m.toProgress < LudoGame.homeStretchStart
          ? (m.color.startIndex + m.toProgress) % LudoGame.trackLength
          : null;
      if (destGlobal != null && game.isSafeGlobal(destGlobal)) s += 15;
      return s;
    }

    moves.sort((a, b) => score(b).compareTo(score(a)));
    final best = score(moves.first);
    final top = moves.where((m) => score(m) == best).toList();
    return top[_random.nextInt(top.length)];
  }
}
