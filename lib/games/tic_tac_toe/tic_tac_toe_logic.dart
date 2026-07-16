enum Mark { empty, x, o }

enum GameStatus { playing, xWins, oWins, draw }

class TicTacToeGame {
  TicTacToeGame() {
    reset();
  }

  static const winLines = <List<int>>[
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  late List<Mark> board;
  late Mark turn;
  Mark? winner;
  List<int>? winningLine;
  var isDraw = false;

  bool get isOver => winner != null || isDraw;

  GameStatus get status {
    if (winner == Mark.x) return GameStatus.xWins;
    if (winner == Mark.o) return GameStatus.oWins;
    if (isDraw) return GameStatus.draw;
    return GameStatus.playing;
  }

  List<int> get emptyCells {
    return [
      for (var i = 0; i < 9; i++)
        if (board[i] == Mark.empty) i,
    ];
  }

  Mark markAt(int index) => board[index];

  void reset() {
    board = List<Mark>.filled(9, Mark.empty);
    turn = Mark.x;
    winner = null;
    winningLine = null;
    isDraw = false;
  }

  /// Places [turn]'s mark at [index]. Returns false if illegal.
  bool place(int index) {
    if (isOver || index < 0 || index > 8 || board[index] != Mark.empty) {
      return false;
    }

    board[index] = turn;
    final line = _findWinningLine(turn);
    if (line != null) {
      winner = turn;
      winningLine = line;
      return true;
    }

    if (emptyCells.isEmpty) {
      isDraw = true;
      return true;
    }

    turn = turn == Mark.x ? Mark.o : Mark.x;
    return true;
  }

  /// Test helper to set an arbitrary position without validation.
  void setStateForTest({
    required List<Mark> board,
    required Mark turn,
    Mark? winner,
    List<int>? winningLine,
    bool isDraw = false,
  }) {
    assert(board.length == 9);
    this.board = List<Mark>.from(board);
    this.turn = turn;
    this.winner = winner;
    this.winningLine = winningLine == null ? null : List<int>.from(winningLine);
    this.isDraw = isDraw;
  }

  List<int>? _findWinningLine(Mark mark) {
    for (final line in winLines) {
      if (board[line[0]] == mark &&
          board[line[1]] == mark &&
          board[line[2]] == mark) {
        return List<int>.from(line);
      }
    }
    return null;
  }
}
