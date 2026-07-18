import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/tic_tac_toe/tic_tac_toe_logic.dart';

void main() {
  group('TicTacToeGame', () {
    test('starts empty with X to move', () {
      final game = TicTacToeGame();
      expect(game.board.every((m) => m == Mark.empty), isTrue);
      expect(game.turn, Mark.x);
      expect(game.isOver, isFalse);
      expect(game.status, GameStatus.playing);
    });

    test('rejects occupied cells and out-of-range indexes', () {
      final game = TicTacToeGame();
      expect(game.place(0), isTrue);
      expect(game.place(0), isFalse);
      expect(game.place(-1), isFalse);
      expect(game.place(9), isFalse);
    });

    test('alternates turns X then O', () {
      final game = TicTacToeGame();
      game.place(0);
      expect(game.turn, Mark.o);
      game.place(1);
      expect(game.turn, Mark.x);
    });

    test('detects all eight winning lines for X', () {
      for (final line in TicTacToeGame.winLines) {
        final game = TicTacToeGame();
        // Fill winning line with X; fill other cells so O never wins first.
        // Play sequence: X takes line cells interleaved with O elsewhere.
        final others = [
          for (var i = 0; i < 9; i++)
            if (!line.contains(i)) i,
        ];
        game.place(line[0]); // X
        game.place(others[0]); // O
        game.place(line[1]); // X
        game.place(others[1]); // O
        expect(game.place(line[2]), isTrue); // X wins
        expect(game.winner, Mark.x);
        expect(game.winningLine, line);
        expect(game.status, GameStatus.xWins);
        expect(game.place(others[2]), isFalse);
      }
    });

    test('detects draw when board is full without a winner', () {
      final game = TicTacToeGame();
      // X O X
      // X O O
      // O X X
      const moves = [0, 1, 2, 4, 3, 5, 7, 6, 8];
      for (final m in moves) {
        expect(game.place(m), isTrue);
      }
      expect(game.isDraw, isTrue);
      expect(game.winner, isNull);
      expect(game.status, GameStatus.draw);
      expect(game.isOver, isTrue);
    });

    test('reset clears the board', () {
      final game = TicTacToeGame();
      game.place(0);
      game.place(1);
      game.reset();
      expect(game.board.every((m) => m == Mark.empty), isTrue);
      expect(game.turn, Mark.x);
      expect(game.winner, isNull);
      expect(game.isDraw, isFalse);
    });
  });
}
