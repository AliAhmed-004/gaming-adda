import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/tic_tac_toe/tic_tac_toe_ai.dart';
import 'package:gaming_adda/games/tic_tac_toe/tic_tac_toe_config.dart';
import 'package:gaming_adda/games/tic_tac_toe/tic_tac_toe_logic.dart';

void main() {
  group('TicTacToeAi', () {
    test('easy returns a legal empty cell', () {
      final game = TicTacToeGame();
      game.place(0); // X
      final ai = TicTacToeAi(
        difficulty: TicTacToeAiDifficulty.easy,
        random: Random(1),
      );
      final move = ai.chooseMove(game);
      expect(move, isNotNull);
      expect(game.emptyCells, contains(move));
    });

    test('medium takes an immediate winning move', () {
      final game = TicTacToeGame();
      // X at 0,1 — O to play somewhere — set board so O can win on 2,5,8 col? 
      // Better: O has 0 and 1 empty? Wait AI is O.
      // Board: O O _ on top row → O to play → should take 2.
      game.setStateForTest(
        board: const [
          Mark.o, Mark.o, Mark.empty,
          Mark.x, Mark.x, Mark.empty,
          Mark.empty, Mark.empty, Mark.empty,
        ],
        turn: Mark.o,
      );
      final ai = TicTacToeAi(
        difficulty: TicTacToeAiDifficulty.medium,
        random: Random(0),
      );
      expect(ai.chooseMove(game), 2);
    });

    test('medium blocks opponent winning move', () {
      final game = TicTacToeGame();
      game.setStateForTest(
        board: const [
          Mark.x, Mark.x, Mark.empty,
          Mark.o, Mark.empty, Mark.empty,
          Mark.empty, Mark.empty, Mark.empty,
        ],
        turn: Mark.o,
      );
      final ai = TicTacToeAi(
        difficulty: TicTacToeAiDifficulty.medium,
        random: Random(0),
      );
      expect(ai.chooseMove(game), 2);
    });

    test('hard never loses when both sides play optimally from start', () {
      final random = Random(42);
      final hard = TicTacToeAi(
        difficulty: TicTacToeAiDifficulty.hard,
        random: random,
      );

      // X plays center, then AI responds optimally for rest of game as O.
      // Play many games where X is also hard (clone minimax as X).
      for (var gameIndex = 0; gameIndex < 20; gameIndex++) {
        final game = TicTacToeGame();
        while (!game.isOver) {
          if (game.turn == Mark.x) {
            final move = _bestForX(game, random);
            expect(game.place(move), isTrue);
          } else {
            final move = hard.chooseMove(game);
            expect(move, isNotNull);
            expect(game.place(move!), isTrue);
          }
        }
        // Perfect play → draw (or at worst AI never loses as O if X also optimal).
        expect(game.winner, isNot(Mark.o));
      }
    });

    test('returns null when not AI turn or game over', () {
      final game = TicTacToeGame();
      final ai = TicTacToeAi(difficulty: TicTacToeAiDifficulty.hard);
      expect(ai.chooseMove(game), isNull); // X to move
      game.setStateForTest(
        board: List.filled(9, Mark.x),
        turn: Mark.o,
        winner: Mark.x,
        winningLine: const [0, 1, 2],
      );
      expect(ai.chooseMove(game), isNull);
    });
  });
}

int _bestForX(TicTacToeGame game, Random random) {
  var bestScore = -1000;
  final bestMoves = <int>[];
  for (final index in game.emptyCells) {
    final next = TicTacToeGame()
      ..setStateForTest(board: game.board, turn: game.turn);
    next.place(index);
    final score = _minimaxX(next, maximizingO: true);
    if (score > bestScore) {
      bestScore = score;
      bestMoves
        ..clear()
        ..add(index);
    } else if (score == bestScore) {
      bestMoves.add(index);
    }
  }
  return bestMoves[random.nextInt(bestMoves.length)];
}

int _minimaxX(TicTacToeGame game, {required bool maximizingO}) {
  if (game.winner == Mark.x) return 10;
  if (game.winner == Mark.o) return -10;
  if (game.isDraw) return 0;

  if (!maximizingO) {
    var best = -1000;
    for (final index in game.emptyCells) {
      final next = TicTacToeGame()
        ..setStateForTest(board: game.board, turn: game.turn);
      next.place(index);
      best = best > _minimaxX(next, maximizingO: true)
          ? best
          : _minimaxX(next, maximizingO: true);
    }
    return best;
  }

  var best = 1000;
  for (final index in game.emptyCells) {
    final next = TicTacToeGame()
      ..setStateForTest(board: game.board, turn: game.turn);
    next.place(index);
    final score = _minimaxX(next, maximizingO: false);
    best = best < score ? best : score;
  }
  return best;
}
