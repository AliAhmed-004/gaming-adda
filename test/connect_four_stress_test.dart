import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/connect_four/connect_four_ai.dart';
import 'package:gaming_adda/games/connect_four/connect_four_logic.dart';

/// Regression stress test for a crash where ConnectFourAi.chooseColumn
/// called Random.nextInt(0). Plays many full games: red picks random legal
/// columns, yellow uses the AI, until every game finishes.
void main() {
  test('AI survives many full random games', () {
    final rng = Random(42);
    final ai = ConnectFourAi(random: Random(7), depth: 5);

    for (var g = 0; g < 200; g++) {
      final game = ConnectFourGame();
      while (!game.isOver) {
        if (game.turn == Disc.red) {
          final legal = game.legalColumns;
          game.drop(legal[rng.nextInt(legal.length)]);
        } else {
          final col = ai.chooseColumn(game);
          expect(col, isNotNull, reason: 'game $g: AI returned null mid-game');
          expect(game.drop(col!), isNotNull,
              reason: 'game $g: AI chose illegal column $col');
        }
      }
    }
  });
}
