import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/sudoku/sudoku_generator.dart';
import 'package:gaming_adda/games/sudoku/sudoku_levels.dart';
import 'package:gaming_adda/games/sudoku/sudoku_shape.dart';

void main() {
  test('seeded generation is stable', () {
    final a = SudokuGenerator.generate(
      seed: 7,
      targetClues: 10,
      shape: SudokuShape.four,
    );
    final b = SudokuGenerator.generate(
      seed: 7,
      targetClues: 10,
      shape: SudokuShape.four,
    );
    expect(a.puzzle, b.puzzle);
    expect(a.solution, b.solution);
    expect(a.shape, SudokuShape.four);
  });

  test('solution is a valid complete grid for each shape', () {
    for (final shape in [
      SudokuShape.four,
      SudokuShape.six,
      SudokuShape.nine,
    ]) {
      final range = SudokuLevels.clueRangeFor(shape);
      final puzzle = SudokuGenerator.generate(
        seed: 11,
        targetClues: range.maxClues,
        shape: shape,
      );
      expect(
        SudokuGenerator.isValidComplete(puzzle.solution, shape: shape),
        isTrue,
        reason: shape.label,
      );
      expect(puzzle.puzzle.length, shape.size);
    }
  });

  test('puzzle has a unique solution', () {
    final puzzle = SudokuGenerator.generate(
      seed: 99,
      targetClues: 10,
      shape: SudokuShape.four,
    );
    expect(
      SudokuGenerator.countSolutions(puzzle.puzzle, shape: puzzle.shape),
      1,
    );
  });

  test('forLevel uses shape bands and is deterministic', () {
    final early = SudokuGenerator.forLevel(5);
    expect(early.shape, SudokuShape.four);
    expect(SudokuGenerator.forLevel(5).puzzle, early.puzzle);

    final mid = SudokuGenerator.forLevel(100);
    expect(mid.shape, SudokuShape.six);

    final late = SudokuGenerator.forLevel(300);
    expect(late.shape, SudokuShape.nine);
  });

  test('givens match the solution', () {
    final puzzle = SudokuGenerator.generate(
      seed: 3,
      targetClues: 20,
      shape: SudokuShape.six,
    );
    for (var r = 0; r < puzzle.shape.size; r++) {
      for (var c = 0; c < puzzle.shape.size; c++) {
        final d = puzzle.puzzle[r][c];
        if (d == 0) continue;
        expect(d, puzzle.solution[r][c]);
      }
    }
  });
}
