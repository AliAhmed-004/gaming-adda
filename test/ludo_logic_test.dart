import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/ludo/ludo_ai.dart';
import 'package:gaming_adda/games/ludo/ludo_logic.dart';

void main() {
  test('active seats: 2 opposite, 3 consecutive, 4 all', () {
    expect(activeColorsForPlayerCount(2), [LudoColor.red, LudoColor.yellow]);
    expect(activeColorsForPlayerCount(3), [
      LudoColor.red,
      LudoColor.green,
      LudoColor.yellow,
    ]);
    expect(activeColorsForPlayerCount(4).length, 4);
  });

  test('enter board only on a 6', () {
    final game = LudoGame(playerCount: 2);
    expect(game.turn, LudoColor.red);

    game.setRoll(4);
    expect(game.pendingRoll, isNull);
    expect(game.turn, LudoColor.yellow);

    game.setRoll(6);
    final moves = game.legalMovesForCurrentRoll();
    expect(moves.length, 4);
    expect(moves.every((m) => m.entersBoard), isTrue);

    game.applyMove(moves.first);
    expect(game.token(LudoColor.yellow, moves.first.tokenId).progress, 0);
    expect(game.pendingRoll, isNull);
    // Extra turn after 6.
    expect(game.turn, LudoColor.yellow);
  });

  test('move along track and block illegal overshoot into home', () {
    final game = LudoGame(playerCount: 2);
    final list = game.tokensByColor[LudoColor.red]!;
    list[0] = list[0].copyWith(progress: 54);
    game.turn = LudoColor.red;

    game.setRoll(3);
    expect(game.legalMovesForCurrentRoll(), isEmpty);
    expect(game.turn, LudoColor.yellow);

    game.turn = LudoColor.red;
    game.setRoll(2);
    final moves = game.legalMovesForCurrentRoll();
    expect(moves.single.toProgress, LudoGame.finishedProgress);
    game.applyMove(moves.single);
    expect(game.token(LudoColor.red, 0).isFinished, isTrue);
  });

  test('safe squares do not capture; unsafe do', () {
    final game = LudoGame(playerCount: 4);
    // Place yellow on red start (global 0) — safe, no capture on enter.
    final yellow = game.tokensByColor[LudoColor.yellow]!;
    yellow[0] = yellow[0].copyWith(
      progress: 26,
    ); // (26+26)%52=0? start 26, progress 26 -> (26+26)%52=0
    // Actually (26 + 26) % 52 = 0. Yes on red start.
    expect(yellow[0].globalIndex, 0);
    expect(game.isSafeGlobal(0), isTrue);

    game.turn = LudoColor.red;
    game.setRoll(6);
    final enter = game.legalMovesForCurrentRoll().first;
    expect(enter.isCapture, isFalse);
    game.applyMove(enter);
    expect(game.token(LudoColor.yellow, 0).inYard, isFalse);

    // Opponent on unsafe square in front of red.
    // Red token at progress 0 (global 0). Place green at global 3.
    // green start 13, want (13+p)%52=3 => p=42.
    final green = game.tokensByColor[LudoColor.green]!;
    green[0] = green[0].copyWith(progress: 42);
    expect(green[0].globalIndex, 3);
    expect(game.isSafeGlobal(3), isFalse);

    game.turn = LudoColor.red;
    game.setRoll(3);
    final captureMoves = game
        .legalMovesForCurrentRoll()
        .where((m) => m.tokenId == enter.tokenId)
        .toList();
    expect(captureMoves, isNotEmpty);
    expect(captureMoves.single.isCapture, isTrue);
    game.applyMove(captureMoves.single);
    expect(game.token(LudoColor.green, 0).inYard, isTrue);
    // Capture grants extra turn.
    expect(game.turn, LudoColor.red);
  });

  test('exact finish and first to home all four wins', () {
    final game = LudoGame(playerCount: 2);
    final red = game.tokensByColor[LudoColor.red]!;
    for (var i = 0; i < 3; i++) {
      red[i] = red[i].copyWith(progress: LudoGame.finishedProgress);
    }
    red[3] = red[3].copyWith(progress: 55);
    game.turn = LudoColor.red;
    game.setRoll(1);
    final move = game.legalMovesForCurrentRoll().single;
    game.applyMove(move);
    expect(game.winner, LudoColor.red);
  });

  test('three consecutive sixes forfeit the turn', () {
    final game = LudoGame(playerCount: 2);
    // Need at least one token out so rolling 6 always has a move
    // (otherwise empty move path differs). Put red token on track.
    final red = game.tokensByColor[LudoColor.red]!;
    red[0] = red[0].copyWith(progress: 0);
    game.turn = LudoColor.red;

    game.setRoll(6);
    expect(game.pendingRoll, 6);
    game.applyMove(game.legalMovesForCurrentRoll().first);
    expect(game.turn, LudoColor.red);

    game.setRoll(6);
    expect(game.pendingRoll, 6);
    game.applyMove(game.legalMovesForCurrentRoll().first);
    expect(game.turn, LudoColor.red);

    // Third six: forfeit without applying a move.
    game.setRoll(6);
    expect(game.pendingRoll, isNull);
    expect(game.turn, LudoColor.yellow);
  });

  test('AI chooses a legal move for current roll', () {
    final game = LudoGame(playerCount: 2);
    game.setRoll(6);
    // Red has pending 6 with enter moves
    expect(game.turn, LudoColor.red);
    final ai = LudoAi();
    final choice = ai.chooseMove(game);
    expect(choice, isNotNull);
    expect(
      game.legalMovesForCurrentRoll().any(
        (m) =>
            m.tokenId == choice!.tokenId && m.toProgress == choice.toProgress,
      ),
      isTrue,
    );
  });
}
