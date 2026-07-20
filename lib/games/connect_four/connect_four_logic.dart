enum Disc { none, red, yellow }

extension DiscX on Disc {
  bool get isEmpty => this == Disc.none;

  Disc get opposite => switch (this) {
        Disc.red => Disc.yellow,
        Disc.yellow => Disc.red,
        Disc.none => Disc.none,
      };
}

class Cell {
  const Cell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

/// Standard 7x6 Connect Four. Row 0 is the top of the grid; discs dropped in
/// a column settle at the highest empty row index (bottom of the board).
class ConnectFourGame {
  ConnectFourGame() {
    reset();
  }

  static const int rows = 6;
  static const int cols = 7;
  static const int winLength = 4;

  late List<List<Disc>> board;
  late Disc turn;
  Disc? winner;
  bool isDraw = false;

  /// Cells forming the winning line, empty until someone wins.
  List<Cell> winningLine = const [];

  /// Column of the most recent drop, or null at game start.
  int? lastColumn;

  /// Landing cell of the most recent drop, used by the UI drop animation.
  Cell? lastMove;

  bool get isOver => winner != null || isDraw;

  void reset() {
    board = List.generate(rows, (_) => List.filled(cols, Disc.none));
    turn = Disc.red;
    winner = null;
    isDraw = false;
    winningLine = const [];
    lastColumn = null;
    lastMove = null;
  }

  Disc discAt(int row, int col) => board[row][col];

  bool canDrop(int col) =>
      !isOver && col >= 0 && col < cols && board[0][col].isEmpty;

  List<int> get legalColumns =>
      [for (var c = 0; c < cols; c++) if (canDrop(c)) c];

  /// Row the disc would land in for [col], or null if the column is full.
  int? landingRow(int col) {
    if (col < 0 || col >= cols) return null;
    for (var row = rows - 1; row >= 0; row--) {
      if (board[row][col].isEmpty) return row;
    }
    return null;
  }

  /// Drops the current player's disc in [col]. Returns the landing cell,
  /// or null if the move is illegal.
  Cell? drop(int col) {
    if (!canDrop(col)) return null;
    final row = landingRow(col)!;
    board[row][col] = turn;
    lastColumn = col;
    lastMove = Cell(row, col);

    final line = _findWinningLine(row, col);
    if (line != null) {
      winner = turn;
      winningLine = line;
    } else if (legalColumns.isEmpty) {
      isDraw = true;
    } else {
      turn = turn.opposite;
    }
    return Cell(row, col);
  }

  /// Undoes the top disc of [col]. Used by the AI search.
  void undo(int col) {
    for (var row = 0; row < rows; row++) {
      if (!board[row][col].isEmpty) {
        turn = board[row][col];
        board[row][col] = Disc.none;
        winner = null;
        isDraw = false;
        winningLine = const [];
        return;
      }
    }
  }

  List<Cell>? _findWinningLine(int row, int col) {
    final disc = board[row][col];
    const directions = [(0, 1), (1, 0), (1, 1), (1, -1)];

    for (final (dr, dc) in directions) {
      final line = [Cell(row, col)];
      for (final sign in [1, -1]) {
        var r = row + dr * sign;
        var c = col + dc * sign;
        while (r >= 0 &&
            r < rows &&
            c >= 0 &&
            c < cols &&
            board[r][c] == disc) {
          line.add(Cell(r, c));
          r += dr * sign;
          c += dc * sign;
        }
      }
      if (line.length >= winLength) return line;
    }
    return null;
  }
}
