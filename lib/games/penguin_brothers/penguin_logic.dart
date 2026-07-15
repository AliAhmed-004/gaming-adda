// Pure rules helpers for Penguin Brothers (no Flutter / Flame).

enum StagePhase { clearing, keyAvailable, exiting, bossFight, cleared }

enum EnemyKind { chaser, fireSpitter, skittish }

enum PowerUpKind { longRange, invincibilityFish, speedSkates }

enum TileKind { empty, wall, ground, platform, breakable }

class BombRules {
  const BombRules({this.fuseSeconds = 1.4, this.radiusTiles = 1});

  final double fuseSeconds;
  final int radiusTiles;

  BombRules get longRange =>
      BombRules(fuseSeconds: fuseSeconds + 0.4, radiusTiles: radiusTiles + 1);

  /// Orthogonal blast (cross) including origin.
  static Set<(int, int)> blastCells(int col, int row, int radius) {
    final cells = <(int, int)>{(col, row)};
    for (var i = 1; i <= radius; i++) {
      cells.add((col + i, row));
      cells.add((col - i, row));
      cells.add((col, row + i));
      cells.add((col, row - i));
    }
    return cells;
  }
}

class StageProgress {
  StageProgress({
    required this.wave1EnemyCount,
    this.hasBoss = false,
    this.postKeyEnemyCount = 0,
  }) : enemiesRemaining = wave1EnemyCount {
    _recompute();
  }

  final int wave1EnemyCount;
  final bool hasBoss;
  final int postKeyEnemyCount;

  int enemiesRemaining;
  bool keySpawned = false;
  bool keyCollected = false;
  bool postKeySpawned = false;
  bool bossDefeated = false;
  StagePhase phase = StagePhase.clearing;

  void onEnemyDefeated() {
    if (enemiesRemaining > 0) enemiesRemaining--;
    _recompute();
  }

  void onBossDefeated() {
    bossDefeated = true;
    _recompute();
  }

  void onKeyCollected() {
    keyCollected = true;
    _recompute();
  }

  void markKeySpawned() => keySpawned = true;

  void markPostKeySpawned(int count) {
    postKeySpawned = true;
    enemiesRemaining += count;
    _recompute();
  }

  void _recompute() {
    if (hasBoss && !bossDefeated) {
      phase = StagePhase.bossFight;
      return;
    }
    if (!keySpawned && enemiesRemaining <= 0 && (!hasBoss || bossDefeated)) {
      phase = StagePhase.keyAvailable;
      return;
    }
    if (keyCollected) {
      phase = StagePhase.exiting;
      return;
    }
    if (keySpawned) {
      phase = StagePhase.keyAvailable;
      return;
    }
    phase = StagePhase.clearing;
  }

  bool get shouldSpawnKey =>
      !keySpawned && enemiesRemaining <= 0 && (!hasBoss || bossDefeated);

  bool get shouldSpawnPostKeyWave =>
      keyCollected && !postKeySpawned && postKeyEnemyCount > 0;

  bool get exitOpen => keyCollected;
}

int scoreForEnemyKill(int combo) => 100 * combo;

const int fruitScore = 50;
const int stageClearBonus = 500;
const int perfectKeyBonus = 200;
const int bossKillScore = 1000;
