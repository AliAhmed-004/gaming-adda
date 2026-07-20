import 'dart:math';

import 'sudoku_config.dart';
import 'sudoku_levels.dart';
import 'sudoku_shape.dart';

/// A generated puzzle plus its unique solution.
class SudokuPuzzle {
  const SudokuPuzzle({
    required this.puzzle,
    required this.solution,
    required this.clueCount,
    required this.shape,
  });

  final List<List<int>> puzzle;
  final List<List<int>> solution;
  final int clueCount;
  final SudokuShape shape;
}

/// Seeded Sudoku generator: fill a complete grid, then dig cells while
/// keeping a unique solution. Supports 4×4, 6×6, and 9×9 shapes.
abstract final class SudokuGenerator {
  static SudokuPuzzle forLevel(int level) {
    final shape = SudokuLevels.shapeFor(level);
    final clues = SudokuLevels.cluesFor(level);
    return generate(seed: level, targetClues: clues, shape: shape);
  }

  static SudokuPuzzle forDifficulty(SudokuDifficulty difficulty) {
    final shape = switch (difficulty) {
      SudokuDifficulty.easy => SudokuShape.four,
      SudokuDifficulty.medium => SudokuShape.six,
      SudokuDifficulty.hard => SudokuShape.nine,
    };
    final range = SudokuLevels.clueRangeFor(shape);
    // Mid-band difficulty within the chosen size.
    final clues = ((range.maxClues + range.minClues) / 2).round();
    final seed = DateTime.now().microsecondsSinceEpoch ^ difficulty.index;
    return generate(seed: seed, targetClues: clues, shape: shape);
  }

  static SudokuPuzzle generate({
    required int seed,
    required int targetClues,
    SudokuShape shape = SudokuShape.nine,
  }) {
    final rng = Random(seed);
    final size = shape.size;
    final solution = _emptyGrid(size);
    _fillGrid(solution, rng, shape);

    final puzzle = List.generate(
      size,
      (r) => List<int>.from(solution[r]),
    );

    final positions = [
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++) (r, c),
    ]..shuffle(rng);

    var clues = size * size;
    for (final (r, c) in positions) {
      if (clues <= targetClues) break;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;
      if (_countSolutions(puzzle, shape, limit: 2) != 1) {
        puzzle[r][c] = backup;
      } else {
        clues--;
      }
    }

    return SudokuPuzzle(
      puzzle: puzzle,
      solution: solution,
      clueCount: clues,
      shape: shape,
    );
  }

  static bool isValidComplete(
    List<List<int>> grid, {
    SudokuShape shape = SudokuShape.nine,
  }) {
    final size = shape.size;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final d = grid[r][c];
        if (d < 1 || d > shape.maxDigit) return false;
        if (!_isSafe(grid, r, c, d, shape, ignoreSelf: true)) return false;
      }
    }
    return true;
  }

  static int countSolutions(
    List<List<int>> puzzle, {
    SudokuShape shape = SudokuShape.nine,
    int limit = 2,
  }) =>
      _countSolutions(puzzle, shape, limit: limit);

  static List<List<int>> _emptyGrid(int size) =>
      List.generate(size, (_) => List.filled(size, 0));

  static bool _fillGrid(
    List<List<int>> grid,
    Random rng,
    SudokuShape shape,
  ) {
    final size = shape.size;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] != 0) continue;
        final digits =
            List<int>.generate(shape.maxDigit, (i) => i + 1)..shuffle(rng);
        for (final d in digits) {
          if (!_isSafe(grid, r, c, d, shape)) continue;
          grid[r][c] = d;
          if (_fillGrid(grid, rng, shape)) return true;
          grid[r][c] = 0;
        }
        return false;
      }
    }
    return true;
  }

  static int _countSolutions(
    List<List<int>> grid,
    SudokuShape shape, {
    required int limit,
  }) {
    var count = 0;
    final size = shape.size;

    bool solve() {
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (grid[r][c] != 0) continue;
          for (var d = 1; d <= shape.maxDigit; d++) {
            if (!_isSafe(grid, r, c, d, shape)) continue;
            grid[r][c] = d;
            final done = solve();
            grid[r][c] = 0;
            if (done) return true;
          }
          return false;
        }
      }
      count++;
      return count >= limit;
    }

    solve();
    return count;
  }

  static bool _isSafe(
    List<List<int>> grid,
    int row,
    int col,
    int digit,
    SudokuShape shape, {
    bool ignoreSelf = false,
  }) {
    final size = shape.size;
    for (var c = 0; c < size; c++) {
      if (ignoreSelf && c == col) continue;
      if (grid[row][c] == digit) return false;
    }
    for (var r = 0; r < size; r++) {
      if (ignoreSelf && r == row) continue;
      if (grid[r][col] == digit) return false;
    }
    final br = (row ~/ shape.boxRows) * shape.boxRows;
    final bc = (col ~/ shape.boxCols) * shape.boxCols;
    for (var r = br; r < br + shape.boxRows; r++) {
      for (var c = bc; c < bc + shape.boxCols; c++) {
        if (ignoreSelf && r == row && c == col) continue;
        if (grid[r][c] == digit) return false;
      }
    }
    return true;
  }
}
