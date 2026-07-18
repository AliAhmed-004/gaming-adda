import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/sudoku/sudoku_generator.dart';
import 'package:gaming_adda/games/sudoku/sudoku_logic.dart';
import 'package:gaming_adda/games/sudoku/sudoku_shape.dart';

void main() {
  late SudokuGame game;

  setUp(() {
    final puzzle = SudokuGenerator.generate(
      seed: 42,
      targetClues: 10,
      shape: SudokuShape.four,
    );
    game = SudokuGame(
      puzzle: puzzle.puzzle,
      solution: puzzle.solution,
      shape: puzzle.shape,
    );
  });

  test('givens are locked', () {
    for (var r = 0; r < game.size; r++) {
      for (var c = 0; c < game.size; c++) {
        if (!game.isGiven(r, c)) continue;
        game.select(r, c);
        expect(game.inputDigit(1), isFalse);
        return;
      }
    }
    fail('expected at least one given');
  });

  test('rejects digits above maxDigit', () {
    final empty = game.firstEmptyCell()!;
    game.select(empty.row, empty.col);
    expect(game.inputDigit(5), isFalse);
    expect(game.inputDigit(9), isFalse);
  });

  test('place erase and undo', () {
    final empty = game.firstEmptyCell()!;
    game.select(empty.row, empty.col);
    final solutionDigit = game.solutionAt(empty.row, empty.col);

    expect(game.inputDigit(solutionDigit), isTrue);
    expect(game.digitAt(empty.row, empty.col), solutionDigit);

    expect(game.clearCell(), isTrue);
    expect(game.digitAt(empty.row, empty.col), 0);

    expect(game.undo(), isTrue);
    expect(game.digitAt(empty.row, empty.col), solutionDigit);

    expect(game.undo(), isTrue);
    expect(game.digitAt(empty.row, empty.col), 0);
  });

  test('notes toggle in notes mode', () {
    final empty = game.firstEmptyCell()!;
    game.select(empty.row, empty.col);
    game.notesMode = true;

    expect(game.inputDigit(2), isTrue);
    expect(game.notesAt(empty.row, empty.col), contains(2));
    expect(game.digitAt(empty.row, empty.col), 0);

    expect(game.inputDigit(2), isTrue);
    expect(game.notesAt(empty.row, empty.col), isEmpty);
  });

  test('conflicts detect duplicate digits', () {
    final empty = game.firstEmptyCell()!;
    var conflictDigit = 0;
    for (var c = 0; c < game.size; c++) {
      final d = game.digitAt(empty.row, c);
      if (d != 0) {
        conflictDigit = d;
        break;
      }
    }
    if (conflictDigit == 0) conflictDigit = 1;

    game.select(empty.row, empty.col);
    game.inputDigit(conflictDigit);
    expect(game.isConflict(empty.row, empty.col), isTrue);
    expect(game.conflictingCells(), isNotEmpty);
  });

  test('hint fills a correct empty cell', () {
    final before = game.firstEmptyCell();
    expect(before, isNotNull);
    final cell = game.hint();
    expect(cell, isNotNull);
    expect(
      game.digitAt(cell!.row, cell.col),
      game.solutionAt(cell.row, cell.col),
    );
  });

  test('isSolved when board matches solution', () {
    expect(game.isSolved, isFalse);
    for (var r = 0; r < game.size; r++) {
      for (var c = 0; c < game.size; c++) {
        if (game.isGiven(r, c)) continue;
        game.select(r, c);
        game.inputDigit(game.solutionAt(r, c));
      }
    }
    expect(game.isSolved, isTrue);
  });
}
