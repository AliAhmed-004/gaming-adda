import 'sudoku_shape.dart';

/// A single cell coordinate on the board.
class SudokuCell {
  const SudokuCell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is SudokuCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

enum _UndoKind { digit, notes }

class _UndoEntry {
  const _UndoEntry.digit({
    required this.row,
    required this.col,
    required this.prevDigit,
    required this.prevNotes,
  }) : kind = _UndoKind.digit;

  const _UndoEntry.notes({
    required this.row,
    required this.col,
    required this.prevDigit,
    required this.prevNotes,
  }) : kind = _UndoKind.notes;

  final _UndoKind kind;
  final int row;
  final int col;
  final int prevDigit;
  final Set<int> prevNotes;
}

/// Pure Sudoku board state: givens, user digits, notes, conflicts, undo.
class SudokuGame {
  SudokuGame({
    required List<List<int>> puzzle,
    required List<List<int>> solution,
    this.shape = SudokuShape.nine,
  })  : assert(puzzle.length == shape.size),
        assert(solution.length == shape.size),
        _givens = List.generate(
          shape.size,
          (r) => List<bool>.generate(shape.size, (c) => puzzle[r][c] != 0),
        ),
        _digits = List.generate(
          shape.size,
          (r) => List<int>.from(puzzle[r]),
        ),
        _notes = List.generate(
          shape.size,
          (_) => List.generate(shape.size, (_) => <int>{}),
        ),
        solution = List.generate(
          shape.size,
          (r) => List<int>.from(solution[r]),
        );

  final SudokuShape shape;

  int get size => shape.size;
  int get boxRows => shape.boxRows;
  int get boxCols => shape.boxCols;
  int get maxDigit => shape.maxDigit;

  /// Complete solved grid matching this puzzle.
  final List<List<int>> solution;

  final List<List<bool>> _givens;
  final List<List<int>> _digits;
  final List<List<Set<int>>> _notes;
  final List<_UndoEntry> _undo = [];

  int? selectedRow;
  int? selectedCol;
  bool notesMode = false;

  bool isGiven(int row, int col) => _givens[row][col];

  int digitAt(int row, int col) => _digits[row][col];

  Set<int> notesAt(int row, int col) =>
      Set<int>.unmodifiable(_notes[row][col]);

  bool get hasSelection => selectedRow != null && selectedCol != null;

  bool get canUndo => _undo.isNotEmpty;

  bool get isSolved {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_digits[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }

  /// Cells whose digit conflicts with another in the same row, col, or box.
  Set<SudokuCell> conflictingCells() {
    final conflicts = <SudokuCell>{};
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final d = _digits[r][c];
        if (d == 0) continue;
        if (_conflictsAt(r, c, d)) {
          conflicts.add(SudokuCell(r, c));
        }
      }
    }
    return conflicts;
  }

  bool isConflict(int row, int col) {
    final d = _digits[row][col];
    if (d == 0) return false;
    return _conflictsAt(row, col, d);
  }

  void select(int row, int col) {
    selectedRow = row;
    selectedCol = col;
  }

  void clearSelection() {
    selectedRow = null;
    selectedCol = null;
  }

  /// Places [digit] (1–[maxDigit]) or clears (0) in the selected cell.
  /// In notes mode, toggles a pencil mark instead.
  bool inputDigit(int digit) {
    if (!hasSelection) return false;
    final row = selectedRow!;
    final col = selectedCol!;
    if (_givens[row][col]) return false;
    if (digit < 0 || digit > maxDigit) return false;

    if (notesMode && digit != 0) {
      return _toggleNote(row, col, digit);
    }
    return _setDigit(row, col, digit);
  }

  bool clearCell() => inputDigit(0);

  bool undo() {
    if (_undo.isEmpty) return false;
    final entry = _undo.removeLast();
    _digits[entry.row][entry.col] = entry.prevDigit;
    _notes[entry.row][entry.col]
      ..clear()
      ..addAll(entry.prevNotes);
    return true;
  }

  /// Fills one empty incorrect cell with the solution digit.
  /// Returns the filled cell, or null if already solved.
  SudokuCell? hint() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_givens[r][c]) continue;
        if (_digits[r][c] == solution[r][c]) continue;
        _setDigit(r, c, solution[r][c], recordUndo: true);
        selectedRow = r;
        selectedCol = c;
        return SudokuCell(r, c);
      }
    }
    return null;
  }

  /// First empty cell (row-major) useful for tutorials.
  SudokuCell? firstEmptyCell() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_digits[r][c] == 0) return SudokuCell(r, c);
      }
    }
    return null;
  }

  int solutionAt(int row, int col) => solution[row][col];

  bool _setDigit(int row, int col, int digit, {bool recordUndo = true}) {
    final prevDigit = _digits[row][col];
    final prevNotes = Set<int>.from(_notes[row][col]);
    if (prevDigit == digit && prevNotes.isEmpty) return false;

    if (recordUndo) {
      _undo.add(_UndoEntry.digit(
        row: row,
        col: col,
        prevDigit: prevDigit,
        prevNotes: prevNotes,
      ));
    }
    _digits[row][col] = digit;
    _notes[row][col].clear();
    return true;
  }

  bool _toggleNote(int row, int col, int digit) {
    final prevDigit = _digits[row][col];
    final prevNotes = Set<int>.from(_notes[row][col]);

    _undo.add(_UndoEntry.notes(
      row: row,
      col: col,
      prevDigit: prevDigit,
      prevNotes: prevNotes,
    ));

    // Notes replace a wrong user digit.
    _digits[row][col] = 0;
    final notes = _notes[row][col];
    if (notes.contains(digit)) {
      notes.remove(digit);
    } else {
      notes.add(digit);
    }
    return true;
  }

  bool _conflictsAt(int row, int col, int digit) {
    for (var c = 0; c < size; c++) {
      if (c != col && _digits[row][c] == digit) return true;
    }
    for (var r = 0; r < size; r++) {
      if (r != row && _digits[r][col] == digit) return true;
    }
    final br = (row ~/ boxRows) * boxRows;
    final bc = (col ~/ boxCols) * boxCols;
    for (var r = br; r < br + boxRows; r++) {
      for (var c = bc; c < bc + boxCols; c++) {
        if ((r != row || c != col) && _digits[r][c] == digit) return true;
      }
    }
    return false;
  }
}
