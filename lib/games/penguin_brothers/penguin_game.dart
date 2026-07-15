import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'components/actors.dart';
import 'components/bombs_and_items.dart';
import 'components/tile_map.dart';
import 'levels/level_defs.dart';
import 'penguin_ai.dart';
import 'penguin_config.dart';
import 'penguin_logic.dart';
import 'penguin_sounds.dart';

class PenguinGame extends FlameGame {
  PenguinGame({required this.config, required this.sounds});

  final PenguinConfig config;
  final PenguinSounds sounds;
  final _rng = Random();
  final _ai = PenguinAi();
  final ValueNotifier<int> hudTick = ValueNotifier(0);

  late TileMapComponent worldMap;
  final List<PenguinPlayer> players = [];
  final List<EnemyActor> enemies = [];
  final List<BombActor> bombs = [];
  final List<BarrelActor> barrels = [];
  BossActor? boss;
  KeyItem? keyItem;
  ExitDoor? exitDoor;

  late StageProgress progress;
  int stageIndex = 0;
  int score = 0;
  int lives = 3;
  int combo = 0;
  double comboTimer = 0;
  double shake = 0;

  // Human input (set from Flutter overlays)
  double inputMoveX = 0;
  bool inputJump = false;
  bool inputBomb = false;
  bool _bombLatched = false;

  bool stageLocked = false;
  bool gameOver = false;
  bool gameWon = false;

  List<PenguinPlayer> get livingPlayers =>
      players.where((p) => !p.dead).toList();

  @override
  Color backgroundColor() => const Color(0xFF6BAE6B);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'penguin_brothers/characters/donfi.png',
      'penguin_brothers/characters/turu.png',
      'penguin_brothers/enemies/dino_chase.png',
      'penguin_brothers/enemies/fire_spitter.png',
      'penguin_brothers/enemies/skittish.png',
      'penguin_brothers/enemies/boss_kuda.png',
      'penguin_brothers/items/bomb.png',
      'penguin_brothers/items/key_disc.png',
      'penguin_brothers/items/exit_door.png',
      'penguin_brothers/items/barrel.png',
      'penguin_brothers/items/power_long.png',
      'penguin_brothers/items/power_fish.png',
      'penguin_brothers/items/power_skates.png',
      'penguin_brothers/items/fruit.png',
      'penguin_brothers/fx/explosion.png',
      'penguin_brothers/tiles/ground.png',
      'penguin_brothers/tiles/platform.png',
      'penguin_brothers/tiles/wall.png',
      'penguin_brothers/tiles/breakable.png',
      'penguin_brothers/bg_stage.png',
    ]);
    lives = config.startingLives;
    camera.viewfinder.anchor = Anchor.topLeft;
    await loadStage(0);
  }

  Sprite sprite(String path) => Sprite(images.fromCache(path));

  Future<void> loadStage(int index) async {
    stageIndex = index;
    stageLocked = false;
    world.removeAll(world.children.toList());
    players.clear();
    enemies.clear();
    bombs.clear();
    barrels.clear();
    boss = null;
    keyItem = null;
    exitDoor = null;
    combo = 0;

    final level = penguinLevels[index];
    var plannedEnemies = 0;
    for (final row in level.rows) {
      for (final ch in row.split('')) {
        if (enemyKindFromChar(ch) != null) plannedEnemies++;
      }
    }
    progress = StageProgress(
      wave1EnemyCount: plannedEnemies,
      hasBoss: level.hasBoss,
      postKeyEnemyCount: level.postKeyEnemyCount,
    );

    final bg = SpriteComponent(
      sprite: sprite('penguin_brothers/bg_stage.png'),
      size: Vector2(level.width * kTileSize, level.height * kTileSize),
      priority: -10,
    );
    world.add(bg);

    worldMap = TileMapComponent(
      level: level,
      sprites: {
        TileKind.wall: sprite('penguin_brothers/tiles/wall.png'),
        TileKind.ground: sprite('penguin_brothers/tiles/ground.png'),
        TileKind.platform: sprite('penguin_brothers/tiles/platform.png'),
        TileKind.breakable: sprite('penguin_brothers/tiles/breakable.png'),
      },
    );
    await world.add(worldMap);

    Vector2? p1;
    Vector2? p2;
    Vector2? exitPos;
    Vector2? bossPos;
    final enemySpawns = <(Vector2, EnemyKind)>[];
    final fruitSpawns = <Vector2>[];
    final barrelSpawns = <Vector2>[];

    for (var r = 0; r < level.height; r++) {
      for (var c = 0; c < level.width; c++) {
        final ch = level.rows[r][c];
        final center = worldMap.cellCenter(c, r);
        switch (ch) {
          case '1':
            p1 = center;
          case '2':
            p2 = center;
          case 'X':
            exitPos = center;
          case 'S':
            bossPos = center;
          case 'B':
            barrelSpawns.add(center);
          case 'P':
            fruitSpawns.add(center);
          default:
            final kind = enemyKindFromChar(ch);
            if (kind != null) enemySpawns.add((center, kind));
        }
      }
    }

    if (exitPos != null) {
      exitDoor = ExitDoor(
        sprite: sprite('penguin_brothers/items/exit_door.png'),
        position: exitPos,
      );
      world.add(exitDoor!);
    }

    for (final pos in barrelSpawns) {
      final b = BarrelActor(
        sprite: sprite('penguin_brothers/items/barrel.png'),
        position: pos,
      );
      barrels.add(b);
      world.add(b);
    }
    for (final pos in fruitSpawns) {
      world.add(
        FruitItem(
          sprite: sprite('penguin_brothers/items/fruit.png'),
          position: pos,
        ),
      );
    }

    final donfi = PenguinPlayer(
      isHuman: true,
      isDonfi: true,
      sprite: sprite('penguin_brothers/characters/donfi.png'),
      position: p1 ?? worldMap.cellCenter(2, 5),
    );
    players.add(donfi);
    world.add(donfi);

    if (config.hasAiPartner) {
      final turu = PenguinPlayer(
        isHuman: false,
        isDonfi: false,
        sprite: sprite('penguin_brothers/characters/turu.png'),
        position: p2 ?? (p1 ?? worldMap.cellCenter(3, 5)) + Vector2(28, 0),
      );
      players.add(turu);
      world.add(turu);
    }

    for (final (pos, kind) in enemySpawns) {
      _spawnEnemy(pos, kind);
    }
    progress.enemiesRemaining = enemies.length;

    if (level.hasBoss && bossPos != null) {
      boss = BossActor(
        sprite: sprite('penguin_brothers/enemies/boss_kuda.png'),
        position: bossPos,
      );
      world.add(boss!);
    }

    final worldSize = Vector2(
      level.width * kTileSize,
      level.height * kTileSize,
    );
    camera.viewfinder.visibleGameSize = worldSize;
    overlays.add('hud');
  }

  void _spawnEnemy(Vector2 pos, EnemyKind kind) {
    final path = switch (kind) {
      EnemyKind.chaser => 'penguin_brothers/enemies/dino_chase.png',
      EnemyKind.fireSpitter => 'penguin_brothers/enemies/fire_spitter.png',
      EnemyKind.skittish => 'penguin_brothers/enemies/skittish.png',
    };
    final e = EnemyActor(
      kind: kind,
      sprite: sprite(path),
      position: pos.clone(),
    );
    enemies.add(e);
    world.add(e);
  }

  @override
  void update(double dt) {
    if (gameOver || gameWon || stageLocked) {
      super.update(dt);
      return;
    }
    if (shake > 0) {
      shake -= dt;
      camera.viewfinder.position = Vector2(
        _rng.nextDouble() * 4 - 2,
        _rng.nextDouble() * 4 - 2,
      );
      if (shake <= 0) camera.viewfinder.position = Vector2.zero();
    }

    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 0;
    }

    final human = players.firstWhere((p) => p.isHuman);
    if (!human.dead) {
      human.control(inputMoveX, inputJump, dt);
      final wantBomb = inputBomb && !_bombLatched;
      _bombLatched = inputBomb;
      if (wantBomb) tryThrowBomb(human);
    }

    if (config.hasAiPartner) {
      for (final p in players.where((p) => !p.isHuman)) {
        _ai.update(this, p, dt);
      }
    }

    if (progress.shouldSpawnKey) {
      progress.markKeySpawned();
      progress.phase = StagePhase.keyAvailable;
      final spawn = livingPlayers.isNotEmpty
          ? livingPlayers.first.position + Vector2(0, -40)
          : worldMap.cellCenter(8, 4);
      keyItem = KeyItem(
        sprite: sprite('penguin_brothers/items/key_disc.png'),
        position: spawn,
      );
      world.add(keyItem!);
      sounds.pickup();
    }

    if (progress.shouldSpawnPostKeyWave) {
      final count = progress.postKeyEnemyCount;
      progress.markPostKeySpawned(count);
      for (var i = 0; i < count; i++) {
        final kinds = EnemyKind.values;
        _spawnEnemy(worldMap.cellCenter(3 + i * 3, 4), kinds[i % kinds.length]);
      }
    }

    super.update(dt);
    hudTick.value++;
  }

  void tryThrowBomb(PenguinPlayer p) {
    if (p.dead || p.bombCooldown > 0) return;
    p.bombCooldown = 0.55;
    final offset = Vector2(p.facingRight ? 18 : -18, -4);
    final rules = p.longRangeBombs
        ? const BombRules().longRange
        : const BombRules();
    final bomb = BombActor(
      sprite: sprite('penguin_brothers/items/bomb.png'),
      position: p.position + offset,
      owner: p,
      rules: rules,
    );
    bombs.add(bomb);
    world.add(bomb);
    sounds.bombThrow();
  }

  void detonate(BombActor bomb) {
    bombs.remove(bomb);
    sounds.explode();
    shake = 0.22;
    final (col, row) = worldMap.worldToCell(bomb.position);
    final cells = BombRules.blastCells(col, row, bomb.rules.radiusTiles);

    world.add(
      ExplosionFx(
        sprite: sprite('penguin_brothers/fx/explosion.png'),
        position: bomb.position.clone(),
        radiusTiles: bomb.rules.radiusTiles,
      ),
    );

    for (final (c, r) in cells) {
      if (worldMap.isBreakable(c, r)) {
        worldMap.clearCell(c, r);
      }
      final rect = worldMap.cellRect(c, r).inflate(2);
      for (final e in List<EnemyActor>.from(enemies)) {
        if (e.hitbox.overlaps(rect)) e.die();
      }
      if (boss != null && !boss!.dead && boss!.hitbox.overlaps(rect)) {
        boss!.hit();
      }
      for (final b in List<BarrelActor>.from(barrels)) {
        final br = Rect.fromCenter(
          center: Offset(b.position.x, b.position.y),
          width: b.size.x,
          height: b.size.y,
        );
        if (br.overlaps(rect)) {
          barrels.remove(b);
          b.breakOpen();
        }
      }
      for (final p in livingPlayers) {
        if (p.hitbox.overlaps(rect)) p.takeHit();
      }
    }
  }

  void onEnemyKilled(EnemyActor e) {
    enemies.remove(e);
    combo++;
    comboTimer = 2.2;
    final pts = scoreForEnemyKill(combo);
    score += pts;
    progress.onEnemyDefeated();
    world.add(
      ComboPopup(
        text: combo > 1 ? 'x$combo  +$pts' : '+$pts',
        position: e.position.clone(),
      ),
    );
    sounds.pickup();
  }

  void onBossDefeated(BossActor b) {
    boss = null;
    score += bossKillScore;
    progress.onBossDefeated();
    world.add(ComboPopup(text: 'BOSS +$bossKillScore', position: b.position));
    sounds.win();
  }

  void collectKey(PenguinPlayer p) {
    p.holdingKey = true;
    keyItem = null;
    progress.onKeyCollected();
    sounds.pickup();
  }

  void collectFruit() {
    score += fruitScore;
    sounds.pickup();
  }

  void spawnPowerUpAt(Vector2 pos) {
    final kinds = PowerUpKind.values;
    final kind = kinds[_rng.nextInt(kinds.length)];
    final path = switch (kind) {
      PowerUpKind.longRange => 'penguin_brothers/items/power_long.png',
      PowerUpKind.invincibilityFish => 'penguin_brothers/items/power_fish.png',
      PowerUpKind.speedSkates => 'penguin_brothers/items/power_skates.png',
    };
    world.add(PowerUpItem(sprite: sprite(path), position: pos, kind: kind));
  }

  void onPlayerHit(PenguinPlayer p) {
    if (p.isInvincible) return;
    lives--;
    sounds.hurt();
    p.invuln = 1.5;
    p.holdingKey = false;
    if (progress.keyCollected && keyItem == null) {
      // Drop key near player
      progress.keyCollected = false;
      progress.phase = StagePhase.keyAvailable;
      keyItem = KeyItem(
        sprite: sprite('penguin_brothers/items/key_disc.png'),
        position: p.position.clone(),
      );
      world.add(keyItem!);
    }
    if (lives <= 0) {
      gameOver = true;
      overlays.add('gameOver');
      return;
    }
    // Soft respawn
    final level = penguinLevels[stageIndex];
    for (var r = 0; r < level.height; r++) {
      for (var c = 0; c < level.width; c++) {
        if (level.rows[r][c] == (p.isDonfi ? '1' : '2')) {
          p.position = worldMap.cellCenter(c, r);
          p.velocity.setZero();
          return;
        }
      }
    }
  }

  Future<void> onReachedExit(PenguinPlayer p) async {
    if (stageLocked || !p.holdingKey) return;
    stageLocked = true;
    score += stageClearBonus;
    if (combo > 0) score += perfectKeyBonus;
    sounds.win();
    overlays.add('stageClear');
  }

  Future<void> advanceOrWin() async {
    overlays.remove('stageClear');
    if (stageIndex >= penguinLevels.length - 1) {
      gameWon = true;
      overlays.add('gameWon');
      return;
    }
    await loadStage(stageIndex + 1);
  }

  void restartGame() {
    gameOver = false;
    gameWon = false;
    score = 0;
    lives = config.startingLives;
    overlays.remove('gameOver');
    overlays.remove('gameWon');
    loadStage(0);
  }
}
