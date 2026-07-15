enum Piece {
  empty,
  darkMan,
  darkKing,
  lightMan,
  lightKing,
}

extension PieceX on Piece {
  bool get isEmpty => this == Piece.empty;
  bool get isDark => this == Piece.darkMan || this == Piece.darkKing;
  bool get isLight => this == Piece.lightMan || this == Piece.lightKing;
  bool get isKing => this == Piece.darkKing || this == Piece.lightKing;

  Piece promote() {
    if (this == Piece.darkMan) return Piece.darkKing;
    if (this == Piece.lightMan) return Piece.lightKing;
    return this;
  }
}

enum Side { dark, light }

extension SideX on Side {
  Side get opposite => this == Side.dark ? Side.light : Side.dark;

  bool owns(Piece piece) =>
      this == Side.dark ? piece.isDark : piece.isLight;
}

class Square {
  const Square(this.row, this.col);

  final int row;
  final int col;

  bool get isOnBoard => row >= 0 && row < 8 && col >= 0 && col < 8;

  /// Dark playable squares on a standard board (dark in bottom-left).
  bool get isDarkSquare => (row + col).isOdd;

  @override
  bool operator ==(Object other) =>
      other is Square && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

class CheckersMove {
  const CheckersMove({
    required this.from,
    required this.path,
    required this.captured,
  });

  final Square from;

  /// Intermediate landing squares, ending at the final destination.
  final List<Square> path;
  final List<Square> captured;

  Square get to => path.last;

  bool get isCapture => captured.isNotEmpty;
}

class CheckersGame {
  CheckersGame() {
    reset();
  }

  late List<List<Piece>> board;
  late Side turn;
  Side? winner;

  /// When a multi-jump is in progress, the piece that must continue.
  Square? forcedJumper;

  void reset() {
    board = List.generate(8, (_) => List.filled(8, Piece.empty));
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 8; col++) {
        if ((row + col).isOdd) {
          board[row][col] = Piece.lightMan;
        }
      }
    }
    for (var row = 5; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        if ((row + col).isOdd) {
          board[row][col] = Piece.darkMan;
        }
      }
    }
    turn = Side.dark;
    winner = null;
    forcedJumper = null;
  }

  Piece pieceAt(Square s) => board[s.row][s.col];

  void setPiece(Square s, Piece p) => board[s.row][s.col] = p;

  List<CheckersMove> legalMovesFor(Side side) {
    if (winner != null) return const [];

    if (forcedJumper != null) {
      final piece = pieceAt(forcedJumper!);
      if (!side.owns(piece)) return const [];
      return _capturesFrom(forcedJumper!, piece, const []);
    }

    final captures = <CheckersMove>[];
    final quiet = <CheckersMove>[];

    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        final sq = Square(row, col);
        final piece = pieceAt(sq);
        if (!side.owns(piece)) continue;
        captures.addAll(_capturesFrom(sq, piece, const []));
        quiet.addAll(_quietMovesFrom(sq, piece));
      }
    }

    if (captures.isNotEmpty) return captures;
    return quiet;
  }

  List<CheckersMove> movesFrom(Square from) {
    return legalMovesFor(turn).where((m) => m.from == from).toList();
  }

  /// Applies a full legal move (including multi-jump path).
  void applyMove(CheckersMove move) {
    assert(winner == null);
    var piece = pieceAt(move.from);
    setPiece(move.from, Piece.empty);

    for (final cap in move.captured) {
      setPiece(cap, Piece.empty);
    }

    final dest = move.to;
    // Promote if man reaches last row.
    if (!piece.isKing) {
      if (piece.isDark && dest.row == 0) piece = piece.promote();
      if (piece.isLight && dest.row == 7) piece = piece.promote();
    }
    setPiece(dest, piece);

    forcedJumper = null;
    turn = turn.opposite;
    _updateWinner();
  }

  void _updateWinner() {
    final darkMoves = legalMovesFor(Side.dark);
    final lightMoves = legalMovesFor(Side.light);
    final darkPieces = _countPieces(Side.dark);
    final lightPieces = _countPieces(Side.light);

    if (darkPieces == 0 || (turn == Side.dark && darkMoves.isEmpty)) {
      winner = Side.light;
    } else if (lightPieces == 0 ||
        (turn == Side.light && lightMoves.isEmpty)) {
      winner = Side.dark;
    }
  }

  int _countPieces(Side side) {
    var n = 0;
    for (final row in board) {
      for (final p in row) {
        if (side.owns(p)) n++;
      }
    }
    return n;
  }

  List<CheckersMove> _quietMovesFrom(Square from, Piece piece) {
    final moves = <CheckersMove>[];
    for (final dir in _moveDirs(piece)) {
      final to = Square(from.row + dir.$1, from.col + dir.$2);
      if (!to.isOnBoard || !to.isDarkSquare) continue;
      if (!pieceAt(to).isEmpty) continue;
      moves.add(CheckersMove(from: from, path: [to], captured: const []));
    }
    return moves;
  }

  /// Depth-first collection of complete capture sequences.
  List<CheckersMove> _capturesFrom(
    Square from,
    Piece piece,
    List<Square> alreadyCaptured,
  ) {
    final results = <CheckersMove>[];
    var foundAny = false;

    for (final dir in _captureDirs(piece)) {
      final mid = Square(from.row + dir.$1, from.col + dir.$2);
      final land = Square(from.row + dir.$1 * 2, from.col + dir.$2 * 2);
      if (!mid.isOnBoard || !land.isOnBoard) continue;
      if (!land.isDarkSquare) continue;
      if (!pieceAt(land).isEmpty) continue;
      if (alreadyCaptured.contains(mid)) continue;

      final victim = pieceAt(mid);
      if (victim.isEmpty) continue;
      if (piece.isDark && !victim.isLight) continue;
      if (piece.isLight && !victim.isDark) continue;

      foundAny = true;
      final nextCaptured = [...alreadyCaptured, mid];

      // Temporarily apply for further jumps.
      final savedFrom = pieceAt(from);
      final savedMid = pieceAt(mid);
      setPiece(from, Piece.empty);
      setPiece(mid, Piece.empty);

      var flying = piece;
      var promotedThisJump = false;
      if (!flying.isKing) {
        if (flying.isDark && land.row == 0) {
          flying = flying.promote();
          promotedThisJump = true;
        } else if (flying.isLight && land.row == 7) {
          flying = flying.promote();
          promotedThisJump = true;
        }
      }
      setPiece(land, flying);

      // American rules: crowning ends the multi-jump.
      final List<CheckersMove> further;
      if (promotedThisJump) {
        further = const [];
      } else {
        further = _capturesFrom(land, flying, nextCaptured);
      }

      setPiece(from, savedFrom);
      setPiece(mid, savedMid);
      setPiece(land, Piece.empty);

      if (further.isEmpty) {
        results.add(
          CheckersMove(
            from: from,
            path: [land],
            captured: nextCaptured,
          ),
        );
      } else {
        for (final cont in further) {
          results.add(
            CheckersMove(
              from: from,
              path: [land, ...cont.path],
              captured: cont.captured,
            ),
          );
        }
      }
    }

    if (!foundAny && alreadyCaptured.isNotEmpty) {
      // Should not normally be called; parent builds leaf.
    }
    return results;
  }

  List<(int, int)> _moveDirs(Piece piece) {
    if (piece.isKing) {
      return const [(-1, -1), (-1, 1), (1, -1), (1, 1)];
    }
    if (piece.isDark) {
      return const [(-1, -1), (-1, 1)]; // toward row 0
    }
    return const [(1, -1), (1, 1)]; // toward row 7
  }

  List<(int, int)> _captureDirs(Piece piece) {
    // American checkers: men capture forward only; kings both ways.
    return _moveDirs(piece);
  }
}
