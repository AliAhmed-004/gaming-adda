import 'dart:math';

import 'block_race_config.dart';
import 'block_race_logic.dart';

class BlockRaceAi {
  BlockRaceAi({
    BlockRaceAiDifficulty difficulty = BlockRaceAiDifficulty.medium,
    Random? random,
  })  : _difficulty = difficulty,
        _random = random ?? Random();

  final BlockRaceAiDifficulty _difficulty;
  final Random _random;

  BlockRaceMoveResult? chooseMove(BlockRaceGame game) {
    if (!_shouldPlayOptimally()) {
      final reachable = game.diceValue;
      if (game.pathIndexFor(BlockRacePlayer.red) + reachable > BlockRaceGame.goalIndex) {
        return game.applyMove();
      }
    }
    return game.applyMove();
  }

  BlockRaceCell? chooseBarricade(BlockRaceGame game) {
    if (!game.canPlaceBarricade()) return null;
    if (!_shouldPlaceBarricade()) return null;

    final valid = game.validBarricadeCells();
    if (valid.isEmpty) return null;

    final blueIndex = game.pathIndexFor(BlockRacePlayer.blue);
    if (blueIndex >= BlockRaceGame.goalIndex) return null;

    final bluePath = BlockRaceGame.pathFor(BlockRacePlayer.blue);
    final lookAhead = min(blueIndex + game.diceValue + 1, BlockRaceGame.goalIndex);
    for (var i = lookAhead; i > blueIndex; i--) {
      final cell = bluePath[i];
      if (valid.contains(cell)) return cell;
    }

    if (_difficulty == BlockRaceAiDifficulty.easy) {
      return valid[_random.nextInt(valid.length)];
    }

    final center = const BlockRaceCell(row: 3, col: 3, kind: BlockRaceCellKind.path);
    if (valid.contains(center)) return center;

    return valid[_random.nextInt(valid.length)];
  }

  bool _shouldPlayOptimally() {
    return switch (_difficulty) {
      BlockRaceAiDifficulty.easy => _random.nextDouble() > 0.35,
      BlockRaceAiDifficulty.medium => _random.nextDouble() > 0.15,
      BlockRaceAiDifficulty.hard => true,
    };
  }

  bool _shouldPlaceBarricade() {
    return switch (_difficulty) {
      BlockRaceAiDifficulty.easy => _random.nextBool(),
      BlockRaceAiDifficulty.medium => _random.nextDouble() > 0.25,
      BlockRaceAiDifficulty.hard => true,
    };
  }
}
