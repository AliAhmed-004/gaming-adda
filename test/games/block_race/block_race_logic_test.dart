import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/block_race/block_race_logic.dart';

void main() {
  group('BlockRaceGame paths', () {
    test('blue and red start at opposite sides', () {
      final game = BlockRaceGame();
      expect(game.bluePathIndex, 0);
      expect(game.redPathIndex, 0);
      expect(game.pawnCell(BlockRacePlayer.blue), BlockRaceGame.bluePath.first);
      expect(game.pawnCell(BlockRacePlayer.red), BlockRaceGame.redPath.first);
    });

    test('paths meet at center cell', () {
      const center =
          BlockRaceCell(row: 3, col: 3, kind: BlockRaceCellKind.path);
      expect(BlockRaceGame.bluePath[3], center);
      expect(BlockRaceGame.redPath[3], center);
    });
  });

  group('BlockRaceGame movement', () {
    test('pawn advances along path after roll', () {
      final game = BlockRaceGame(random: _SeqRandom([2]));
      game.startGame();
      game.diceValue = 2;
      game.handleRollComplete();

      final result = game.applyMove();
      expect(result, isNotNull);
      expect(result!.toIndex, 2);
      expect(game.bluePathIndex, 2);
    });

    test('barricade blocks further movement', () {
      final game = BlockRaceGame(random: _SeqRandom([3]));
      game.startGame();
      game.barricades.add(BlockRaceGame.bluePath[2]);
      game.diceValue = 3;
      game.handleRollComplete();

      final result = game.applyMove();
      expect(result, isNotNull);
      expect(result!.toIndex, 1);
    });

    test('reaching goal ends game', () {
      final game = BlockRaceGame(random: _SeqRandom([6]));
      game.startGame();
      game.bluePathIndex = 5;
      game.diceValue = 1;
      game.handleRollComplete();

      final result = game.applyMove();
      expect(result!.won, isTrue);
      expect(game.winner, BlockRacePlayer.blue);
      expect(game.phase, BlockRacePhase.gameOver);
    });

    test('capture sends opponent back to start', () {
      final game = BlockRaceGame(random: _SeqRandom([3]));
      game.startGame();
      game.redPathIndex = 3;
      game.diceValue = 3;
      game.handleRollComplete();

      final result = game.applyMove();
      expect(result!.capturedOpponent, isTrue);
      expect(game.redPathIndex, 0);
    });
  });

  group('BlockRaceGame barricades', () {
    test('valid barricade cells exclude goals and occupied tiles', () {
      final game = BlockRaceGame();
      game.startGame();
      final valid = game.validBarricadeCells();
      expect(valid.any((c) => c.isGoal), isFalse);
      expect(valid.contains(BlockRaceGame.bluePath.first), isFalse);
      expect(valid.contains(BlockRaceGame.redPath.first), isFalse);
    });

    test('placing barricade consumes stock', () {
      final game = BlockRaceGame();
      game.startGame();
      game.phase = BlockRacePhase.placingBarricade;
      final cell = BlockRaceGame.bluePath[1];
      expect(game.placeBarricade(cell), isTrue);
      expect(game.blueBarricadesLeft, BlockRaceGame.maxBarricades - 1);
      expect(game.barricades.contains(cell), isTrue);
    });
  });
}

class _SeqRandom implements Random {
  _SeqRandom(this.values);

  final List<int> values;
  var _index = 0;

  @override
  int nextInt(int max) {
    final value = values[_index.clamp(0, values.length - 1)];
    _index++;
    return (value - 1).clamp(0, max - 1);
  }

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;
}
