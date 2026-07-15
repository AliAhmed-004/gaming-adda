import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/checkers/checkers_ai.dart';
import 'package:gaming_adda/games/checkers/checkers_logic.dart';

void main() {
  test('initial position has dark to move with only quiet advances', () {
    final game = CheckersGame();
    expect(game.turn, Side.dark);
    expect(game.winner, isNull);

    final moves = game.legalMovesFor(Side.dark);
    expect(moves, isNotEmpty);
    expect(moves.every((m) => !m.isCapture), isTrue);
    // Front-row dark men on row 5 can step to row 4.
    expect(moves.every((m) => m.from.row == 5), isTrue);
  });

  test('mandatory capture is preferred over quiet moves', () {
    final game = CheckersGame();
    // Clear board and set up a forced capture for dark.
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        game.setPiece(Square(r, c), Piece.empty);
      }
    }
    game.setPiece(const Square(4, 3), Piece.darkMan);
    game.setPiece(const Square(3, 2), Piece.lightMan);
    game.turn = Side.dark;

    final moves = game.legalMovesFor(Side.dark);
    expect(moves.length, 1);
    expect(moves.single.isCapture, isTrue);
    expect(moves.single.to, const Square(2, 1));
  });

  test('AI returns a legal light-side move', () {
    final game = CheckersGame();
    // Make one dark move so it is light's turn.
    final darkMove = game.legalMovesFor(Side.dark).first;
    game.applyMove(darkMove);
    expect(game.turn, Side.light);

    final ai = CheckersAi();
    final choice = ai.chooseMove(game);
    expect(choice, isNotNull);
    expect(
      game.legalMovesFor(Side.light).any((m) => m.to == choice!.to && m.from == choice.from),
      isTrue,
    );
  });
}
