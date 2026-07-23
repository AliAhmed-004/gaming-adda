import 'dart:math' as math;

enum BlockRacePlayer { blue, red }

enum BlockRacePhase {
  ready,
  rolling,
  moving,
  placingBarricade,
  animating,
  gameOver,
}

enum BlockRaceCellKind { empty, path, blueGoal, redGoal }

class BlockRaceCell {
  const BlockRaceCell({
    required this.row,
    required this.col,
    required this.kind,
  });

  final int row;
  final int col;
  final BlockRaceCellKind kind;

  bool get isPath =>
      kind == BlockRaceCellKind.path ||
      kind == BlockRaceCellKind.blueGoal ||
      kind == BlockRaceCellKind.redGoal;

  bool get isGoal =>
      kind == BlockRaceCellKind.blueGoal || kind == BlockRaceCellKind.redGoal;

  @override
  bool operator ==(Object other) =>
      other is BlockRaceCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

class BlockRaceMoveResult {
  const BlockRaceMoveResult({
    required this.fromIndex,
    required this.toIndex,
    required this.capturedOpponent,
    required this.won,
  });

  final int fromIndex;
  final int toIndex;
  final bool capturedOpponent;
  final bool won;
}

class BlockRaceGame {
  BlockRaceGame({math.Random? random}) : _random = random ?? math.Random();

  static const boardRows = 7;
  static const boardCols = 7;
  static const maxBarricades = 3;
  static const goalIndex = 6;

  static const List<BlockRaceCell> bluePath = [
    BlockRaceCell(row: 3, col: 0, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 3, col: 1, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 3, col: 2, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 3, col: 3, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 2, col: 3, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 1, col: 3, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 0, col: 3, kind: BlockRaceCellKind.blueGoal),
  ];

  static const List<BlockRaceCell> redPath = [
    BlockRaceCell(row: 3, col: 6, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 3, col: 5, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 3, col: 4, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 3, col: 3, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 4, col: 3, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 5, col: 3, kind: BlockRaceCellKind.path),
    BlockRaceCell(row: 6, col: 3, kind: BlockRaceCellKind.redGoal),
  ];

  final math.Random _random;

  BlockRacePhase phase = BlockRacePhase.ready;
  BlockRacePlayer currentPlayer = BlockRacePlayer.blue;
  BlockRacePlayer? winner;

  int bluePathIndex = 0;
  int redPathIndex = 0;
  int diceValue = 1;

  final Set<BlockRaceCell> barricades = {};
  int blueBarricadesLeft = maxBarricades;
  int redBarricadesLeft = maxBarricades;

  String get statusMessage {
    if (winner != null) {
      return '${_playerLabel(winner!)} wins!';
    }
    return switch (phase) {
      BlockRacePhase.ready => 'Tap Roll to begin',
      BlockRacePhase.rolling => '${_playerLabel(currentPlayer)}\'s turn — roll the dice',
      BlockRacePhase.moving =>
        'Rolled $diceValue — ${_canCurrentPlayerMove() ? "moving pawn" : "no legal move"}',
      BlockRacePhase.placingBarricade =>
        'Place a barricade or skip',
      BlockRacePhase.animating => '...',
      BlockRacePhase.gameOver => '${_playerLabel(winner!)} wins!',
    };
  }

  static String _playerLabel(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? 'Blue' : 'Red';

  static List<BlockRaceCell> pathFor(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? bluePath : redPath;

  static BlockRaceCell cellAt(int row, int col) {
    for (final cell in bluePath) {
      if (cell.row == row && cell.col == col) return cell;
    }
    for (final cell in redPath) {
      if (cell.row == row && cell.col == col) return cell;
    }
    return BlockRaceCell(row: row, col: col, kind: BlockRaceCellKind.empty);
  }

  BlockRaceCell pawnCell(BlockRacePlayer player) {
    final index = player == BlockRacePlayer.blue ? bluePathIndex : redPathIndex;
    return pathFor(player)[index];
  }

  int pathIndexFor(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? bluePathIndex : redPathIndex;

  int barricadesLeftFor(BlockRacePlayer player) =>
      player == BlockRacePlayer.blue ? blueBarricadesLeft : redBarricadesLeft;

  bool isBarricadeAt(int row, int col) =>
      barricades.contains(BlockRaceCell(row: row, col: col, kind: BlockRaceCellKind.path));

  bool _isBlocked(BlockRaceCell cell) {
    if (cell.isGoal) return false;
    return barricades.contains(cell) ||
        barricades.contains(
          BlockRaceCell(row: cell.row, col: cell.col, kind: BlockRaceCellKind.path),
        );
  }

  bool _cellHasOpponent(BlockRaceCell cell, BlockRacePlayer mover) {
    final opponent =
        mover == BlockRacePlayer.blue ? BlockRacePlayer.red : BlockRacePlayer.blue;
    final opponentCell = pawnCell(opponent);
    return opponentCell.row == cell.row && opponentCell.col == cell.col;
  }

  int? _maxReachableIndex(BlockRacePlayer player, int steps) {
    final path = pathFor(player);
    final start = pathIndexFor(player);
    if (start >= goalIndex) return null;

    var reachable = start;
    for (var step = 1; step <= steps; step++) {
      final next = start + step;
      if (next > goalIndex) break;

      final cell = path[next];
      if (next < goalIndex && _isBlocked(cell)) break;

      reachable = next;
      if (next == goalIndex) break;
    }

    return reachable > start ? reachable : null;
  }

  bool _canCurrentPlayerMove() =>
      _maxReachableIndex(currentPlayer, diceValue) != null;

  bool canPlaceBarricade() =>
      barricadesLeftFor(currentPlayer) > 0 && validBarricadeCells().isNotEmpty;

  List<BlockRaceCell> validBarricadeCells() {
    final cells = <BlockRaceCell>[];
    for (final path in [bluePath, redPath]) {
      for (final cell in path) {
        if (cell.isGoal) continue;
        if (barricades.contains(cell)) continue;
        if (pawnCell(BlockRacePlayer.blue) == cell) continue;
        if (pawnCell(BlockRacePlayer.red) == cell) continue;
        cells.add(cell);
      }
    }
    return cells;
  }

  int rollDice() {
    diceValue = _random.nextInt(6) + 1;
    return diceValue;
  }

  void beginTurn() {
    winner = null;
    phase = BlockRacePhase.rolling;
  }

  void startGame() {
    bluePathIndex = 0;
    redPathIndex = 0;
    barricades.clear();
    blueBarricadesLeft = maxBarricades;
    redBarricadesLeft = maxBarricades;
    currentPlayer = BlockRacePlayer.blue;
    winner = null;
    diceValue = 1;
    phase = BlockRacePhase.rolling;
  }

  BlockRaceMoveResult? applyMove() {
    if (phase != BlockRacePhase.moving && phase != BlockRacePhase.rolling) {
      return null;
    }

    final target = _maxReachableIndex(currentPlayer, diceValue);
    if (target == null) {
      _endTurnWithoutBarricade();
      return null;
    }

    final fromIndex = pathIndexFor(currentPlayer);
    final path = pathFor(currentPlayer);
    final destination = path[target];

    var captured = false;
    if (_cellHasOpponent(destination, currentPlayer)) {
      if (currentPlayer == BlockRacePlayer.blue) {
        redPathIndex = 0;
      } else {
        bluePathIndex = 0;
      }
      captured = true;
    }

    if (currentPlayer == BlockRacePlayer.blue) {
      bluePathIndex = target;
    } else {
      redPathIndex = target;
    }

    final won = target == goalIndex;
    if (won) {
      winner = currentPlayer;
      phase = BlockRacePhase.gameOver;
      return BlockRaceMoveResult(
        fromIndex: fromIndex,
        toIndex: target,
        capturedOpponent: captured,
        won: true,
      );
    }

    phase = canPlaceBarricade()
        ? BlockRacePhase.placingBarricade
        : BlockRacePhase.animating;

    return BlockRaceMoveResult(
      fromIndex: fromIndex,
      toIndex: target,
      capturedOpponent: captured,
      won: false,
    );
  }

  bool placeBarricade(BlockRaceCell cell) {
    if (phase != BlockRacePhase.placingBarricade) return false;
    if (!validBarricadeCells().contains(cell)) return false;

    barricades.add(cell);
    if (currentPlayer == BlockRacePlayer.blue) {
      blueBarricadesLeft--;
    } else {
      redBarricadesLeft--;
    }
    phase = BlockRacePhase.animating;
    return true;
  }

  void skipBarricade() {
    if (phase != BlockRacePhase.placingBarricade) return;
    phase = BlockRacePhase.animating;
  }

  void finishAnimations() {
    if (phase != BlockRacePhase.animating) return;
    _advancePlayer();
  }

  void _endTurnWithoutBarricade() {
    phase = BlockRacePhase.animating;
  }

  void _advancePlayer() {
    if (winner != null) {
      phase = BlockRacePhase.gameOver;
      return;
    }

    currentPlayer = currentPlayer == BlockRacePlayer.blue
        ? BlockRacePlayer.red
        : BlockRacePlayer.blue;
    phase = BlockRacePhase.rolling;
  }

  void handleRollComplete() {
    if (phase != BlockRacePhase.rolling) return;
    phase = BlockRacePhase.moving;
  }
}
