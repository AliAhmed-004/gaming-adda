import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/connect_four/connect_four_ai.dart';
import 'package:gaming_adda/games/connect_four/connect_four_logic.dart';

void main() {
  test('initial position: red to move, all columns open', () {
    final game = ConnectFourGame();
    expect(game.turn, Disc.red);
    expect(game.winner, isNull);
    expect(game.isDraw, isFalse);
    expect(game.legalColumns, [0, 1, 2, 3, 4, 5, 6]);
  });

  test('discs stack from the bottom and turns alternate', () {
    final game = ConnectFourGame();
    final first = game.drop(3);
    expect(first, const Cell(5, 3));
    expect(game.turn, Disc.yellow);

    final second = game.drop(3);
    expect(second, const Cell(4, 3));
    expect(game.turn, Disc.red);

    expect(game.discAt(5, 3), Disc.red);
    expect(game.discAt(4, 3), Disc.yellow);
  });

  test('column fills up and rejects further drops', () {
    final game = ConnectFourGame();
    for (var i = 0; i < ConnectFourGame.rows; i++) {
      expect(game.drop(0), isNotNull);
    }
    expect(game.canDrop(0), isFalse);
    expect(game.drop(0), isNull);
  });

  test('vertical four in a row wins', () {
    final game = ConnectFourGame();
    // Red stacks column 0; yellow wastes moves in column 6.
    for (var i = 0; i < 3; i++) {
      game.drop(0);
      game.drop(6);
    }
    game.drop(0);
    expect(game.winner, Disc.red);
    expect(game.isOver, isTrue);
    expect(game.winningLine.length, 4);
    expect(game.winningLine, contains(const Cell(5, 0)));
    expect(game.legalColumns, isEmpty);
  });

  test('horizontal four in a row wins', () {
    final game = ConnectFourGame();
    // Red plays columns 0-3 along the bottom; yellow stacks column 6.
    for (var col = 0; col < 3; col++) {
      game.drop(col);
      game.drop(6);
    }
    game.drop(3);
    expect(game.winner, Disc.red);
    expect(game.winningLine, containsAll(const [Cell(5, 0), Cell(5, 3)]));
  });

  test('diagonal four in a row wins', () {
    final game = ConnectFourGame();
    // Build a staircase for red: (5,0) (4,1) (3,2) (2,3).
    game.drop(0); // R
    game.drop(1); // Y
    game.drop(1); // R
    game.drop(2); // Y
    game.drop(2); // R
    game.drop(3); // Y
    game.drop(2); // R
    game.drop(3); // Y
    game.drop(3); // R
    game.drop(6); // Y
    game.drop(3); // R -> completes diagonal
    expect(game.winner, Disc.red);
  });

  test('undo restores board, turn, and win state', () {
    final game = ConnectFourGame();
    for (var i = 0; i < 3; i++) {
      game.drop(0);
      game.drop(6);
    }
    game.drop(0); // red wins
    expect(game.winner, Disc.red);

    game.undo(0);
    expect(game.winner, isNull);
    expect(game.turn, Disc.red);
    expect(game.discAt(2, 0), Disc.none);
    expect(game.winningLine, isEmpty);
  });

  test('AI takes an immediate winning column', () {
    final game = ConnectFourGame();
    // Yellow has three in column 5; it is yellow's turn.
    game.drop(0); // R
    game.drop(5); // Y
    game.drop(0); // R
    game.drop(5); // Y
    game.drop(1); // R
    game.drop(5); // Y
    game.drop(1); // R
    expect(game.turn, Disc.yellow);

    final ai = ConnectFourAi();
    expect(ai.chooseColumn(game), 5);
  });

  test('AI blocks an immediate opponent win', () {
    final game = ConnectFourGame();
    // Red has three along the bottom (cols 0-2); yellow must block col 3.
    game.drop(0); // R
    game.drop(0); // Y
    game.drop(1); // R
    game.drop(1); // Y
    game.drop(2); // R
    expect(game.turn, Disc.yellow);

    final ai = ConnectFourAi();
    expect(ai.chooseColumn(game), 3);
  });
}
