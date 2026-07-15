import 'dart:math';

enum LudoColor { red, green, yellow, blue }

extension LudoColorX on LudoColor {
  String get label => switch (this) {
    LudoColor.red => 'Red',
    LudoColor.green => 'Green',
    LudoColor.yellow => 'Yellow',
    LudoColor.blue => 'Blue',
  };

  /// Global track index where this color enters from the yard.
  int get startIndex => switch (this) {
    LudoColor.red => 0,
    LudoColor.green => 13,
    LudoColor.yellow => 26,
    LudoColor.blue => 39,
  };

  /// Global track index just before entering this color's home stretch.
  int get homeEntranceIndex => switch (this) {
    LudoColor.red => 50,
    LudoColor.green => 11,
    LudoColor.yellow => 24,
    LudoColor.blue => 37,
  };
}

/// Active seats for [playerCount]: classic opposite for 2, consecutive for 3.
List<LudoColor> activeColorsForPlayerCount(int playerCount) {
  switch (playerCount) {
    case 2:
      return const [LudoColor.red, LudoColor.yellow];
    case 3:
      return const [LudoColor.red, LudoColor.green, LudoColor.yellow];
    case 4:
      return const [
        LudoColor.red,
        LudoColor.green,
        LudoColor.yellow,
        LudoColor.blue,
      ];
    default:
      throw ArgumentError.value(
        playerCount,
        'playerCount',
        'Must be 2, 3, or 4',
      );
  }
}

/// Progress of a token: -1 yard, 0..50 main track (steps from start),
/// 51..55 home stretch, 56 finished.
class LudoToken {
  const LudoToken({required this.color, required this.id, this.progress = -1});

  final LudoColor color;
  final int id;
  final int progress;

  bool get inYard => progress < 0;
  bool get isFinished => progress >= LudoGame.finishedProgress;
  bool get onHomeStretch =>
      progress >= LudoGame.homeStretchStart &&
      progress < LudoGame.finishedProgress;
  bool get onTrack => progress >= 0 && progress < LudoGame.homeStretchStart;

  LudoToken copyWith({int? progress}) =>
      LudoToken(color: color, id: id, progress: progress ?? this.progress);

  /// Global 0..51 when on the shared track; null otherwise.
  int? get globalIndex {
    if (!onTrack) return null;
    return (color.startIndex + progress) % LudoGame.trackLength;
  }
}

class LudoMove {
  const LudoMove({
    required this.color,
    required this.tokenId,
    required this.fromProgress,
    required this.toProgress,
    this.capturedTokenId,
    this.capturedColor,
  });

  final LudoColor color;
  final int tokenId;
  final int fromProgress;
  final int toProgress;
  final int? capturedTokenId;
  final LudoColor? capturedColor;

  bool get isCapture => capturedTokenId != null;
  bool get entersBoard => fromProgress < 0 && toProgress == 0;
  bool get finishes => toProgress >= LudoGame.finishedProgress;
}

class LudoGame {
  LudoGame({this.playerCount = 4, Random? random})
    : _random = random ?? Random() {
    reset();
  }

  static const trackLength = 52;
  static const homeStretchStart = 51;
  static const finishedProgress = 56;
  static const tokensPerPlayer = 4;
  static const maxConsecutiveSixes = 3;

  /// Global track indices that are always safe (starts + star squares).
  static const safeGlobalIndices = <int>{0, 8, 13, 21, 26, 34, 39, 47};

  final int playerCount;
  final Random _random;

  late List<LudoColor> activeColors;
  late Map<LudoColor, List<LudoToken>> tokensByColor;
  late LudoColor turn;
  LudoColor? winner;

  int? pendingRoll;
  int consecutiveSixes = 0;

  void reset() {
    activeColors = activeColorsForPlayerCount(playerCount);
    tokensByColor = {
      for (final c in activeColors)
        c: List.generate(tokensPerPlayer, (i) => LudoToken(color: c, id: i)),
    };
    turn = activeColors.first;
    winner = null;
    pendingRoll = null;
    consecutiveSixes = 0;
  }

  List<LudoToken> tokensFor(LudoColor color) =>
      tokensByColor[color] ?? const [];

  LudoToken token(LudoColor color, int id) =>
      tokensByColor[color]!.firstWhere((t) => t.id == id);

  bool isSafeGlobal(int global) => safeGlobalIndices.contains(global);

  /// Roll the die. Requires no pending roll and no winner.
  int rollDie() {
    if (winner != null) {
      throw StateError('Game already finished');
    }
    if (pendingRoll != null) {
      throw StateError('Must resolve current roll first');
    }
    final roll = _random.nextInt(6) + 1;
    pendingRoll = roll;

    if (roll == 6) {
      consecutiveSixes += 1;
      if (consecutiveSixes >= maxConsecutiveSixes) {
        // Three sixes in a row: forfeit the turn (discard roll).
        pendingRoll = null;
        consecutiveSixes = 0;
        _advanceTurn();
        return roll;
      }
    }

    final moves = legalMoves(turn, roll);
    if (moves.isEmpty) {
      pendingRoll = null;
      if (roll != 6) {
        consecutiveSixes = 0;
        _advanceTurn();
      }
      // Rolled 6 with no moves: keep turn, allow another roll.
    }
    return roll;
  }

  /// Force a specific roll (tests / deterministic play). Same rules as [rollDie].
  int setRoll(int roll) {
    if (roll < 1 || roll > 6) {
      throw ArgumentError.value(roll, 'roll', 'Must be 1–6');
    }
    if (winner != null) {
      throw StateError('Game already finished');
    }
    if (pendingRoll != null) {
      throw StateError('Must resolve current roll first');
    }
    pendingRoll = roll;

    if (roll == 6) {
      consecutiveSixes += 1;
      if (consecutiveSixes >= maxConsecutiveSixes) {
        pendingRoll = null;
        consecutiveSixes = 0;
        _advanceTurn();
        return roll;
      }
    }

    final moves = legalMoves(turn, roll);
    if (moves.isEmpty) {
      pendingRoll = null;
      if (roll != 6) {
        consecutiveSixes = 0;
        _advanceTurn();
      }
    }
    return roll;
  }

  List<LudoMove> legalMovesForCurrentRoll() {
    final roll = pendingRoll;
    if (roll == null) return const [];
    return legalMoves(turn, roll);
  }

  List<LudoMove> legalMoves(LudoColor color, int roll) {
    final result = <LudoMove>[];
    for (final t in tokensFor(color)) {
      final move = _moveForToken(t, roll);
      if (move != null) result.add(move);
    }
    return result;
  }

  LudoMove? _moveForToken(LudoToken t, int roll) {
    if (t.isFinished) return null;

    if (t.inYard) {
      if (roll != 6) return null;
      final capture = _captureAtGlobal(t.color, t.color.startIndex);
      return LudoMove(
        color: t.color,
        tokenId: t.id,
        fromProgress: -1,
        toProgress: 0,
        capturedTokenId: capture?.id,
        capturedColor: capture?.color,
      );
    }

    final to = t.progress + roll;
    if (to > finishedProgress) return null;

    // Blocked by own token on destination (except finished).
    if (to < finishedProgress && _ownTokenAt(t.color, to, excludeId: t.id)) {
      return null;
    }

    int? capturedId;
    LudoColor? capturedColor;
    if (to < homeStretchStart) {
      final global = (t.color.startIndex + to) % trackLength;
      final capture = _captureAtGlobal(t.color, global);
      capturedId = capture?.id;
      capturedColor = capture?.color;
    }

    return LudoMove(
      color: t.color,
      tokenId: t.id,
      fromProgress: t.progress,
      toProgress: to,
      capturedTokenId: capturedId,
      capturedColor: capturedColor,
    );
  }

  bool _ownTokenAt(LudoColor color, int progress, {required int excludeId}) {
    return tokensFor(
      color,
    ).any((o) => o.id != excludeId && o.progress == progress && !o.isFinished);
  }

  LudoToken? _captureAtGlobal(LudoColor mover, int global) {
    if (isSafeGlobal(global)) return null;
    for (final color in activeColors) {
      if (color == mover) continue;
      for (final t in tokensFor(color)) {
        if (t.globalIndex == global) return t;
      }
    }
    return null;
  }

  /// Apply a legal move for the current pending roll.
  void applyMove(LudoMove move) {
    if (winner != null) {
      throw StateError('Game already finished');
    }
    final roll = pendingRoll;
    if (roll == null) {
      throw StateError('No pending roll');
    }
    if (move.color != turn) {
      throw StateError('Not this color\'s turn');
    }
    final legal = legalMoves(turn, roll);
    final match = legal.any(
      (m) =>
          m.tokenId == move.tokenId &&
          m.toProgress == move.toProgress &&
          m.fromProgress == move.fromProgress,
    );
    if (!match) {
      throw StateError('Illegal move');
    }

    final list = tokensByColor[move.color]!;
    final idx = list.indexWhere((t) => t.id == move.tokenId);
    list[idx] = list[idx].copyWith(progress: move.toProgress);

    if (move.isCapture) {
      final victims = tokensByColor[move.capturedColor!]!;
      final vIdx = victims.indexWhere((t) => t.id == move.capturedTokenId);
      victims[vIdx] = victims[vIdx].copyWith(progress: -1);
    }

    pendingRoll = null;

    if (tokensFor(move.color).every((t) => t.isFinished)) {
      winner = move.color;
      consecutiveSixes = 0;
      return;
    }

    final extraTurn = roll == 6 || move.isCapture || move.finishes;
    if (!extraTurn) {
      consecutiveSixes = 0;
      _advanceTurn();
    } else if (roll != 6) {
      // Capture / finish without a 6: keep turn, reset six streak.
      consecutiveSixes = 0;
    }
  }

  void _advanceTurn() {
    final i = activeColors.indexOf(turn);
    turn = activeColors[(i + 1) % activeColors.length];
  }

  /// Tokens currently sitting on a global track square (any color).
  List<LudoToken> tokensAtGlobal(int global) {
    final out = <LudoToken>[];
    for (final color in activeColors) {
      for (final t in tokensFor(color)) {
        if (t.globalIndex == global) out.add(t);
      }
    }
    return out;
  }
}
