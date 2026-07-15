import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/penguin_brothers/levels/level_defs.dart';
import 'package:gaming_adda/games/penguin_brothers/penguin_config.dart';
import 'package:gaming_adda/games/penguin_brothers/penguin_logic.dart';

void main() {
  group('BombRules.blastCells', () {
    test('includes origin and orthogonal arms', () {
      final cells = BombRules.blastCells(5, 5, 1);
      expect(cells.contains((5, 5)), isTrue);
      expect(cells.contains((6, 5)), isTrue);
      expect(cells.contains((4, 5)), isTrue);
      expect(cells.contains((5, 6)), isTrue);
      expect(cells.contains((5, 4)), isTrue);
      expect(cells.contains((6, 6)), isFalse);
      expect(cells.length, 5);
    });

    test('radius 2 extends further', () {
      final cells = BombRules.blastCells(0, 0, 2);
      expect(cells.contains((2, 0)), isTrue);
      expect(cells.contains((0, 2)), isTrue);
      expect(cells.length, 9);
    });
  });

  group('StageProgress', () {
    test('spawns key after wave cleared', () {
      final p = StageProgress(wave1EnemyCount: 2)..enemiesRemaining = 2;
      expect(p.shouldSpawnKey, isFalse);
      p.onEnemyDefeated();
      expect(p.shouldSpawnKey, isFalse);
      p.onEnemyDefeated();
      expect(p.shouldSpawnKey, isTrue);
      p.markKeySpawned();
      expect(p.phase, StagePhase.keyAvailable);
    });

    test('exit opens after key collected', () {
      final p = StageProgress(wave1EnemyCount: 0)..enemiesRemaining = 0;
      p.markKeySpawned();
      p.onKeyCollected();
      expect(p.exitOpen, isTrue);
      expect(p.phase, StagePhase.exiting);
    });

    test('boss must die before key', () {
      final p = StageProgress(wave1EnemyCount: 0, hasBoss: true)
        ..enemiesRemaining = 0;
      expect(p.shouldSpawnKey, isFalse);
      expect(p.phase, StagePhase.bossFight);
      p.onBossDefeated();
      expect(p.shouldSpawnKey, isTrue);
    });

    test('post-key wave flags', () {
      final p = StageProgress(wave1EnemyCount: 0, postKeyEnemyCount: 2)
        ..enemiesRemaining = 0;
      p.markKeySpawned();
      p.onKeyCollected();
      expect(p.shouldSpawnPostKeyWave, isTrue);
      p.markPostKeySpawned(2);
      expect(p.enemiesRemaining, 2);
      expect(p.shouldSpawnPostKeyWave, isFalse);
    });
  });

  group('levels', () {
    test('all five stages are rectangular', () {
      expect(penguinLevels.length, 5);
      for (final level in penguinLevels) {
        final w = level.width;
        expect(level.height, greaterThan(0));
        for (final row in level.rows) {
          expect(row.length, w);
        }
        expect(level.rows.any((r) => r.contains('1')), isTrue);
        expect(level.rows.any((r) => r.contains('X')), isTrue);
      }
      expect(penguinLevels.last.hasBoss, isTrue);
    });
  });

  group('config', () {
    test('ai partner flag', () {
      expect(const PenguinConfig().hasAiPartner, isFalse);
      expect(
        const PenguinConfig(mode: PenguinPlayMode.aiPartner).hasAiPartner,
        isTrue,
      );
    });
  });

  test('scoring helpers', () {
    expect(scoreForEnemyKill(1), 100);
    expect(scoreForEnemyKill(3), 300);
  });
}
